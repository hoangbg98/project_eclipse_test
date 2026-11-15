import { asJson, bucket, readAsset, writeAsset } from "../../../../route";
export const dynamic = "force-dynamic";
export async function POST(_request:Request,{params}:{params:Promise<{id:string;versionId:string}>}) {
  try {
    const {id,versionId}=await params; const asset=await readAsset(id); if(!asset)return asJson({error:"Không tìm thấy asset"},404);
    const previous=asset.versions.find((v:any)=>v.id===versionId); if(!previous?.objectKey)return asJson({error:"Bản này không có file lưu trữ"},404);
    const source=await bucket().get(previous.objectKey); if(!source)return asJson({error:"File phiên bản không còn trong kho"},404);
    const key=`assets/${id}/${crypto.randomUUID()}-restore`;
    await bucket().put(key,source.body,{httpMetadata:source.httpMetadata});
    const version={...previous,id:crypto.randomUUID(),label:`v${asset.versions.length+1} · phục hồi`,role:"option",url:`/api/files/${key}`,objectKey:key,note:`Phục hồi từ ${previous.label}`,date:new Date().toLocaleDateString("vi-VN"),status:"Đang làm"};
    const next={...asset,versions:[version,...asset.versions],updated:"Vừa phục hồi",status:"Đang làm"}; await writeAsset(next); return asJson({version,asset:next},201);
  }catch(error){console.error("version restore failed",error);return asJson({error:"Không thể phục hồi phiên bản"},503)}
}
