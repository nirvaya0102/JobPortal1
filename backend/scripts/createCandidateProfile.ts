import prisma from "../src/lib/prisma";

async function main() {
  await prisma.candidateProfile.upsert({
    where: {
      userId: "54432f10-d8dd-426c-910e-a053a7478761",
    },
    update: {
      headline: "Flutter Developer",
      bio: "Passionate developer learning mobile app development.",
      skills: "Flutter, Dart, Firebase",
      resumeUrl: null,
    },
    create: {
      userId: "54432f10-d8dd-426c-910e-a053a7478761",
      headline: "Flutter Developer",
      bio: "Passionate developer learning mobile app development.",
      skills: "Flutter, Dart, Firebase",
      resumeUrl: null,
    },
  });

  console.log("Candidate profile created/updated successfully.");
}

main()
  .catch(console.error)
  .finally(async () => {
    await prisma.$disconnect();
  });