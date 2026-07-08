import { Response } from "express";
import { asyncHandler } from "../../utils/asyncHandler";
import { sendSuccess } from "../../utils/ApiResponse";
import {
  createOneToOneChannel,
  generateStreamToken,
} from "./stream.service";

export const getStreamToken = asyncHandler(async (req: any, res: Response) => {
  const data = await generateStreamToken(req.user);

  return sendSuccess({
    res,
    message: "Stream token generated successfully",
    data,
  });
});

export const createStreamChannel = asyncHandler(
  async (req: any, res: Response) => {
    const { targetUserId, jobId } = req.body;

    const data = await createOneToOneChannel(
      req.user,
      targetUserId,
      typeof jobId === "string" && jobId.trim().length > 0
        ? jobId.trim()
        : undefined
    );

    return sendSuccess({
      res,
      message: "Stream channel ready",
      data,
    });
  }
);
