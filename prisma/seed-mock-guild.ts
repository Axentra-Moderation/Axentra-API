import "dotenv/config";
import { getPrisma } from "../src/utils/prisma";

const prisma = getPrisma();

async function main() {
  // Mock owner / target user (the specific user ID requested)
  const owner = await prisma.user.upsert({
    where: { id: "726507399640252416" },
    update: {},
    create: {
      id: "726507399640252416",
      username: "mock_user",
      discriminator: "0",
      globalName: "Mock User",
    },
  });

  // Reuse the same user as the ban target for convenience
  const target = await prisma.user.upsert({
    where: { id: "1500460522024468552" },
    update: {},
    create: {
      id: "1500460522024468552",
      username: "mock_user",
      discriminator: "0",
      globalName: "Mock User",
    },
  });

  // Mock moderator user (the one issuing the ban)
  const moderator = await prisma.user.upsert({
    where: { id: "726507399640252416" },
    update: {},
    create: {
      id: "726507399640252416",
      username: "mock_moderator",
      discriminator: "0",
      globalName: "Mock Moderator",
    },
  });

  // Mock guild with all required fields filled (the specific guild ID requested)
  const guild = await prisma.guild.upsert({
    where: { id: "1515831672543641661" },
    update: {},
    create: {
      id: "1515831672543641661",
      name: "Mock Test Guild",
      ownerId: owner.id,
      afkTimeout: 300,
      verificationLevel: 1,
      defaultMessageNotifications: 0,
      explicitContentFilter: 0,
      mfaLevel: 0,
      systemChannelFlags: 0,
      premiumTier: 0,
      nsfwLevel: 0,
      premiumProgressBarEnabled: false,
      features: [],
      settings: {},
    },
  });

  console.log("Seeded mock data:");
  console.log({ owner, target, moderator, guild });
}

main()
  .catch((err) => {
    console.error("Seed failed:", err);
    process.exit(1);
  })
  .finally(async () => {
    process.exit(0);
  });
