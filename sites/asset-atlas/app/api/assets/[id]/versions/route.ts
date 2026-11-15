import { asJson, bucket, readAsset, writeAsset } from "../../route";
export const dynamic = "force-dynamic";
const allowed = new Set(["image/png","image/webp","image/jpeg","image/gif"]);
export async function POST(request:Request,{params}:{params:Promise<{id:string}>}) {
  try {
    const {id}=await params; const asset=await readAsset(id); if(!asset)return asJson({error:"Không tìm thấy asset"},404);
    const form=await request.formData(); const file=form.get("file"); const note=String(form.get("note")||"");
    if(!(file instanceof File)||!allowed.has(file.type))return asJson({error:"Chỉ nhận PNG, WebP, JPEG hoặc GIF"},415);
    if(file.size>20*1024*1024)return asJson({error:"Mỗi file tối đa 20 MB"},413);
    const key=`assets/${id}/${crypto.randomUUID()}-${file.name.replace(/[^a-zA-Z0-9._-]/g,"_")}`;
    await bucket().put(key,await file.arrayBuffer(),{httpMetadata:{contentType:file.type}});
    const isOriginal=asset.versions.length===0;
    const version={id:crypto.randomUUID(),label:isOriginal?"v1 · Bản gốc":`v${asset.versions.length+1}`,role:isOriginal?"original":"option",url:`/api/files/${key}`,objectKey:key,note:note||(isOriginal?"File gốc · bất biến":"Option mới"),date:new Date().toLocaleDateString("vi-VN"),status:isOriginal?"Bản gốc":"Đang làm"};
    const next={...asset,versions:[version,...asset.versions],updated:"Vừa xong"}; await writeAsset(next); return asJson({version,asset:next},201);
  }catch(error){console.error("version upload failed",error);return asJson({error:"Không thể lưu file vào R2"},503)}
}
