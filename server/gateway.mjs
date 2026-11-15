// Cổng vào máy chủ thử nghiệm (M10): một địa chỉ cho cả Nakama và file nhạc của chế độ nhịp điệu.
//   GET /music/<tên file>  -> server/music/charts/<tên> hoặc server/music/<tên> (catalog.json, bản nốt .json, nhạc .wav/.ogg/.mp3)
//   mọi đường dẫn khác      -> chuyển tiếp tới Nakama (http://127.0.0.1:7350), kể cả websocket
// Không cần thư viện ngoài (Node >= 18). Chạy: node server/gateway.mjs [--port 7360] [--host 127.0.0.1]
// start_local.ps1 tự bật; tunnel.ps1 trỏ đường hầm vào cổng này.
import http from "node:http";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const MUSIC = path.join(here, "music");
const args = process.argv.slice(2);
const opt = (name, def) => {
  const i = args.indexOf(name);
  return i >= 0 && args[i + 1] ? args[i + 1] : def;
};
const PORT = Number(opt("--port", "7360"));
const HOST = opt("--host", "127.0.0.1");
const NAKAMA_HOST = opt("--nakama-host", "127.0.0.1");
const NAKAMA_PORT = Number(opt("--nakama-port", "7350"));

const TYPES = { ".json": "application/json; charset=utf-8", ".wav": "audio/wav", ".ogg": "audio/ogg", ".mp3": "audio/mpeg" };
const NAME_RE = /^[A-Za-z0-9_][A-Za-z0-9_.-]{0,119}$/;
const HIDDEN = new Set(["songs.json"]);

function musicFile(name) {
  if (!NAME_RE.test(name) || HIDDEN.has(name) || !TYPES[path.extname(name).toLowerCase()]) return null;
  for (const dir of [path.join(MUSIC, "charts"), MUSIC]) {
    const p = path.join(dir, name);
    if (path.dirname(p) === dir && fs.existsSync(p) && fs.statSync(p).isFile()) return p;
  }
  return null;
}

function serveMusic(req, res, name) {
  if (req.method !== "GET" && req.method !== "HEAD") {
    res.writeHead(405).end();
    return;
  }
  const p = musicFile(name);
  if (!p) {
    res.writeHead(404, { "Content-Type": "text/plain" }).end("not found");
    return;
  }
  const st = fs.statSync(p);
  res.writeHead(200, {
    "Content-Type": TYPES[path.extname(p).toLowerCase()],
    "Content-Length": st.size,
    // Danh mục đổi khi thêm bài; file nhạc / bản nốt được game kiểm sha256 nên cache ngắn là đủ.
    "Cache-Control": name === "catalog.json" ? "no-cache" : "public, max-age=300",
  });
  if (req.method === "HEAD") {
    res.end();
    return;
  }
  fs.createReadStream(p).pipe(res);
}

function proxy(req, res) {
  const up = http.request(
    { host: NAKAMA_HOST, port: NAKAMA_PORT, method: req.method, path: req.url, headers: req.headers },
    (r) => {
      res.writeHead(r.statusCode || 502, r.headers);
      r.pipe(res);
    }
  );
  up.on("error", () => {
    if (!res.headersSent) res.writeHead(502, { "Content-Type": "text/plain" });
    res.end("nakama unavailable");
  });
  req.pipe(up);
}

const server = http.createServer((req, res) => {
  const url = new URL(req.url, "http://x");
  if (url.pathname.startsWith("/music/")) {
    serveMusic(req, res, decodeURIComponent(url.pathname.slice("/music/".length)));
    return;
  }
  proxy(req, res);
});

// Websocket (chat sau này): nối thẳng socket tới Nakama.
server.on("upgrade", (req, socket, head) => {
  const up = http.request({ host: NAKAMA_HOST, port: NAKAMA_PORT, method: req.method, path: req.url, headers: req.headers });
  up.on("upgrade", (r, upSocket, upHead) => {
    let lines = `HTTP/1.1 ${r.statusCode} ${r.statusMessage}\r\n`;
    for (let i = 0; i < r.rawHeaders.length; i += 2) lines += `${r.rawHeaders[i]}: ${r.rawHeaders[i + 1]}\r\n`;
    socket.write(lines + "\r\n");
    if (upHead && upHead.length) socket.write(upHead);
    if (head && head.length) upSocket.write(head);
    upSocket.pipe(socket).pipe(upSocket);
    upSocket.on("error", () => socket.destroy());
    socket.on("error", () => upSocket.destroy());
  });
  up.on("error", () => socket.destroy());
  up.end();
});

server.listen(PORT, HOST, () => {
  console.log(`gateway: http://${HOST}:${PORT} -> nakama ${NAKAMA_HOST}:${NAKAMA_PORT}, /music/ -> ${MUSIC}`);
});
