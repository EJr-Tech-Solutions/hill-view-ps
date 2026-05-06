"use client";

import { useEffect, useState, useCallback } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import MarksEntryClient from "./MarksEntryClient";

type AssignedClass = {
  id: string;
  name: string;
};

type Pupil = {
  id: string;
  name: string;
  avatar?: string | null;
  house?: string | null;
  paycode?: string | null;
};

type Subject = {
  id: string;
  name: string;
};

type Mark = {
  id: string;
  pupil_id: string;
  subject_id: string;
  score: number;
  teacher_comment?: string | null;
};

type DashboardPayload = {
  user: {
    id: string;
    email: string;
    name: string;
    classId: string | null;
  };
  classInfo: {
    id: string;
    name: string;
  } | null;
  assignedClasses: AssignedClass[];
  pupils: Pupil[];
  subjects: Subject[];
  marks: Mark[];
  performance: {
    class_name: string;
    average_score: number;
    best_pupil: string | null;
    weakest_pupil: string | null;
  } | null;
};

export default function TeacherDashboardClient() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const [data, setData] = useState<DashboardPayload | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [selectedClass, setSelectedClass] = useState<string>("");

  const loadDashboard = useCallback(
    async (classId?: string) => {
      setLoading(true);
      setError(null);

      const params = new URLSearchParams();
      if (classId) params.set("classId", classId);
      const url = `/api/teacher/dashboard${params.toString() ? "?" + params.toString() : ""}`;

      const response = await fetch(url, { cache: "no-store" });

      if (response.status === 401) {
        router.replace("/login");
        return;
      }

      if (response.status === 403) {
        router.replace("/admin");
        return;
      }

      const payload = await response.json();

      if (!response.ok) {
        setError(payload.error ?? "Failed to load teacher dashboard.");
        setLoading(false);
        return;
      }

      setData(payload);
      setSelectedClass(payload.user.classId ?? "");
      setLoading(false);
    },
    [router]
  );

  useEffect(() => {
    loadDashboard(searchParams?.get("classId") ?? undefined);
  }, [loadDashboard, searchParams]);

  const handleClassChange = (classId: string) => {
    setSelectedClass(classId);
    loadDashboard(classId);
  };

  if (loading) {
    return <div className="loader">Loading teacher dashboard...</div>;
  }

  if (error || !data) {
    return <div className="msg-err">{error ?? "Teacher dashboard is unavailable."}</div>;
  }

  return (
    <section>
      <div style={{ display: "flex", alignItems: "center", gap: "12px", marginBottom: "22px" }}>
        <h2 className="page-h" style={{ marginBottom: 0 }}>Marks Entry</h2>

        {data.assignedClasses.length > 1 && (
          <select
            value={selectedClass}
            onChange={(e) => handleClassChange(e.target.value)}
            style={{ width: "auto", padding: "8px 12px", fontSize: "13.5px" }}
          >
            {data.assignedClasses.map((c) => (
              <option key={c.id} value={c.id}>
                {c.name}
              </option>
            ))}
          </select>
        )}
      </div>

      <div className="mc-grid">
        <div className="mc">
          <div className="mc-val">{data.classInfo?.name ?? "–"}</div>
          <div className="mc-lbl">Class</div>
        </div>
        <div className="mc">
          <div className="mc-val">{data.pupils.length}</div>
          <div className="mc-lbl">Pupils</div>
        </div>
        <div className="mc">
          <div className="mc-val">{data.subjects.length}</div>
          <div className="mc-lbl">Subjects</div>
        </div>
        <div className="mc">
          <div
            className="mc-val"
            style={{
              color:
                data.performance?.average_score && data.performance.average_score >= 60
                  ? "var(--g)"
                  : "var(--danger)"
            }}
          >
            {data.performance?.average_score?.toFixed(1) ?? "–"}%
          </div>
          <div className="mc-lbl">Class Average</div>
        </div>
      </div>

      <MarksEntryClient
        classId={data.user.classId ?? ""}
        pupils={data.pupils}
        subjects={data.subjects}
        marks={data.marks}
      />
    </section>
  );
}
