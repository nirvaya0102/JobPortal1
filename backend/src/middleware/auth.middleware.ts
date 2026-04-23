import { Request, Response, NextFunction } from "express";
import { verifyToken } from "../lib/jwt";

export const authMiddleware = (req: any, res: Response, next: NextFunction) => {
    try {
        const authHeader = req.headers.authorization;

        if (!authHeader) {
            return res.status(401).json({ success: false, message: "No token provided" });
        }

        const token = authHeader.split(" ")[1];

        const decoded = verifyToken(token);

        req.user = decoded;

        next();
    } catch (error) {
        return res.status(401).json({ success: false, message: "Unauthorized" });
    }
};