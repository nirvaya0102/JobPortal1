import { Request, Response } from "express";
import { loginUser, registerUser } from "./auth.service";

export const register = async (req: Request, res: Response) => {
    try {
        const user = await registerUser(req.body);
        res.status(201).json({ success: true, user });
    } catch (error: any) {
        res.status(400).json({ success: false, message: error.message });
    }
};

export const login = async (req: Request, res: Response) => {
    try {
        const result = await loginUser(req.body);
        res.status(200).json({ success: true, user: result.user, token: result.token });
    } catch (error: any) {
        res.status(400).json({ success: false, message: error.message });
    }
};

export const getMe = async (req: any, res: Response) => {
    res.json({
        success: true,
        user: req.user,
    });
};