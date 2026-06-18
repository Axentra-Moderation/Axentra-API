// src/utils/generate-key.ts
import "dotenv/config";
import crypto from "crypto";
import { getPrisma } from "./prisma";

async function main() {
  const prisma = getPrisma();
  const label = process.argv[2] ?? "unnamed";

  const secret = crypto.randomBytes(32).toString("hex");
  const prefix = `mod_pk_${crypto.randomBytes(4).toString("hex")}`;
  const raw = `${prefix}.${secret}`;
  const hash = crypto.createHash("sha256").update(raw).digest("hex");

  await prisma.apiKey.create({
    data: { prefix, keyHash: hash, label },
  });

  console.log("\n✅ API key generated");
  console.log(`   Label:  ${label}`);
  console.log(`   Prefix: ${prefix}`);
  console.log(`   Key:    ${raw}`);
  console.log("\n⚠️  Copy this key now — it will never be shown again.\n");
}

main()
  .catch((err) => {
    console.error("Failed to generate key:", err);
    process.exit(1);
  })
  .finally(() => {
    const prisma = getPrisma();
    return prisma.$disconnect();
  });
