import express from "express";
import cors from "cors";
import authRoutes from "./modules/auth/auth.routes";
import { authMiddleware } from "./middleware/auth.middleware";
import path from "path";
import { requireRole } from "./middleware/role.middleware";
import cookieParser from "cookie-parser";

import jobRoutes from "./modules/jobs/jobs.routes";
import notificationRoutes from "./modules/notifications/notification.routes";
const app = express();


app.get("/api/protected", authMiddleware, (req: any, res) => {
    res.json({
        success: true,
        message: "You are authorized",
        user: req.user,
    });
});
app.use(cookieParser());

app.use(
  cors({
    origin: ["http://localhost:3000", "http://localhost:5000"],
    credentials: true,
    allowedHeaders: ["Content-Type", "Authorization", "x-client-type"],
  })
);

app.use(express.json());
app.use("/uploads", express.static(path.join(process.cwd(), "uploads")));
app.get("/", (_req, res) => {
    res.send("API running");
});

app.use("/api/auth", authRoutes);

app.get(
    "/api/employer-only",
    authMiddleware,
    requireRole("EMPLOYER"),
    (req: any, res) => {
        res.json({
            success: true,
            message: "Employer access granted",
        });
    }
);

app.use("/api/jobs", jobRoutes);
app.use("/api/notifications", notificationRoutes);

export default app;