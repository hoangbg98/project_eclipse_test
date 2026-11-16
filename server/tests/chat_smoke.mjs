// Kiểm tra module chat trên máy chủ THẬT (Nakama đang chạy), không cần Godot. Cần Node >= 22 (WebSocket có sẵn).
// Chạy: node server/tests/chat_smoke.mjs [--server http://127.0.0.1:7360]
// Tạo vài tài khoản chat_t<số> (tên ngẫu nhiên mỗi lần) rồi kiểm: vào phòng, gửi / nhận, lọc từ, giãn cách, độ dài,
// kênh không cho phép, nhắn riêng + thông báo cho người nhận, chặn, báo cáo, cấm chat (cần secrets.json của máy chủ thử).
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const args = process.argv.slice(2);
const SERVER = args.includes("--server") ? args[args.indexOf("--server") + 1] : "http://127.0.0.1:7360";
const KEY = "eclipse-test-key";
const secrets = JSON.parse(fs.readFileSync(path.join(here, "..", ".runtime", "secrets.json"), "utf8"));
const basic = "Basic " + Buffer.from(KEY + ":").toString("base64");
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

let fails = 0;
function check(ok, what, extra = "") {
  console.log((ok ? "  ĐẠT  " : "  LỖI  ") + what + (ok ? "" : "   " + extra));
  if (!ok) fails++;
}

async function json(url, opts = {}) {
  const r = await fetch(url, opts);
  const t = await r.text();
  let body = null;
  try { body = JSON.parse(t); } catch { body = t; }
  return { status: r.status, body };
}

const stamp = String(Date.now() % 1000000);
async function account(label) {
  const name = `chat_${label}${stamp}`;
  const r = await json(`${SERVER}/v2/account/authenticate/email?create=true&username=${name}`, {
    method: "POST", headers: { Authorization: basic, "Content-Type": "application/json" },
    body: JSON.stringify({ email: `${name}@example.com`, password: "matkhau123" }),
  });
  const token = r.body.token;
  const uid = JSON.parse(Buffer.from(token.split(".")[1], "base64").toString()).uid;
  return { name, token, uid };
}

async function rpc(user, id, payload) {
  const r = await json(`${SERVER}/v2/rpc/${id}`, {
    method: "POST", headers: { Authorization: "Bearer " + user.token, "Content-Type": "application/json" },
    body: JSON.stringify(JSON.stringify(payload)),
  });
  return r.status === 200 ? { ok: true, data: JSON.parse(r.body.payload) } : { ok: false, error: r.body.message || String(r.body) };
}
async function admin(id, payload) {
  const r = await json(`${SERVER}/v2/rpc/${id}?http_key=${secrets.http_key}&unwrap`, {
    method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(payload),
  });
  return r.status === 200 ? { ok: true, data: r.body } : { ok: false, error: r.body.message || String(r.body) };
}

function socket(user) {
  const ws = new WebSocket(SERVER.replace("http", "ws") + "/ws?format=json&token=" + user.token);
  const inbox = [];
  const waiters = {};
  let cid = 0;
  ws.onmessage = (e) => {
    const m = JSON.parse(e.data);
    inbox.push(m);
    if (m.cid && waiters[m.cid]) { waiters[m.cid](m); delete waiters[m.cid]; }
  };
  ws.call = (obj) => new Promise((res) => { const c = String(++cid); waiters[c] = res; ws.send(JSON.stringify({ cid: c, ...obj })); });
  ws.inbox = inbox;
  return new Promise((res) => { ws.onopen = () => res(ws); });
}
const send = (ws, channelId, text) => ws.call({ channel_message_send: { channel_id: channelId, content: JSON.stringify({ text }) } });
const errMsg = (m) => (m.error ? m.error.message : "");

console.log("Máy chủ:", SERVER);
const a = await account("a"), b = await account("b"), c = await account("c");
const wa = await socket(a), wb = await socket(b), wc = await socket(c);

// --- phòng thế giới
const ja = await wa.call({ channel_join: { target: "world", type: 1, persistence: true, hidden: false } });
const jb = await wb.call({ channel_join: { target: "world", type: 1, persistence: true, hidden: false } });
await wc.call({ channel_join: { target: "world", type: 1, persistence: true, hidden: false } });
check(ja.channel && ja.channel.id === "2...world", "vào phòng world", JSON.stringify(ja));
const other = await wa.call({ channel_join: { target: "phong_khac", type: 1, persistence: true, hidden: false } });
check(errMsg(other).includes("chat_channel_not_allowed"), "không được tạo phòng khác", JSON.stringify(other));
const grp = await wa.call({ channel_join: { target: "abc", type: 3, persistence: true, hidden: false } });
check(errMsg(grp).includes("chat_channel_not_allowed"), "không được vào kênh nhóm", JSON.stringify(grp));

const world = ja.channel.id;
let r = await send(wa, world, "xin chào   cả nhà");
check(!!r.channel_message_ack, "gửi tin vào world", JSON.stringify(r));
await sleep(150);
const got = wb.inbox.find((m) => m.channel_message && JSON.parse(m.channel_message.content).text === "xin chào cả nhà");
check(!!got, "người khác nhận được, khoảng trắng thừa được gộp");

await sleep(900);
r = await send(wa, world, "đm mày vcl lớn quá");
await sleep(150);
const filtered = wb.inbox.filter((m) => m.channel_message).map((m) => JSON.parse(m.channel_message.content).text).pop();
check(filtered === "** mày *** lớn quá", "lọc từ cấm, giữ nguyên 'lớn'", filtered);

r = await send(wa, world, "tin ngay sau");
check(errMsg(r).includes("chat_rate"), "gửi quá nhanh bị chặn", JSON.stringify(r));
await sleep(900);
r = await send(wa, world, "x".repeat(201));
check(errMsg(r).includes("chat_too_long"), "tin quá dài bị từ chối", JSON.stringify(r));
await sleep(900);
r = await send(wa, world, "   ");
check(errMsg(r).includes("chat_empty"), "tin rỗng bị từ chối", JSON.stringify(r));

// --- lịch sử
const hist = await json(`${SERVER}/v2/channel/${encodeURIComponent(world)}?limit=10&forward=false`, { headers: { Authorization: "Bearer " + b.token } });
check(hist.status === 200 && hist.body.messages.length >= 2, "đọc được lịch sử phòng", JSON.stringify(hist.body).slice(0, 120));

// --- tra cứu theo mã
const profB = await rpc(b, "eclipse_profile", {});
const found = await rpc(a, "chat_find", { code: profB.data.code });
check(found.ok && found.data.user_id === b.uid && found.data.username === b.name, "chat_find theo mã người chơi", JSON.stringify(found));
const notFound = await rpc(a, "chat_find", { code: "12345678" });
check(!notFound.ok && notFound.error.includes("chat_not_found"), "chat_find mã không tồn tại");

// --- nhắn riêng + thông báo
await sleep(900);
const dm = await wa.call({ channel_join: { target: b.uid, type: 2, persistence: true, hidden: false } });
const dmId = dm.channel.id;
r = await send(wa, dmId, "chào B, nhắn riêng nè");
check(!!r.channel_message_ack, "A gửi nhắn riêng cho B", JSON.stringify(r));
await sleep(300);
const note = wb.inbox.find((m) => m.notifications && m.notifications.notifications.some((n) => n.code === 100));
check(!!note, "B nhận thông báo có tin nhắn riêng (code 100)", JSON.stringify(wb.inbox.slice(-3)).slice(0, 300));
if (note) {
  const n = note.notifications.notifications.find((x) => x.code === 100);
  check(JSON.parse(n.content).from_id === a.uid && JSON.parse(n.content).text === "chào B, nhắn riêng nè", "thông báo có người gửi + xem trước");
}
const dmB = await wb.call({ channel_join: { target: a.uid, type: 2, persistence: true, hidden: false } });
check(dmB.channel && dmB.channel.id === dmId, "B vào cùng kênh nhắn riêng", JSON.stringify(dmB).slice(0, 200));
await sleep(900);
r = await send(wb, dmId, "B trả lời");
await sleep(200);
check(wa.inbox.some((m) => m.channel_message && m.channel_message.channel_id === dmId && JSON.parse(m.channel_message.content).text === "B trả lời"), "A nhận trả lời của B");
const dmHist = await json(`${SERVER}/v2/channel/${encodeURIComponent(dmId)}?limit=10&forward=false`, { headers: { Authorization: "Bearer " + b.token } });
check(dmHist.status === 200 && dmHist.body.messages.length === 2, "lịch sử nhắn riêng đủ 2 tin");

// --- chặn
const blk = await json(`${SERVER}/v2/friend/block?ids=${a.uid}`, { method: "POST", headers: { Authorization: "Bearer " + b.token } });
check(blk.status === 200, "B chặn A", JSON.stringify(blk));
await sleep(900);
r = await send(wa, dmId, "A nhắn sau khi bị chặn");
check(errMsg(r).includes("chat_blocked"), "A không nhắn riêng được cho B nữa", JSON.stringify(r));
await json(`${SERVER}/v2/friend?ids=${a.uid}`, { method: "DELETE", headers: { Authorization: "Bearer " + b.token } });
await sleep(900);
r = await send(wa, dmId, "A nhắn sau khi bỏ chặn");
// Nakama đẩy A ra khỏi kênh riêng khi bị chặn: phải vào lại kênh (game tự làm: gặp lỗi này thì vào lại rồi gửi lại 1 lần).
check(errMsg(r).includes("Must join channel"), "sau khi bị chặn A bị đẩy khỏi kênh riêng", JSON.stringify(r));
await wa.call({ channel_join: { target: b.uid, type: 2, persistence: true, hidden: false } });
await sleep(900);
r = await send(wa, dmId, "A nhắn sau khi vào lại kênh");
check(!!r.channel_message_ack, "bỏ chặn + vào lại kênh thì nhắn được", JSON.stringify(r));

// --- báo cáo + QTV
const rep = await rpc(b, "chat_report", { target_id: a.uid, reason: "abuse", channel_id: world, message_id: "m1", text: "đm mày" });
check(rep.ok && rep.data.id, "B báo cáo A", JSON.stringify(rep));
const self = await rpc(b, "chat_report", { target_id: b.uid, reason: "abuse" });
check(!self.ok, "không báo cáo chính mình");
const list = await admin("admin_chat_reports", { limit: 20 });
const mine = list.ok && list.data.reports.find((x) => x.id === rep.data.id);
check(!!mine && mine.target_name === a.name && mine.reporter_name === b.name && mine.reason === "abuse", "QTV thấy báo cáo", JSON.stringify(list).slice(0, 200));
const asUser = await rpc(a, "admin_chat_reports", {});
check(!asUser.ok, "người chơi không gọi được RPC của QTV");
const res = await admin("admin_chat_resolve", { id: rep.data.id, operator: "test" });
check(res.ok, "QTV đánh dấu đã xử lý");
const list2 = await admin("admin_chat_reports", { limit: 50 });
check(list2.ok && !list2.data.reports.find((x) => x.id === rep.data.id), "báo cáo đã xử lý không còn trong danh sách mới");

const profA = await rpc(a, "eclipse_profile", {});
const mute = await admin("admin_chat_mute", { code: profA.data.code, minutes: 5, reason: "test", operator: "test" });
check(mute.ok && mute.data.muted_until > Date.now(), "QTV cấm chat A 5 phút", JSON.stringify(mute));
await sleep(900);
r = await send(wa, world, "A đang bị cấm");
check(errMsg(r).startsWith("Error: chat_muted:") || errMsg(r).includes("chat_muted:"), "A bị cấm chat", JSON.stringify(r));
await admin("admin_chat_mute", { code: profA.data.code, minutes: 0, operator: "test" });
await sleep(900);
r = await send(wa, world, "A hết bị cấm");
check(!!r.channel_message_ack, "gỡ cấm thì chat lại được", JSON.stringify(r));

wa.close(); wb.close(); wc.close();
console.log(fails === 0 ? "ĐẠT" : `CÓ ${fails} BƯỚC LỖI`);
process.exit(fails === 0 ? 0 : 1);
