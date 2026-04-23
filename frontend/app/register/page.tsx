"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";

export default function RegisterPage() {
    const router = useRouter();

    const [form, setForm] = useState({
        name: "",
        email: "",
        password: "",
        role: "CANDIDATE",
    });

    const [message, setMessage] = useState("");
    const [loading, setLoading] = useState(false);

    const handleChange = (
        e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>
    ) => {
        setForm({
            ...form,
            [e.target.name]: e.target.value,
        });
    };

    const handleRegister = async (e: React.FormEvent) => {
        e.preventDefault();

        try {
            setLoading(true);
            setMessage("");

            const res = await fetch("http://localhost:5000/api/auth/register", {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                },
                body: JSON.stringify(form),
            });

            const data = await res.json();

            if (data.success) {
                setMessage("Registration successful. Please log in.");
                router.push("/login");
            } else {
                setMessage(data.message || "Registration failed.");
            }
        } catch (error) {
            setMessage("Something went wrong.");
        } finally {
            setLoading(false);
        }
    };

    return (
        <main className="p-6 max-w-md mx-auto">
            <div className="border rounded-lg p-6 shadow-sm">
                <h1 className="text-2xl font-bold mb-4">Register</h1>

                <form onSubmit={handleRegister} className="space-y-4">
                    <div>
                        <label className="block mb-1 font-medium">Name</label>
                        <input
                            name="name"
                            value={form.name}
                            onChange={handleChange}
                            className="w-full border rounded px-3 py-2"
                            placeholder="Enter your name"
                            required
                        />
                    </div>

                    <div>
                        <label className="block mb-1 font-medium">Email</label>
                        <input
                            name="email"
                            type="email"
                            value={form.email}
                            onChange={handleChange}
                            className="w-full border rounded px-3 py-2"
                            placeholder="Enter your email"
                            required
                        />
                    </div>

                    <div>
                        <label className="block mb-1 font-medium">Password</label>
                        <input
                            name="password"
                            type="password"
                            value={form.password}
                            onChange={handleChange}
                            className="w-full border rounded px-3 py-2"
                            placeholder="Enter your password"
                            required
                        />
                    </div>

                    <div>
                        <label className="block mb-1 font-medium">Role</label>
                        <select
                            name="role"
                            value={form.role}
                            onChange={handleChange}
                            className="w-full border rounded px-3 py-2"
                        >
                            <option value="CANDIDATE">Candidate</option>
                            <option value="EMPLOYER">Employer</option>
                        </select>
                    </div>

                    <button
                        type="submit"
                        disabled={loading}
                        className="w-full bg-black text-white py-2 rounded disabled:opacity-50"
                    >
                        {loading ? "Registering..." : "Register"}
                    </button>
                </form>

                {message && <p className="mt-4 text-sm">{message}</p>}
            </div>
        </main>
    );
}