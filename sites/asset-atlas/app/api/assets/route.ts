import { env } from "cloudflare:workers";
import { seedAssets } from "@/lib/seed-assets";

export const dynamic = "force-dynamic";
type AssetRecord = Omit<(typeof seedAssets)[number], "versions"> & { versions: Array<Record<string, any>> } & Record<string, any>;
const db = () => (env as unknown as CloudflareEnv).DB;
const bucket = () => (env as unknown as CloudflareEnv).BUCKET;

async function ensureSeed() {
  const database = db();
  const count = await database.prepare("SELECT COUNT(*) AS total FROM assets").first<{ total: number }>();
  if (!count?.total) {
    await database.batch(seedAssets.map(asset => database.prepare("INSERT OR IGNORE INTO assets (id, record_json, updated_at) VALUES (?, ?, CURRENT_TIMESTAMP)").bind(asset.id, JSON.stringify(asset))));
  }
}
async function readAsset(id: string): Promise<AssetRecord | null> {
  const row = await db().prepare("SELECT record_json FROM assets WHERE id = ?").bind(id).first<{ record_json: string }>();
  return row ? JSON.parse(row.record_json) as AssetRecord : null;
}
async function writeAsset(asset: AssetRecord) {
  await db().prepare("INSERT INTO assets (id, record_json, updated_at) VALUES (?, ?, CURRENT_TIMESTAMP) ON CONFLICT(id) DO UPDATE SET record_json=excluded.record_json, updated_at=CURRENT_TIMESTAMP").bind(asset.id, JSON.stringify(asset)).run();
}
function asJson(data: unknown, status=200) { return Response.json(data, { status, headers: { "Cache-Control": "no-store" } }); }

export async function GET() {
  try { await ensureSeed(); const rows = await db().prepare("SELECT record_json FROM assets ORDER BY updated_at DESC").all<{record_json:string}>(); return asJson({assets:rows.results.map(r=>JSON.parse(r.record_json))}); }
  catch (error) { console.error("asset index unavailable", error); return asJson({error:"Kho metadata chưa sẵn sàng"},503); }
}
export async function POST(request: Request) {
  try {
    const asset = await request.json() as AssetRecord;
    if (!asset.id || !asset.name || !asset.brief) return asJson({error:"Thiếu tên hoặc brief"},400);
    await ensureSeed();
    const exists = await readAsset(asset.id);
    if (exists) return asJson({error:"ID asset đã tồn tại"},409);
    await writeAsset(asset);
    return asJson({asset},201);
  } catch (error) { console.error("asset create failed", error); return asJson({error:"Không thể tạo asset"},503); }
}

export { readAsset, writeAsset, asJson, bucket };
