import { Request, Response, NextFunction } from "express";

export const requireRole = (role: string) => {
    return (req: any, res: Response, next: NextFunction) => {
        if (req.user.role !== role) {
            return res.status(403).json({
                success: false,
                message: `Access denied: ${role.toLowerCase()} role required`,
            });
        }
        next();
    };
};

export const employerOnly = (req, res, next) => {
  if (req.user.role !== "EMPLOYER") {
    return res.status(403).json({
      message: "Only employers can access this route",
    });
  }

  next();
};