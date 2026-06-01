import { Response } from "express";
import { AuthRequest } from "../../middleware/auth.middleware";
import prisma from "../../lib/prisma";

export const getNotifications = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user?.id;
    if (!userId) {
      res.status(401).json({ success: false, message: "Unauthorized" });
      return;
    }

    const notifications = await prisma.notification.findMany({
      where: { userId },
      orderBy: { createdAt: "desc" },
    });

    res.json({ success: true, data: notifications });
  } catch (error) {
    console.error("Error fetching notifications:", error);
    res.status(500).json({ success: false, message: "Failed to fetch notifications" });
  }
};

export const markAsRead = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user?.id;
    const { id } = req.params;
    
    if (!userId) {
      res.status(401).json({ success: false, message: "Unauthorized" });
      return;
    }

    const notification = await prisma.notification.updateMany({
      where: { id, userId },
      data: { read: true },
    });

    res.json({ success: true, message: "Notification marked as read" });
  } catch (error) {
    console.error("Error updating notification:", error);
    res.status(500).json({ success: false, message: "Failed to update notification" });
  }
};

export const createDemoNotifications = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const userId = req.user?.id;
        if (!userId) {
            res.status(401).json({ success: false, message: "Unauthorized" });
            return;
        }

        const count = await prisma.notification.count({ where: { userId } });
        if (count > 0) {
             res.json({ success: true, message: "Notifications already exist" });
             return;
        }

        await prisma.notification.createMany({
            data: [
                {
                    userId,
                    title: "New Job Alert",
                    message: "5 new jobs match your \"Senior Product Designer\" alert in Kathmandu.",
                    type: "JOB_ALERT",
                    actionUrl: "/jobs",
                    createdAt: new Date(Date.now() - 2 * 60 * 60 * 1000) // 2 hours ago
                },
                {
                    userId,
                    title: "Application Viewed",
                    message: "TechCorp Inc. has viewed your application for Lead UX Researcher.",
                    type: "APPLICATION_VIEWED",
                    createdAt: new Date(Date.now() - 5 * 60 * 60 * 1000) // 5 hours ago
                },
                {
                    userId,
                    title: "Interview Scheduled",
                    message: "Your interview with Innovate Nepal is scheduled for Tomorrow at 10:00 AM.",
                    type: "INTERVIEW_SCHEDULED",
                    actionUrl: "/meetings/join",
                    createdAt: new Date(Date.now() - 24 * 60 * 60 * 1000) // 1 day ago
                },
                {
                    userId,
                    title: "Profile Optimization",
                    message: "Adding your portfolio link can increase profile views by 30%.",
                    type: "PROFILE_OPTIMIZATION",
                    actionUrl: "/profile/edit",
                    createdAt: new Date(Date.now() - 48 * 60 * 60 * 1000) // 2 days ago
                }
            ]
        });

        res.json({ success: true, message: "Demo notifications created" });
    } catch(error) {
        console.error("Error creating demo notifications:", error);
        res.status(500).json({ success: false, message: "Failed to create demo notifications" });
    }
};
