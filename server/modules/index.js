// Module máy chủ Nakama của PROJECT ECLIPSE (M9-1). Chạy trong JS runtime của Nakama (goja), không cần build.
// Đặt trong thư mục runtime.path của Nakama; Nakama gọi InitModule khi khởi động.
//
// Chức năng giai đoạn 1:
//  - Tài khoản: đăng ký tên + email + mật khẩu (endpoint authenticate/email), đăng nhập bằng tên hoặc email.
//  - Mỗi tài khoản có một "mã người chơi" 8 chữ số (duy nhất), người chơi ghi vào nội dung chuyển khoản.
//  - eclipse_profile (người chơi gọi): mã, tên, ví (wallet).
//  - admin_find / admin_grant (chỉ gọi bằng http_key từ tool của QTV): tra cứu theo mã, phát tiền vào ví.
//    Mỗi lần phát cần mã giao dịch ngân hàng (ref) duy nhất: cùng ref lần hai bị từ chối (chống phát trùng).
//
// Không đặt số cân bằng / giá gói ở đây: QTV nhập số lượng khi phát.

var CODE_COLLECTION = "player_code";      // key = mã 8 số, owner = hệ thống, value {user_id}
var GRANT_COLLECTION = "admin_grant";     // key = ref, owner = hệ thống, value = bản ghi phát quà
var SYSTEM_USER = "00000000-0000-0000-0000-000000000000";
var ALLOWED_CURRENCIES = ["gems", "gold"];
var MAX_GRANT = 10000000;                  // chặn gõ nhầm thừa số 0
var CODE_LENGTH = 8;

function newCode() {
  var s = "" + (1 + Math.floor(Math.random() * 9));   // không bắt đầu bằng 0
  while (s.length < CODE_LENGTH) {
    s += Math.floor(Math.random() * 10);
  }
  return s;
}

function cleanCode(raw) {
  return String(raw || "").replace(/[^0-9]/g, "");
}

// Mã của tài khoản; chưa có thì cấp mới (ghi với version "*" để hai tài khoản không lấy trùng mã).
function ensureCode(nk, logger, userId) {
  var account = nk.accountGetId(userId);
  var meta = account.user.metadata || {};
  if (meta.code) {
    return meta.code;
  }
  for (var i = 0; i < 20; i++) {
    var code = newCode();
    try {
      nk.storageWrite([{
        collection: CODE_COLLECTION, key: code, userId: SYSTEM_USER,
        value: { user_id: userId }, version: "*", permissionRead: 0, permissionWrite: 0
      }]);
    } catch (e) {
      continue;   // mã đã có người dùng
    }
    meta.code = code;
    nk.accountUpdateId(userId, null, null, null, null, null, null, meta);
    logger.info("Cấp mã người chơi %s cho %s", code, userId);
    return code;
  }
  throw new Error("không cấp được mã người chơi");
}

function userIdByCode(nk, code) {
  var rows = nk.storageRead([{ collection: CODE_COLLECTION, key: code, userId: SYSTEM_USER }]);
  if (!rows || rows.length === 0) {
    return null;
  }
  return rows[0].value.user_id;
}

function walletOf(account) {
  var w = account.wallet;
  if (typeof w === "string") {
    w = w ? JSON.parse(w) : {};
  }
  return w || {};
}

function profileOf(nk, userId, code) {
  var account = nk.accountGetId(userId);
  return {
    user_id: userId,
    code: code,
    username: account.user.username,
    display_name: account.user.displayName || "",
    wallet: walletOf(account),
    server_time: Math.floor(Date.now() / 1000)
  };
}

function requireAdmin(ctx) {
  // Gọi bằng http_key (server-to-server) thì không có userId; người chơi đăng nhập thì có.
  if (ctx.userId) {
    throw new Error("chỉ QTV được gọi");
  }
}

function afterAuthenticateDevice(ctx, logger, nk, session, request) {
  ensureCode(nk, logger, ctx.userId);
}

// Tên đăng nhập: 3–20 ký tự chữ không dấu, số, gạch dưới (giống kiểm tra phía game, NakamaApi.username_error).
var USERNAME_RE = /^[A-Za-z0-9_]{3,20}$/;

// Đăng ký tài khoản (create = true) phải có tên hợp lệ; đăng nhập (create = false) không kiểm.
function beforeAuthenticateEmail(ctx, logger, nk, data) {
  if (data.create && !USERNAME_RE.test(String(data.username || ""))) {
    throw new Error("tên đăng nhập 3–20 ký tự: chữ không dấu, số, gạch dưới");
  }
  return data;
}

function afterAuthenticateEmail(ctx, logger, nk, session, request) {
  ensureCode(nk, logger, ctx.userId);
}

function rpcProfile(ctx, logger, nk, payload) {
  if (!ctx.userId) {
    throw new Error("cần đăng nhập");
  }
  return JSON.stringify(profileOf(nk, ctx.userId, ensureCode(nk, logger, ctx.userId)));
}

function rpcAdminFind(ctx, logger, nk, payload) {
  requireAdmin(ctx);
  var req = JSON.parse(payload || "{}");
  var code = cleanCode(req.code);
  var userId = userIdByCode(nk, code);
  if (!userId) {
    throw new Error("không có người chơi mã " + code);
  }
  return JSON.stringify(profileOf(nk, userId, code));
}

// Kiểm tra yêu cầu phát quà; trả về chuỗi lỗi hoặc "" nếu hợp lệ.
function validateGrant(req) {
  if (cleanCode(req.code).length !== CODE_LENGTH) {
    return "mã người chơi phải có " + CODE_LENGTH + " chữ số";
  }
  var ref = String(req.ref || "").trim();
  if (ref.length < 4 || ref.length > 64 || !/^[A-Za-z0-9._-]+$/.test(ref)) {
    return "ref (mã giao dịch ngân hàng) 4–64 ký tự: chữ, số, . _ -";
  }
  if (!req.operator || String(req.operator).trim() === "") {
    return "thiếu tên QTV (operator)";
  }
  var changes = req.changes || {};
  var keys = Object.keys(changes);
  if (keys.length === 0) {
    return "không có gì để phát";
  }
  for (var i = 0; i < keys.length; i++) {
    var k = keys[i];
    var v = changes[k];
    if (ALLOWED_CURRENCIES.indexOf(k) < 0) {
      return "loại tiền không hợp lệ: " + k;
    }
    if (typeof v !== "number" || Math.floor(v) !== v || v === 0 || Math.abs(v) > MAX_GRANT) {
      return "số lượng " + k + " phải là số nguyên khác 0, tối đa " + MAX_GRANT;
    }
  }
  return "";
}

function rpcAdminGrant(ctx, logger, nk, payload) {
  requireAdmin(ctx);
  var req = JSON.parse(payload || "{}");
  var err = validateGrant(req);
  if (err) {
    throw new Error(err);
  }
  var code = cleanCode(req.code);
  var userId = userIdByCode(nk, code);
  if (!userId) {
    throw new Error("không có người chơi mã " + code);
  }
  var ref = String(req.ref).trim();
  var record = {
    code: code, user_id: userId, changes: req.changes, ref: ref,
    note: String(req.note || ""), operator: String(req.operator).trim(),
    time: Math.floor(Date.now() / 1000)
  };
  // Giữ chỗ ref trước khi cộng ví: ref đã dùng thì storageWrite với version "*" báo lỗi.
  try {
    nk.storageWrite([{
      collection: GRANT_COLLECTION, key: ref, userId: SYSTEM_USER,
      value: record, version: "*", permissionRead: 0, permissionWrite: 0
    }]);
  } catch (e) {
    throw new Error("ref " + ref + " đã được dùng (đã phát quà cho giao dịch này)");
  }
  try {
    nk.walletUpdate(userId, req.changes, { reason: "admin_grant", ref: ref, operator: record.operator, note: record.note }, true);
  } catch (e) {
    nk.storageDelete([{ collection: GRANT_COLLECTION, key: ref, userId: SYSTEM_USER }]);
    throw new Error("không cập nhật được ví: " + e.message);
  }
  logger.info("QTV %s phát %s cho %s (ref %s)", record.operator, JSON.stringify(req.changes), code, ref);
  return JSON.stringify(profileOf(nk, userId, code));
}

function InitModule(ctx, logger, nk, initializer) {
  initializer.registerAfterAuthenticateDevice(afterAuthenticateDevice);
  initializer.registerBeforeAuthenticateEmail(beforeAuthenticateEmail);
  initializer.registerAfterAuthenticateEmail(afterAuthenticateEmail);
  initializer.registerRpc("eclipse_profile", rpcProfile);
  initializer.registerRpc("admin_find", rpcAdminFind);
  initializer.registerRpc("admin_grant", rpcAdminGrant);
  logger.info("PROJECT ECLIPSE module đã nạp");
}

// Nakama tìm InitModule ở phạm vi toàn cục; dòng dưới để trình đóng gói không xóa hàm.
!InitModule && InitModule.bind(null);
