// Module máy chủ Nakama của PROJECT ECLIPSE (M9-1). Chạy trong JS runtime của Nakama (goja), không cần build.
// Đặt trong thư mục runtime.path của Nakama; Nakama gọi InitModule khi khởi động.
//
// Chức năng giai đoạn 1:
//  - Tài khoản: đăng ký tên + email + mật khẩu (endpoint authenticate/email), đăng nhập bằng tên hoặc email.
//  - Mỗi tài khoản có một "mã người chơi" 8 chữ số (duy nhất), người chơi ghi vào nội dung chuyển khoản.
//  - eclipse_profile (người chơi gọi): mã, tên, ví (wallet).
//  - save_get / save_put (người chơi gọi): cloud save, mỗi tài khoản một thế giới (M9-3).
//  - Chat (M9-6): phòng thế giới + nhắn riêng, lọc từ, cấm chat, báo cáo, tra cứu theo mã (xem mục Chat bên dưới).
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

// ---------- Cloud save (M9-3) ----------
// Mỗi tài khoản một "thế giới": collection "save", key "main", chủ = người chơi; chỉ ghi qua RPC (permissionWrite 0).
// Giá trị = phong bì file save của game: {schema_version, checksum, saved_at, data: "<chuỗi JSON>"} (SaveStore.encode).
// Ghi có kiểm tra version (base_version): bản trên máy chủ đã đổi từ thiết bị khác thì báo "save_conflict".
// Bản trước mỗi lần ghi giữ ở "save_backup"/"prev" để QTV khôi phục khi cần.

var SAVE_COLLECTION = "save";
var SAVE_KEY = "main";
var SAVE_BACKUP_COLLECTION = "save_backup";
var SAVE_MAX_DATA = 200000;   // ký tự của chuỗi data (save thật ~20 KB)

function readSave(nk, userId) {
  var rows = nk.storageRead([{ collection: SAVE_COLLECTION, key: SAVE_KEY, userId: userId }]);
  return rows && rows.length > 0 ? rows[0] : null;
}

function validateEnvelope(env) {
  if (!env || typeof env !== "object") {
    return "thiếu dữ liệu save";
  }
  if (typeof env.schema_version !== "number" || env.schema_version < 1) {
    return "schema_version không hợp lệ";
  }
  if (typeof env.checksum !== "string" || env.checksum.length !== 64) {
    return "checksum không hợp lệ";
  }
  if (typeof env.data !== "string" || env.data.length < 2) {
    return "data không hợp lệ";
  }
  if (env.data.length > SAVE_MAX_DATA) {
    return "save quá lớn (" + env.data.length + " ký tự)";
  }
  return "";
}

function rpcSaveGet(ctx, logger, nk, payload) {
  if (!ctx.userId) {
    throw new Error("cần đăng nhập");
  }
  var row = readSave(nk, ctx.userId);
  if (!row) {
    return JSON.stringify({ exists: false });
  }
  return JSON.stringify({ exists: true, version: row.version, envelope: row.value, update_time: row.updateTime });
}

function rpcSavePut(ctx, logger, nk, payload) {
  if (!ctx.userId) {
    throw new Error("cần đăng nhập");
  }
  var req = JSON.parse(payload || "{}");
  var err = validateEnvelope(req.envelope);
  if (err) {
    throw new Error(err);
  }
  var base = String(req.base_version || "");
  var current = readSave(nk, ctx.userId);
  if ((current ? current.version : "") !== base) {
    throw new Error("save_conflict");
  }
  var acks;
  try {
    acks = nk.storageWrite([{
      collection: SAVE_COLLECTION, key: SAVE_KEY, userId: ctx.userId, value: req.envelope,
      version: base === "" ? "*" : base, permissionRead: 1, permissionWrite: 0
    }]);
  } catch (e) {
    throw new Error("save_conflict");   // thiết bị khác vừa ghi chen vào
  }
  if (current) {
    nk.storageWrite([{
      collection: SAVE_BACKUP_COLLECTION, key: "prev", userId: ctx.userId, value: current.value,
      permissionRead: 0, permissionWrite: 0
    }]);
  }
  return JSON.stringify({ version: acks[0].version });
}

// ---------- Chat (M9-6) ----------
// Chat thời gian thực dùng kênh có sẵn của Nakama: phòng "world" (type 1) và nhắn riêng (type 2). Game KHÔNG được tạo
// phòng khác. Mọi tin đi qua hook trước khi gửi: kiểm tra cấm chat, tần suất, độ dài, người nhận có chặn không, lọc từ.
// Bạn bè / chặn dùng API bạn bè của Nakama (/v2/friend) trực tiếp từ game; ở đây chỉ có tra cứu theo mã, báo cáo,
// cấm chat (QTV), và thông báo "có tin nhắn riêng" cho người nhận chưa mở kênh (Nakama không đẩy tin riêng cho họ).
// Lỗi gửi cho game bằng message dạng "chat_<lý do>" (game dịch sang chữ hiển thị).

var MUTE_COLLECTION = "chat_mute";        // key = user_id, value {until (ms), reason, operator}
var RATE_COLLECTION = "chat_rate";        // key = user_id, value {t: ms tin gần nhất}
var NOTIFY_COLLECTION = "chat_notify";    // key = người nhận, value {<sender_id>: ms thông báo gần nhất}
var REPORT_COLLECTION = "chat_report";    // key = id báo cáo, value bản ghi báo cáo
var WORLD_ROOM = "world";
var CHAT_MAX_LEN = 200;                   // ký tự mỗi tin
var CHAT_MIN_INTERVAL_MS = 800;           // giãn cách giữa hai tin của một người
var NOTIFY_INTERVAL_MS = 30000;           // tối đa 1 thông báo / người gửi / 30 giây
var NOTIFY_CODE_DM = 100;
var REPORT_REASONS = ["spam", "abuse", "inappropriate", "cheat", "other"];
var MAX_MUTE_MIN = 60 * 24 * 365;

// Từ cấm. Khớp theo từ (có ranh giới chữ), không phân biệt hoa thường; che bằng dấu *.
//  - BAD_WORDS_ACCENT: so khớp đúng dấu tiếng Việt (tránh bắt nhầm "lớn" khi bỏ dấu thành "lon").
//  - BAD_WORDS_FOLDED: dạng viết tắt không dấu hay dùng để né lọc. QTV sửa danh sách ở đây rồi khởi động lại Nakama.
var BAD_WORDS_ACCENT = ["địt", "đụ", "lồn", "cặc", "đĩ", "đm", "đmm", "đcm", "đkm", "đéo", "súc vật", "óc chó"];
var BAD_WORDS_FOLDED = ["dm", "dmm", "dcm", "dkm", "dcmm", "vcl", "vkl", "clm", "cmm", "cmn", "dit me", "dit con me"];

function isWordChar(ch) {
  return !!ch && /[0-9A-Za-z_\u00C0-\u1EF9]/.test(ch);
}

// Che mọi lần xuất hiện của `words` trong `text` (khớp trên `hay` cùng độ dài với text).
function maskWords(text, hay, words) {
  var out = text.split("");
  for (var w = 0; w < words.length; w++) {
    var word = words[w];
    var from = 0;
    while (true) {
      var i = hay.indexOf(word, from);
      if (i < 0) {
        break;
      }
      var end = i + word.length;
      if (!isWordChar(hay.charAt(i - 1)) && !isWordChar(hay.charAt(end))) {
        for (var k = i; k < end; k++) {
          if (out[k] !== " ") {
            out[k] = "*";
          }
        }
      }
      from = i + 1;
    }
  }
  return out.join("");
}

// Bỏ dấu 1-1 (giữ nguyên độ dài chuỗi) để so khớp dạng viết tắt không dấu.
var FOLD_FROM = "àáảãạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđ";
var FOLD_TO   = "aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd";
function foldChar(ch) {
  var i = FOLD_FROM.indexOf(ch);
  return i >= 0 ? FOLD_TO.charAt(i) : ch;
}

function filterText(text) {
  var lower = text.toLowerCase();
  var out = maskWords(text, lower, BAD_WORDS_ACCENT);
  var folded = "";
  for (var i = 0; i < lower.length; i++) {
    folded += foldChar(lower.charAt(i));
  }
  return maskWords(out, folded, BAD_WORDS_FOLDED);
}

function cleanChatText(raw) {
  var s = String(raw || "").replace(/[\u0000-\u001F\u007F]/g, " ").replace(/\s+/g, " ").trim();
  return s;
}

function readOne(nk, collection, key) {
  var rows = nk.storageRead([{ collection: collection, key: key, userId: SYSTEM_USER }]);
  return rows && rows.length > 0 ? rows[0] : null;
}

function writeSystem(nk, collection, key, value) {
  nk.storageWrite([{ collection: collection, key: key, userId: SYSTEM_USER, value: value, permissionRead: 0, permissionWrite: 0 }]);
}

// Throw nếu người chơi đang bị cấm chat.
function assertNotMuted(nk, userId) {
  var row = readOne(nk, MUTE_COLLECTION, userId);
  if (row && row.value.until > Date.now()) {
    throw new Error("chat_muted:" + row.value.until);
  }
}

function assertRate(nk, userId) {
  var row = readOne(nk, RATE_COLLECTION, userId);
  var now = Date.now();
  if (row && now - row.value.t < CHAT_MIN_INTERVAL_MS) {
    throw new Error("chat_rate");
  }
  writeSystem(nk, RATE_COLLECTION, userId, { t: now });
}

// Kênh nhắn riêng có id "4.<user_id_1>.<user_id_2>." → id người còn lại.
function dmPeer(channelId, me) {
  var parts = String(channelId).split(".");
  if (parts.length < 3 || parts[0] !== "4") {
    return null;
  }
  return parts[1] === me ? parts[2] : (parts[2] === me ? parts[1] : "");
}

function hasBlocked(nk, ownerId, otherId) {
  var cursor = "";
  for (var page = 0; page < 10; page++) {
    var res = nk.friendsList(ownerId, 100, 3, cursor);
    var list = res.friends || [];
    for (var i = 0; i < list.length; i++) {
      if (list[i].user.userId === otherId) {
        return true;
      }
    }
    cursor = res.cursor;
    if (!cursor) {
      break;
    }
  }
  return false;
}

function beforeChannelJoin(ctx, logger, nk, envelope) {
  var j = envelope.channelJoin;
  var type = Number(j.type);
  if (type === 1 && j.target === WORLD_ROOM) {
    return envelope;
  }
  if (type === 2 && j.target && j.target !== ctx.userId) {
    return envelope;
  }
  throw new Error("chat_channel_not_allowed");
}

function beforeChannelMessageSend(ctx, logger, nk, envelope) {
  var m = envelope.channelMessageSend;
  var userId = ctx.userId;
  var body;
  try {
    body = JSON.parse(m.content);
  } catch (e) {
    throw new Error("chat_empty");
  }
  var text = cleanChatText(body && body.text);
  if (!text) {
    throw new Error("chat_empty");
  }
  if (text.length > CHAT_MAX_LEN) {
    throw new Error("chat_too_long");
  }
  assertNotMuted(nk, userId);
  assertRate(nk, userId);
  var peer = dmPeer(m.channelId, userId);
  if (peer === "") {
    throw new Error("chat_channel_not_allowed");
  }
  if (peer && hasBlocked(nk, peer, userId)) {
    throw new Error("chat_blocked");
  }
  text = filterText(text);
  m.content = JSON.stringify({ text: text });
  if (peer) {
    notifyDirectMessage(nk, logger, userId, ctx.username, peer, text);
  }
  return envelope;
}

// Báo cho người nhận (đang mở game thì thấy ngay, đang tắt thì thấy khi đăng nhập). Tối đa 1 lần / người gửi / 30 giây.
function notifyDirectMessage(nk, logger, senderId, senderName, peerId, text) {
  var row = readOne(nk, NOTIFY_COLLECTION, peerId);
  var map = row ? row.value : {};
  var now = Date.now();
  if (map[senderId] && now - map[senderId] < NOTIFY_INTERVAL_MS) {
    return;
  }
  map[senderId] = now;
  writeSystem(nk, NOTIFY_COLLECTION, peerId, map);
  try {
    nk.notificationSend(peerId, senderName, { from_id: senderId, from_name: senderName, text: text.substring(0, 60) },
      NOTIFY_CODE_DM, senderId, true);
  } catch (e) {
    logger.warn("không gửi được thông báo tin nhắn riêng: %s", e.message);
  }
}

// Người chơi tra cứu người khác theo mã người chơi (để kết bạn / nhắn riêng). Trả về id + tên, không lộ gì thêm.
function rpcChatFind(ctx, logger, nk, payload) {
  if (!ctx.userId) {
    throw new Error("cần đăng nhập");
  }
  var req = JSON.parse(payload || "{}");
  var code = cleanCode(req.code);
  var userId = code.length === CODE_LENGTH ? userIdByCode(nk, code) : null;
  if (!userId) {
    throw new Error("chat_not_found");
  }
  var account = nk.accountGetId(userId);
  return JSON.stringify({ user_id: userId, username: account.user.username, code: code });
}

function rpcChatReport(ctx, logger, nk, payload) {
  if (!ctx.userId) {
    throw new Error("cần đăng nhập");
  }
  var req = JSON.parse(payload || "{}");
  var target = String(req.target_id || "");
  if (!target || target === ctx.userId) {
    throw new Error("chat_report_invalid");
  }
  var reason = REPORT_REASONS.indexOf(req.reason) >= 0 ? req.reason : "other";
  var accounts = nk.accountsGetId([target]);
  if (!accounts || accounts.length === 0) {
    throw new Error("chat_not_found");
  }
  var id = nk.uuidv4();
  writeSystem(nk, REPORT_COLLECTION, id, {
    id: id, time: Date.now(), reporter_id: ctx.userId, reporter_name: ctx.username,
    target_id: target, target_name: accounts[0].user.username, reason: reason,
    channel_id: String(req.channel_id || "").substring(0, 120),
    message_id: String(req.message_id || "").substring(0, 64),
    text: String(req.text || "").substring(0, CHAT_MAX_LEN), resolved: false
  });
  return JSON.stringify({ id: id });
}

// ---- QTV ----

// Danh sách báo cáo chưa xử lý (mới nhất trước).
function rpcAdminChatReports(ctx, logger, nk, payload) {
  requireAdmin(ctx);
  var req = JSON.parse(payload || "{}");
  var all = [];
  var cursor = "";
  for (var page = 0; page < 20; page++) {
    var res = nk.storageList(SYSTEM_USER, REPORT_COLLECTION, 100, cursor);
    var objs = res.objects || [];
    for (var i = 0; i < objs.length; i++) {
      if (req.all || !objs[i].value.resolved) {
        all.push(objs[i].value);
      }
    }
    cursor = res.cursor;
    if (!cursor) {
      break;
    }
  }
  all.sort(function (a, b) { return b.time - a.time; });
  return JSON.stringify({ reports: all.slice(0, Number(req.limit) || 50) });
}

function rpcAdminChatResolve(ctx, logger, nk, payload) {
  requireAdmin(ctx);
  var req = JSON.parse(payload || "{}");
  var row = readOne(nk, REPORT_COLLECTION, String(req.id || ""));
  if (!row) {
    throw new Error("không có báo cáo " + req.id);
  }
  row.value.resolved = true;
  row.value.resolved_by = String(req.operator || "");
  writeSystem(nk, REPORT_COLLECTION, row.key, row.value);
  return JSON.stringify({ id: row.key, resolved: true });
}

// Cấm chat `minutes` phút (0 = gỡ cấm).
function rpcAdminChatMute(ctx, logger, nk, payload) {
  requireAdmin(ctx);
  var req = JSON.parse(payload || "{}");
  var code = cleanCode(req.code);
  var userId = userIdByCode(nk, code);
  if (!userId) {
    throw new Error("không có người chơi mã " + code);
  }
  var minutes = Number(req.minutes);
  if (!(minutes >= 0) || minutes > MAX_MUTE_MIN || Math.floor(minutes) !== minutes) {
    throw new Error("minutes phải là số nguyên 0.." + MAX_MUTE_MIN);
  }
  if (!req.operator || String(req.operator).trim() === "") {
    throw new Error("thiếu tên QTV (operator)");
  }
  var until = minutes === 0 ? 0 : Date.now() + minutes * 60000;
  writeSystem(nk, MUTE_COLLECTION, userId, { until: until, reason: String(req.reason || ""), operator: String(req.operator).trim(), time: Date.now() });
  logger.info("QTV %s %s chat của %s (%s phút)", req.operator, minutes === 0 ? "gỡ cấm" : "cấm", code, minutes);
  return JSON.stringify({ code: code, user_id: userId, muted_until: until });
}

function InitModule(ctx, logger, nk, initializer) {
  initializer.registerRpc("save_get", rpcSaveGet);
  initializer.registerRpc("save_put", rpcSavePut);
  initializer.registerAfterAuthenticateDevice(afterAuthenticateDevice);
  initializer.registerBeforeAuthenticateEmail(beforeAuthenticateEmail);
  initializer.registerAfterAuthenticateEmail(afterAuthenticateEmail);
  initializer.registerRpc("eclipse_profile", rpcProfile);
  initializer.registerRpc("admin_find", rpcAdminFind);
  initializer.registerRpc("admin_grant", rpcAdminGrant);
  initializer.registerRtBefore("ChannelJoin", beforeChannelJoin);
  initializer.registerRtBefore("ChannelMessageSend", beforeChannelMessageSend);
  initializer.registerRpc("chat_find", rpcChatFind);
  initializer.registerRpc("chat_report", rpcChatReport);
  initializer.registerRpc("admin_chat_reports", rpcAdminChatReports);
  initializer.registerRpc("admin_chat_resolve", rpcAdminChatResolve);
  initializer.registerRpc("admin_chat_mute", rpcAdminChatMute);
  logger.info("PROJECT ECLIPSE module đã nạp");
}

// Nakama tìm InitModule ở phạm vi toàn cục; dòng dưới để trình đóng gói không xóa hàm.
!InitModule && InitModule.bind(null);
