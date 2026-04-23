import { Request, Response, NextFunction } from "express";

export const requireRole = (role: string) => {
    return (req: any, res: Response, next: NextFunction) => {
        if (req.user.role !== role) {
            return res.status(403).json({ success: false, message: "Forbidden" });
        }
        next();
    };
};