/// <reference types="@cloudflare/workers-types" />
interface CloudflareEnv {
  DB: D1Database;
  BUCKET: R2Bucket;
}
declare namespace Cloudflare { interface Env { DB: D1Database; BUCKET: R2Bucket } }
