// Module máy chủ Nakama của PROJECT ECLIPSE (M9-1). Chạy trong JS runtime của Nakama (goja), không cần build.
// Đặt trong thư mục runtime.path của Nakama; Nakama gọi InitModule khi khởi động.
//
// Chức năng giai đoạn 1:
//  - Tài khoản: đăng ký tên + email + mật khẩu (endpoint authenticate/email), đăng nhập bằng tên hoặc email.
//  - Mỗi tài khoản có một "mã người chơi" 8 chữ số (duy nhất), người chơi ghi vào nội dung chuyển khoản.
//  - eclipse_profile (người chơi gọi): mã, tên, ví (wallet).
//  - save_get / save_put (người chơi gọi): cloud save, mỗi tài khoản một thế giới (M9-3).
//  - Chat (M9-6): phòng thế giới + nhắn riêng, lọc từ, cấm chat, báo cáo, tra cứu theo mã (xem mục Chat bên dưới).
//  - Nạp tiền (M9-2): bảng giá, thưởng nạp lần đầu, thẻ tháng (xem mục Nạp tiền bên dưới).
//  - admin_find / admin_grant (chỉ gọi bằng http_key từ tool của QTV): tra cứu theo mã, phát tiền vào ví.
//    Mỗi lần phát cần mã giao dịch ngân hàng (ref) duy nhất: cùng ref lần hai bị từ chối (chống phát trùng).
//
// Không đặt số cân bằng / giá gói ở đây: QTV nhập số lượng khi phát.

var CODE_COLLECTION = "player_code";      // key = mã 8 số, owner = hệ thống, value {user_id}
var GRANT_COLLECTION = "admin_grant";     // key = ref, owner = hệ thống, value = bản ghi phát quà
var SYSTEM_USER = "00000000-0000-0000-0000-000000000000";
var ALLOWED_CURRENCIES = ["gems", "gold", "corona"];
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
    pack: String(req.pack || "").substring(0, 40), paid: Number(req.paid) || 0,
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

// ---------- Nạp tiền (M9-2) ----------
// Bảng giá (shop_catalog/main) do QTV đẩy lên từ data/shop/topup_packs.json (admin_set_packs): gói tiền tệ, thẻ tháng, thông tin
// nhận tiền. Người chơi chuyển khoản theo mã người chơi; QTV phát bằng admin_topup (kiểm số tiền đúng giá gói, thưởng nạp lần đầu
// tính ở máy chủ). Ví máy chủ (wallet) chỉ TĂNG khi nạp / nhận thẻ; game cộng phần chênh vào save (PurchasedCurrency).
//  - Thưởng nạp lần đầu: mỗi tài khoản, mỗi gói (first_bonus), mỗi "kỳ" (epoch); QTV tăng kỳ bằng admin_topup_reset để mở lại.
//  - Thẻ tháng: mỗi gói +30 lượt nhận; mỗi ngày (giờ Việt Nam) nhận 1 lượt; cứ `milestone_every` lượt nhận được thêm quà; tối đa max_days lượt.

var CATALOG_COLLECTION = "shop_catalog";
var TOPUP_CONFIG_COLLECTION = "topup_config";   // key "main": {epoch}
var TOPUP_STATE_COLLECTION = "topup_state";     // key = user_id: {bought:{pack:epoch}, log:[...], card:{...}}
var TOPUP_LOG_KEEP = 20;
var WALLET_CURRENCIES = ["gems", "corona"];

function readCatalog(nk) {
  var row = readOne(nk, CATALOG_COLLECTION, "main");
  return row ? row.value : null;
}

function findPack(catalog, id) {
  var packs = (catalog && catalog.packs) || [];
  for (var i = 0; i < packs.length; i++) {
    if (packs[i].id === id) {
      return packs[i];
    }
  }
  return null;
}

function topupEpoch(nk) {
  var row = readOne(nk, TOPUP_CONFIG_COLLECTION, "main");
  return row ? row.value.epoch : 1;
}

// Trạng thái nạp của một người chơi + version (để ghi có điều kiện).
function readTopupState(nk, userId) {
  var row = readOne(nk, TOPUP_STATE_COLLECTION, userId);
  var v = row ? row.value : {};
  return {
    version: row ? row.version : "*",
    value: { bought: v.bought || {}, log: v.log || [], card: v.card || { claims_left: 0, claims_total: 0, last_claim_day: "" } }
  };
}

function writeTopupState(nk, userId, st) {
  nk.storageWrite([{ collection: TOPUP_STATE_COLLECTION, key: userId, userId: SYSTEM_USER, value: st.value,
    version: st.version, permissionRead: 0, permissionWrite: 0 }]);
}

// Ngày theo giờ Việt Nam (mặc định UTC+7) dạng yyyy-mm-dd, dùng để giới hạn nhận thẻ 1 lần / ngày.
function dayKey(catalog) {
  var off = (catalog && catalog.card && catalog.card.reset_utc_offset_hours) || 7;
  return new Date(Date.now() + off * 3600000).toISOString().substring(0, 10);
}

function validateCatalog(c) {
  if (!c || !Array.isArray(c.packs) || c.packs.length === 0) {
    throw new Error("bảng giá thiếu packs");
  }
  var seen = {};
  for (var i = 0; i < c.packs.length; i++) {
    var k = c.packs[i];
    if (!/^[a-z0-9_]{2,32}$/.test(String(k.id || "")) || seen[k.id]) {
      throw new Error("id gói không hợp lệ hoặc trùng: " + k.id);
    }
    seen[k.id] = true;
    if (k.price !== null && !(typeof k.price === "number" && k.price > 0 && Math.floor(k.price) === k.price)) {
      throw new Error("giá gói " + k.id + " phải là số nguyên dương hoặc null (chưa bán)");
    }
    if (k.kind === "currency") {
      if (WALLET_CURRENCIES.indexOf(k.currency) < 0 || !(k.amount > 0) || Math.floor(k.amount) !== k.amount) {
        throw new Error("gói " + k.id + ": loại tiền hoặc số lượng không hợp lệ");
      }
    } else if (k.kind !== "card") {
      throw new Error("gói " + k.id + ": kind phải là currency hoặc card");
    }
  }
  var cd = c.card;
  if (cd && !(cd.days > 0 && cd.daily > 0 && cd.max_days >= cd.days && cd.milestone_every > 0 && cd.milestone_bonus >= 0)) {
    throw new Error("cấu hình thẻ tháng không hợp lệ");
  }
}

function rpcAdminSetPacks(ctx, logger, nk, payload) {
  requireAdmin(ctx);
  var req = JSON.parse(payload || "{}");
  validateCatalog(req.catalog);
  req.catalog.updated = Date.now();
  writeSystem(nk, CATALOG_COLLECTION, "main", req.catalog);
  return JSON.stringify({ packs: req.catalog.packs.length, updated: req.catalog.updated });
}

function rpcAdminTopupReset(ctx, logger, nk, payload) {
  requireAdmin(ctx);
  var req = JSON.parse(payload || "{}");
  if (!req.operator || String(req.operator).trim() === "") {
    throw new Error("thiếu tên QTV (operator)");
  }
  var epoch = topupEpoch(nk) + 1;
  writeSystem(nk, TOPUP_CONFIG_COLLECTION, "main", { epoch: epoch, reset_by: String(req.operator).trim(), reset_at: Date.now(), note: String(req.note || "") });
  logger.info("QTV %s mở lại thưởng nạp lần đầu: kỳ %d", req.operator, epoch);
  return JSON.stringify({ epoch: epoch });
}

// QTV: phát gói đã mua. Kiểm số tiền, ref không trùng, thưởng lần đầu, hạn thẻ tháng.
function rpcAdminTopup(ctx, logger, nk, payload) {
  requireAdmin(ctx);
  var req = JSON.parse(payload || "{}");
  var catalog = readCatalog(nk);
  if (!catalog) {
    throw new Error("máy chủ chưa có bảng giá (đẩy bảng giá: grant.ps1 tự đồng bộ khi dùng -Pack)");
  }
  var code = cleanCode(req.code);
  var ref = String(req.ref || "").trim();
  if (code.length !== CODE_LENGTH) {
    throw new Error("mã người chơi phải có " + CODE_LENGTH + " chữ số");
  }
  if (ref.length < 4 || ref.length > 64 || !/^[A-Za-z0-9._-]+$/.test(ref)) {
    throw new Error("ref (mã giao dịch ngân hàng) 4–64 ký tự: chữ, số, . _ -");
  }
  if (!req.operator || String(req.operator).trim() === "") {
    throw new Error("thiếu tên QTV (operator)");
  }
  var pack = findPack(catalog, String(req.pack || ""));
  if (!pack) {
    throw new Error("không có gói " + req.pack + " trong bảng giá");
  }
  if (pack.price === null) {
    throw new Error("gói " + pack.id + " chưa có giá (chưa mở bán)");
  }
  if (Number(req.paid) !== pack.price && !req.force) {
    throw new Error("so_tien_khong_khop: nhận " + Number(req.paid) + ", gói " + pack.id + " giá " + pack.price);
  }
  var userId = userIdByCode(nk, code);
  if (!userId) {
    throw new Error("không có người chơi mã " + code);
  }
  var epoch = topupEpoch(nk);
  var st = readTopupState(nk, userId);
  var changes = {};
  var base = 0;
  var bonus = 0;
  var cardDays = 0;
  if (pack.kind === "currency") {
    base = pack.amount;
    var last = st.value.bought[pack.id];
    bonus = pack.first_bonus && !(last >= epoch) ? pack.amount : 0;
    changes[pack.currency] = base + bonus;
    st.value.bought[pack.id] = epoch;
  } else {
    cardDays = catalog.card.days;
    if (st.value.card.claims_left + cardDays > catalog.card.max_days) {
      throw new Error("thẻ tháng tối đa " + catalog.card.max_days + " ngày (đang còn " + st.value.card.claims_left + ")");
    }
    st.value.card.claims_left += cardDays;
  }
  var record = {
    code: code, user_id: userId, changes: changes, ref: ref, note: String(req.note || ""), operator: String(req.operator).trim(),
    pack: pack.id, paid: Number(req.paid) || 0, base: base, bonus: bonus, card_days: cardDays, forced: !!req.force,
    time: Math.floor(Date.now() / 1000)
  };
  try {
    nk.storageWrite([{ collection: GRANT_COLLECTION, key: ref, userId: SYSTEM_USER, value: record, version: "*", permissionRead: 0, permissionWrite: 0 }]);
  } catch (e) {
    throw new Error("ref " + ref + " đã được dùng (đã phát quà cho giao dịch này)");
  }
  st.value.log.unshift({ t: record.time, pack: pack.id, base: base, bonus: bonus, card_days: cardDays, paid: record.paid, ref: ref });
  st.value.log = st.value.log.slice(0, TOPUP_LOG_KEEP);
  try {
    writeTopupState(nk, userId, st);
    if (Object.keys(changes).length > 0) {
      nk.walletUpdate(userId, changes, { reason: "topup", pack: pack.id, ref: ref, operator: record.operator, bonus: bonus }, true);
    }
  } catch (e) {
    nk.storageDelete([{ collection: GRANT_COLLECTION, key: ref, userId: SYSTEM_USER }]);
    throw new Error("không phát được (thử lại): " + e.message);
  }
  logger.info("QTV %s phát gói %s cho %s (ref %s, nhận %d, thưởng %d)", record.operator, pack.id, code, ref, record.paid, bonus);
  var out = profileOf(nk, userId, code);
  out.granted = { pack: pack.id, base: base, bonus: bonus, card_days: cardDays };
  return JSON.stringify(out);
}

// QTV: xem trạng thái nạp của một người chơi (thưởng lần đầu đã dùng, thẻ tháng, lịch sử).
function rpcAdminTopupState(ctx, logger, nk, payload) {
  requireAdmin(ctx);
  var req = JSON.parse(payload || "{}");
  var code = cleanCode(req.code);
  var userId = userIdByCode(nk, code);
  if (!userId) {
    throw new Error("không có người chơi mã " + code);
  }
  var st = readTopupState(nk, userId).value;
  return JSON.stringify({ code: code, epoch: topupEpoch(nk), bought: st.bought, card: st.card, log: st.log });
}

// QTV: sửa thẻ tháng khi có sự cố (vd bù ngày). Chỉ các trường được truyền mới đổi.
function rpcAdminCardSet(ctx, logger, nk, payload) {
  requireAdmin(ctx);
  var req = JSON.parse(payload || "{}");
  var catalog = readCatalog(nk);
  var userId = userIdByCode(nk, cleanCode(req.code));
  if (!userId || !catalog) {
    throw new Error("không có người chơi hoặc bảng giá");
  }
  if (!req.operator || String(req.operator).trim() === "") {
    throw new Error("thiếu tên QTV (operator)");
  }
  var st = readTopupState(nk, userId);
  var card = st.value.card;
  if (req.claims_left !== undefined) {
    if (!(req.claims_left >= 0 && req.claims_left <= catalog.card.max_days)) {
      throw new Error("claims_left 0.." + catalog.card.max_days);
    }
    card.claims_left = req.claims_left;
  }
  if (req.claims_total !== undefined) {
    card.claims_total = Math.max(0, Math.floor(req.claims_total));
  }
  if (req.last_claim_day !== undefined) {
    card.last_claim_day = String(req.last_claim_day);
  }
  writeTopupState(nk, userId, st);
  logger.info("QTV %s sửa thẻ tháng của %s: %s", req.operator, req.code, JSON.stringify(card));
  return JSON.stringify({ card: card });
}

function cardView(catalog, st) {
  var c = st.card;
  var cd = (catalog && catalog.card) || { daily: 0, milestone_every: 1, milestone_bonus: 0 };
  var nextTotal = c.claims_total + 1;
  return {
    claims_left: c.claims_left, claims_total: c.claims_total,
    can_claim: c.claims_left > 0 && c.last_claim_day !== dayKey(catalog),
    next_gems: cd.daily + (nextTotal % cd.milestone_every === 0 ? cd.milestone_bonus : 0),
    until_milestone: cd.milestone_every - (c.claims_total % cd.milestone_every)
  };
}

// Người chơi: bảng giá hiện hành, gói nào còn thưởng lần đầu, thẻ tháng, lịch sử nạp gần đây, thông tin nhận tiền.
function rpcTopupInfo(ctx, logger, nk, payload) {
  if (!ctx.userId) {
    throw new Error("cần đăng nhập");
  }
  var catalog = readCatalog(nk);
  var st = readTopupState(nk, ctx.userId).value;
  var epoch = topupEpoch(nk);
  var eligible = {};
  var packs = (catalog && catalog.packs) || [];
  for (var i = 0; i < packs.length; i++) {
    if (packs[i].first_bonus) {
      eligible[packs[i].id] = !(st.bought[packs[i].id] >= epoch);
    }
  }
  return JSON.stringify({
    catalog: catalog, eligible: eligible, card: cardView(catalog, st), log: st.log.slice(0, 10),
    code: ensureCode(nk, logger, ctx.userId)
  });
}

// Người chơi: nhận quà thẻ tháng hôm nay.
function rpcCardClaim(ctx, logger, nk, payload) {
  if (!ctx.userId) {
    throw new Error("cần đăng nhập");
  }
  var catalog = readCatalog(nk);
  if (!catalog || !catalog.card) {
    throw new Error("card_none");
  }
  var st = readTopupState(nk, ctx.userId);
  var card = st.value.card;
  if (card.claims_left <= 0) {
    throw new Error("card_none");
  }
  var today = dayKey(catalog);
  if (card.last_claim_day === today) {
    throw new Error("card_claimed_today");
  }
  card.claims_left -= 1;
  card.claims_total += 1;
  card.last_claim_day = today;
  var bonus = card.claims_total % catalog.card.milestone_every === 0 ? catalog.card.milestone_bonus : 0;
  var gems = catalog.card.daily + bonus;
  try {
    writeTopupState(nk, ctx.userId, st);   // ghi có điều kiện: hai lần bấm cùng lúc chỉ một lần thành công
  } catch (e) {
    throw new Error("card_claimed_today");
  }
  nk.walletUpdate(ctx.userId, { gems: gems }, { reason: "card_claim", day: today, claims_total: card.claims_total, bonus: bonus }, true);
  return JSON.stringify({ gems: gems, daily: catalog.card.daily, bonus: bonus, card: cardView(catalog, st.value) });
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
  initializer.registerRpc("admin_set_packs", rpcAdminSetPacks);
  initializer.registerRpc("admin_topup", rpcAdminTopup);
  initializer.registerRpc("admin_topup_reset", rpcAdminTopupReset);
  initializer.registerRpc("admin_topup_state", rpcAdminTopupState);
  initializer.registerRpc("admin_card_set", rpcAdminCardSet);
  initializer.registerRpc("topup_info", rpcTopupInfo);
  initializer.registerRpc("card_claim", rpcCardClaim);
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
