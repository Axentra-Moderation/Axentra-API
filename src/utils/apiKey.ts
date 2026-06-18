// src/utils/apiKey.ts
import crypto from "crypto";

export function generateApiKey(): {
  raw: string;
  prefix: string;
  hash: string;
} {
  const secret = crypto.randomBytes(32).toString("hex"); // 64-char hex
  const prefix = `mod_pk_${crypto.randomBytes(4).toString("hex")}`;
  const raw = `${prefix}.${secret}`;
  const hash = crypto.createHash("sha256").update(raw).digest("hex");

  return { raw, prefix, hash };
}
