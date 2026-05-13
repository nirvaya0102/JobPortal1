import dotenv from "dotenv";
import app from "./app";
import authRoutes from "./modules/auth/auth.routes";
import { errorMiddleware } from "./middleware/error.middleware";

import cookieParser from "cookie-parser";


dotenv.config();
app.use(cookieParser());
const PORT = process.env.PORT || 5000;

// authRoutes is already mounted in app.ts
app.use(errorMiddleware);

app.listen(Number(PORT), "0.0.0.0", () => {
    console.log(`Server running on port ${PORT}`);
});