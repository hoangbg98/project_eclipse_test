import { asJson, readAsset, writeAsset } from "../route";
export const dynamic = "force-dynamic";
export async function PATCH(request:Request,{params}:{params:Promise<{id:string}>}) {
  try { const {id}=await params; const current=await readAsset(id); if(!current)return asJson({error:"Không tìm thấy asset"},404); const patch=await request.json() as Record<string,unknown>; const next={...current,...patch,id}; await writeAsset(next); return asJson({asset:next}); }
  catch(error){console.error("asset update failed",error);return asJson({error:"Không thể cập nhật asset"},503)}
}
