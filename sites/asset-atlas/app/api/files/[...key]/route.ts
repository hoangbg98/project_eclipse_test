import { env } from "cloudflare:workers";
export const dynamic = "force-dynamic";
export async function GET(_request:Request,{params}:{params:Promise<{key:string[]}>}) {
  const {key}=await params; const objectKey=key.join("/");
  if(!objectKey.startsWith("assets/"))return new Response("Not found",{status:404});
  const object=await (env as unknown as CloudflareEnv).BUCKET.get(objectKey); if(!object)return new Response("Not found",{status:404});
  const headers=new Headers(); object.writeHttpMetadata(headers); headers.set("etag",object.httpEtag); headers.set("Cache-Control","private, max-age=3600");
  return new Response(object.body,{headers});
}
