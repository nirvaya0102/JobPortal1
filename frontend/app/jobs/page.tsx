"use client";

import { useEffect, useState } from "react";
import Link from "next/link";

type Job = {
    id: string;
    jobCode?: string;
    title: string;
    location: string;
    jobType: string;
    salaryMin?: number;
    salaryMax?: number;
    company?: {
        name: string;
    };
};

export default function JobsPage() {
    const [jobs, setJobs] = useState<Job[]>([]);
    const [loading, setLoading] = useState(false);
    const [message, setMessage] = useState("");

    const [filters, setFilters] = useState({
        keyword: "",
        location: "",
        jobType: "",
    });

    const fetchJobs = async () => {
        try {
            setLoading(true);
            setMessage("");

            const params = new URLSearchParams();

            if (filters.keyword.trim()) {
                params.append("keyword", filters.keyword.trim());
            }

            if (filters.location.trim()) {
                params.append("location", filters.location.trim());
            }

            if (filters.jobType.trim()) {
                params.append("jobType", filters.jobType.trim());
            }

            const url = `http://localhost:5000/api/jobs${params.toString() ? `?${params.toString()}` : ""
                }`;

            const res = await fetch(url, {
                cache: "no-store",
            });

            const data = await res.json();

            if (data.success) {
                setJobs(data.jobs || []);
            } else {
                setMessage(data.message || "Failed to load jobs.");
                setJobs([]);
            }
        } catch (error) {
            setMessage("Something went wrong while loading jobs.");
            setJobs([]);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchJobs();
    }, []);

    const handleChange = (
        e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>
    ) => {
        setFilters({
            ...filters,
            [e.target.name]: e.target.value,
        });
    };

    const handleSearch = async (e: React.FormEvent) => {
        e.preventDefault();
        fetchJobs();
    };

    const handleReset = async () => {
        setFilters({
            keyword: "",
            location: "",
            jobType: "",
        });

        try {
            setLoading(true);
            setMessage("");

            const res = await fetch("http://localhost:5000/api/jobs", {
                cache: "no-store",
            });

            const data = await res.json();

            if (data.success) {
                setJobs(data.jobs || []);
            } else {
                setMessage(data.message || "Failed to load jobs.");
                setJobs([]);
            }
        } catch (error) {
            setMessage("Something went wrong while loading jobs.");
            setJobs([]);
        } finally {
            setLoading(false);
        }
    };

    return (
        <main className="max-w-5xl mx-auto p-6">
            <h1 className="text-3xl font-bold mb-6">Job Listings</h1>

            <form
                onSubmit={handleSearch}
                className="border rounded-xl p-4 mb-6 grid gap-4 md:grid-cols-4"
            >
                <input
                    type="text"
                    name="keyword"
                    value={filters.keyword}
                    onChange={handleChange}
                    placeholder="Search by keyword"
                    className="border rounded px-3 py-2"
                />

                <input
                    type="text"
                    name="location"
                    value={filters.location}
                    onChange={handleChange}
                    placeholder="Filter by location"
                    className="border rounded px-3 py-2"
                />

                <select
                    name="jobType"
                    value={filters.jobType}
                    onChange={handleChange}
                    className="border rounded px-3 py-2"
                >
                    <option value="">All job types</option>
                    <option value="Full-time">Full-time</option>
                    <option value="Part-time">Part-time</option>
                    <option value="Remote">Remote</option>
                </select>

                <div className="flex gap-2">
                    <button
                        type="submit"
                        className="bg-black text-white px-4 py-2 rounded w-full"
                    >
                        Search
                    </button>

                    <button
                        type="button"
                        onClick={handleReset}
                        className="border px-4 py-2 rounded w-full"
                    >
                        Reset
                    </button>
                </div>
            </form>

            {loading && <p>Loading jobs...</p>}
            {!loading && message && <p>{message}</p>}

            {!loading && !message && jobs.length === 0 && (
                <div className="border rounded-xl p-6 text-center">
                    <p className="text-lg font-medium">No jobs found</p>
                    <p className="text-gray-600 mt-2">
                        Try changing your search or filters.
                    </p>
                </div>
            )}

            <div className="space-y-4">
                {jobs.map((job) => (
                    <div key={job.id} className="border rounded-xl p-4 shadow-sm">
                        <h2 className="text-xl font-semibold">{job.title}</h2>

                        {job.jobCode && (
                            <p className="text-sm text-gray-500 mt-1">{job.jobCode}</p>
                        )}

                        <p className="text-gray-700 mt-1">
                            {job.company?.name} • {job.location}
                        </p>

                        <p className="mt-1 text-sm text-gray-600">{job.jobType}</p>

                        <p className="mt-1 text-sm">
                            Salary: {job.salaryMin ?? "-"} - {job.salaryMax ?? "-"}
                        </p>

                        <Link
                            href={`/jobs/${job.id}`}
                            className="inline-block mt-3 text-blue-600"
                        >
                            View Details
                        </Link>
                    </div>
                ))}
            </div>
        </main>
    );
}