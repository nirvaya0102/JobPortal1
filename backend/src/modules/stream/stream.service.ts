import { StreamChat } from "stream-chat";
import prisma from "../../lib/prisma";
import { AppError } from "../../utils/AppError";

const apiKey = process.env.STREAM_API_KEY;
const apiSecret = process.env.STREAM_API_SECRET;

if (!apiKey || !apiSecret) {
  console.warn("STREAM_API_KEY or STREAM_API_SECRET is not configured");
}

const streamClient =
  apiKey && apiSecret ? StreamChat.getInstance(apiKey, apiSecret) : null;

type AuthUser = {
  userId: string;
  role: string;
};

const safeUserSelect = {
  id: true,
  name: true,
  role: true,
};

function requireStreamClient() {
  if (!apiKey || !apiSecret || !streamClient) {
    throw new AppError("Stream Chat is not configured", 500);
  }

  return streamClient;
}

function streamUserId(userId: string) {
  return userId.replace(/[^a-zA-Z0-9@_-]/g, "_");
}

function channelIdFor(userA: string, userB: string, jobId?: string) {
  const sortedUsers = [streamUserId(userA), streamUserId(userB)].sort();
  const safeJobId = jobId ? streamUserId(jobId) : "general";
  return `jobportal_${sortedUsers[0]}_${sortedUsers[1]}_${safeJobId}`;
}

function assertValidRolePair(currentRole: string, targetRole: string) {
  if (currentRole === "ADMIN" || targetRole === "ADMIN") {
    return;
  }

  const roles = [currentRole, targetRole].sort().join(":");
  if (roles !== "CANDIDATE:EMPLOYER") {
    throw new AppError(
      "Chat is only available between candidates and employers",
      403
    );
  }
}

function isChannelAlreadyExistsError(error: unknown) {
  const maybeError = error as {
    code?: number;
    statusCode?: number;
    message?: string;
  };
  const message = maybeError.message?.toLowerCase() ?? "";
  return (
    maybeError.code === 16 ||
    maybeError.statusCode === 409 ||
    message.includes("already exists")
  );
}

export async function generateStreamToken(authUser: AuthUser) {
  if (!authUser?.userId) {
    throw new AppError("Unauthorized", 401);
  }

  const client = requireStreamClient();

  const user = await prisma.user.findUnique({
    where: { id: authUser.userId },
    select: safeUserSelect,
  });

  if (!user) {
    throw new AppError("User not found", 404);
  }

  const id = streamUserId(user.id);

  await client.upsertUser({
    id,
    name: user.name,
    role: user.role,
  });

  return {
    apiKey,
    token: client.createToken(id),
    user: {
      id,
      name: user.name,
      role: user.role,
    },
  };
}

export async function createOneToOneChannel(
  authUser: AuthUser,
  targetUserId: string,
  jobId?: string
) {
  if (!authUser?.userId) {
    throw new AppError("Unauthorized", 401);
  }

  if (!targetUserId || targetUserId === authUser.userId) {
    throw new AppError("A valid target user is required", 400);
  }

  const client = requireStreamClient();

  const [currentUser, targetUser] = await Promise.all([
    prisma.user.findUnique({
      where: { id: authUser.userId },
      select: safeUserSelect,
    }),
    prisma.user.findUnique({
      where: { id: targetUserId },
      select: safeUserSelect,
    }),
  ]);

  if (!currentUser) {
    throw new AppError("User not found", 404);
  }

  if (!targetUser) {
    throw new AppError("Target user not found", 404);
  }

  assertValidRolePair(currentUser.role, targetUser.role);

  const currentStreamId = streamUserId(currentUser.id);
  const targetStreamId = streamUserId(targetUser.id);

  await client.upsertUsers([
    {
      id: currentStreamId,
      name: currentUser.name,
      role: currentUser.role,
    },
    {
      id: targetStreamId,
      name: targetUser.name,
      role: targetUser.role,
    },
  ]);

  const channelType = "messaging";
  const channelId = channelIdFor(currentUser.id, targetUser.id, jobId);
  const channel = client.channel(channelType, channelId, {
    members: [currentStreamId, targetStreamId],
    created_by_id: currentStreamId,
    ...(jobId && { jobId }),
  });

  try {
    await channel.create();
  } catch (error) {
    if (!isChannelAlreadyExistsError(error)) {
      throw error;
    }
  }

  return {
    channelId,
    channelType,
  };
}
