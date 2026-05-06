"use client";

import { useEffect, useState } from "react";

type Pupil = {
  id: string;
  name: string;
  class_id?: string;
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

type Props = {
  classId: string;
  pupils: Pupil[];
  subjects: Subject[];
  marks: Mark[];
};

const scoreToDots = (score: number) => {
  if (score >= 90) return 5;
  if (score >= 75) return 4;
  if (score >= 60) return 3;
  if (score >= 45) return 2;
  if (score >= 25) return 1;
  return 0;
};

const dotLabel = (filled: number) => {
  const labels = ["Beginning", "Developing", "Approaching", "Meeting", "Exceeding"];
  return labels[Math.min(filled, 4)] || "Beginning";
};

const renderDots = (filled: number, colors: Record<number, string>) => {
  let dots = [];
  for (let i = 0; i < 5; i++) {
    const color = colors[i + 1] || "#1a6b3c";
    dots.push(
      <span key={i} style={{
        display: "inline-block",
        width: 16,
        height: 16,
        borderRadius: "50%",
        border: `2px solid ${color}`,
        background: i < filled ? color : "transparent",
        boxSizing: "border-box" as const,
      }} />
    );
  }
  return dots;
};

const scoreColor = (score: number) => {
  if (score >= 80) return "#0a4f24";
  if (score >= 60) return "#0a3a6b";
  if (score >= 40) return "#7a5300";
  return "#c0392b";
};

const scoreLabel = (score: number) => {
  if (score >= 80) return "Excellent";
  if (score >= 60) return "Good";
  if (score >= 40) return "Average";
  return "Needs Improvement";
};

const gradeStyle = (grade: string) => {
  if (grade.startsWith("D")) return "background:#d1f0dc;color:#0a4f24";
  if (grade.startsWith("C")) return "background:#d0e8ff;color:#0a3a6b";
  if (grade.startsWith("P")) return "background:#fff3cd;color:#7a5300";
  return "background:#fde0e0;color:#7a1111";
};

const SHARED_REPORT_CSS = `
  body{font-family:Georgia,serif;max-width:720px;margin:40px auto;color:#1a1a1a;padding:0 24px}
  @media print{.noprint{display:none}}
  h1{font-size:24px;text-align:center;color:#1a6b3c;margin-bottom:3px}
  .sub{text-align:center;font-size:12px;color:#777;margin-bottom:22px}
  .meta{display:grid;grid-template-columns:repeat(3,1fr);gap:10px;padding:14px;background:#f0f8f4;border-radius:8px;margin-bottom:20px}
  .meta div{font-size:13px}.meta strong{display:block;font-size:18px;font-weight:700;color:#1a6b3c}.meta span{font-size:11px;color:#777;text-transform:uppercase;letter-spacing:.04em}
  footer{margin-top:24px;padding-top:12px;border-top:1px solid #e0e0e0;font-size:11px;color:#aaa;text-align:center}
  table{width:100%;border-collapse:collapse;font-size:13px}
  th{background:#1a6b3c;color:#fff;padding:9px 12px;text-align:left;font-weight:500}
  td{padding:8px 12px;border-bottom:1px solid #eee}
  tr:nth-child(even)td{background:#f9f9f9}
  .dot{display:inline-block;width:18px;height:18px;border-radius:50%;border:2px solid #1a6b3c;box-sizing:border-box}
  .dot-filled{background:#1a6b3c}
  .dot-empty{background:transparent}
  .scale-key{display:flex;gap:16px;align-items:center;flex-wrap:wrap;padding:12px 14px;background:#f0f8f4;border-radius:8px;margin-bottom:20px;font-size:12px;color:#555}
  .scale-key .k_item{display:flex;align-items:center;gap:6px}
`;

export default function MarksEntryClient({
  classId,
  pupils,
  subjects,
  marks,
}: Props) {
  const keySeparator = "::";
  const [pending, setPending] = useState<Record<string, number>>({});
  const [pendingComments, setPendingComments] = useState<Record<string, string>>({});
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState<string | null>(null);
  const [pupilList, setPupilList] = useState<Pupil[]>(pupils);
  const [newPupilName, setNewPupilName] = useState("");
  const [markMap, setMarkMap] = useState<Map<string, number>>(new Map());
  const [showToast, setShowToast] = useState(false);
  const [showColorSettings, setShowColorSettings] = useState(false);
  const [levelColors, setLevelColors] = useState<Record<number, string>>({
    1: "#1a6b3c",
    2: "#1a6b3c",
    3: "#1a6b3c",
    4: "#1a6b3c",
    5: "#1a6b3c",
  });
  const [selectedPupil, setSelectedPupil] = useState<Pupil | null>(null);
  const [showPupilModal, setShowPupilModal] = useState(false);

  const openPupilModal = (pupil: Pupil) => {
    setSelectedPupil(pupil);
    setShowPupilModal(true);
  };

  const closePupilModal = () => {
    setShowPupilModal(false);
    setSelectedPupil(null);
  };

  useEffect(() => {
    setPupilList(pupils);
  }, [pupils]);

  useEffect(() => {
    const map = new Map<string, number>();
    marks.forEach((mark) => {
      map.set(`${mark.pupil_id}${keySeparator}${mark.subject_id}`, mark.score);
    });
    setMarkMap(map);
  }, [keySeparator, marks]);

  const scoreFor = (pupilId: string, subjectId: string) => {
    const key = `${pupilId}${keySeparator}${subjectId}`;
    const value = pending[key] ?? markMap.get(key);
    return typeof value === "number" ? value : 0;
  };

  const subjectCount = subjects.length || 1;
  const isNursery = classId.toLowerCase().startsWith("kg") || pupils.some(p => p.class_id?.toLowerCase().startsWith("kg"));

  const rows = pupilList.map((pupil) => {
    const total = subjects.reduce(
      (sum, subject) => sum + scoreFor(pupil.id, subject.id),
      0
    );
    return { pupilId: pupil.id, total, average: total / subjectCount };
  });
  const sortedRows = [...rows].sort((a, b) => b.average - a.average);
  const positionMap = new Map<string, number>();
  let rank = 1;
  sortedRows.forEach((row, index) => {
    if (index > 0 && row.average < sortedRows[index - 1].average) {
      rank = index + 1;
    }
    positionMap.set(row.pupilId, rank);
  });
  const averages = new Map<string, { total: number; average: number; position: number }>();
  rows.forEach((row) => {
    averages.set(row.pupilId, {
      total: row.total,
      average: row.average,
      position: positionMap.get(row.pupilId) ?? 0,
    });
  });

  const handleChange = (key: string, value: string) => {
    if (value === "") {
      setPending((prev) => {
        const next = { ...prev };
        delete next[key];
        return next;
      });
      return;
    }

    const score = Number(value);
    if (Number.isNaN(score)) return;
    setPending((prev) => ({ ...prev, [key]: score }));
  };

  const handleCommentChange = (key: string, value: string) => {
    setPendingComments((prev) => ({ ...prev, [key]: value }));
  };

  const getComment = (key: string) => {
    return pendingComments[key] ?? "";
  };

  const handleSave = async () => {
    setSaving(true);
    setMessage(null);

    const updates = Object.entries(pending).map(([key, score]) => {
      const [pupil_id, subject_id] = key.split(keySeparator);
      return { pupil_id, subject_id, score, teacher_comment: pendingComments[key] || null };
    });

    if (updates.length === 0) {
      setMessage("No changes to save.");
      setSaving(false);
      return;
    }

    const response = await fetch("/api/teacher/marks", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ marks: updates }),
    });

    const payload = await response.json();

    if (!response.ok) {
      setMessage(payload.error ?? "Failed to save marks.");
      setSaving(false);
      return;
    }

    setMarkMap((prev) => {
      const next = new Map(prev);
      updates.forEach((update) => {
        next.set(
          `${update.pupil_id}${keySeparator}${update.subject_id}`,
          update.score
        );
      });
      return next;
    });
    setMessage("Marks saved successfully.");
    setPending({});
    setPendingComments({});
    setSaving(false);
    setShowToast(true);
    setTimeout(() => setShowToast(false), 2200);
  };

  const handleAddPupil = async (event: React.FormEvent) => {
    event.preventDefault();
    const trimmed = newPupilName.trim();
    if (!trimmed) {
      setMessage("Enter a pupil name to add.");
      return;
    }
    const response = await fetch("/api/teacher/pupils", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ name: trimmed }),
    });

    const payload = await response.json();

    if (!response.ok) {
      setMessage(payload.error ?? "Failed to add pupil.");
      return;
    }

    setPupilList((prev) => [...prev, payload.pupil]);
    setNewPupilName("");
  };

  const printReport = (pupil: Pupil, avg: { total: number; average: number; position: number } | undefined) => {
    const w = window.open("", "_blank");

    if (isNursery) {
      const rows = subjects.map((s) => {
        const score = scoreFor(pupil.id, s.id);
        const filled = scoreToDots(score);
        return `<tr>
          <td style="padding:9px 12px;border-bottom:1px solid #eee;font-size:13px">${s.name}</td>
          <td style="padding:9px 12px;border-bottom:1px solid #eee;text-align:center">
            <div style="display:flex;gap:6px;justify-content:center;align-items:center">
              ${[0,1,2,3,4].map(i => `<span class="dot ${i < filled ? 'dot-filled' : 'dot-empty'}"></span>`).join('')}
            </div>
          </td>
          <td style="padding:9px 12px;border-bottom:1px solid #eee;font-size:12px;color:#555">${dotLabel(filled)}</td>
          <td style="padding:9px 12px;border-bottom:1px solid #eee;text-align:center;font-size:13px;font-weight:700;color:#1a6b3c">${score}</td>
        </tr>`;
      }).join('');

      w?.document.write(`<!DOCTYPE html><html><head><title>Nursery Report — ${pupil.name}</title>
      <style>${SHARED_REPORT_CSS}
      .scale-key{display:flex;gap:14px;align-items:center;flex-wrap:wrap;padding:10px 12px;background:#f0f8f4;border-radius:8px;margin-bottom:14px;font-size:11px;color:#555}
      .scale-key strong{color:#1a6b3c;font-size:10px;text-transform:uppercase;letter-spacing:.05em;margin-right:4px}
      </style></head><body>
      <button class="noprint" onclick="window.print()" style="display:block;margin:0 auto 20px;padding:9px 24px;background:#1a6b3c;color:#fff;border:none;border-radius:8px;cursor:pointer;font-size:13px;font-weight:700">Print / Save as PDF</button>
      <h1>Hill View Primary School</h1>
      <div class="sub">Academic Report Card &nbsp;|&nbsp; Term 2, 2025</div>
      <div class="meta">
        <div><span>Pupil</span><strong>${pupil.name}</strong></div>
        <div><span>Class</span><strong>${classId}</strong></div>
        <div><span>Level</span><strong>Nursery</strong></div>
      </div>
      <div class="scale-key">
        <strong>Scale:</strong>
        ${[1,2,3,4,5].map(n => `<span class="k_item">${[0,1,2,3,4].map(i => `<span class="dot ${i < n ? 'dot-filled' : 'dot-empty'}"></span>`).join('')}<span>${n} — ${dotLabel(n)}</span>`).join('')}
      </div>
      <table><thead><tr>
        <th>Learning Area</th>
        <th style="text-align:center">Achievement</th>
        <th>Level</th>
        <th style="text-align:center">Score</th>
      </tr></thead>
      <tbody>${rows}</tbody></table>
      <footer>Generated by Hill View School Report Management System</footer>
      </body></html>`);
    } else {
      const reportRows = subjects.map(s => {
        const score = scoreFor(pupil.id, s.id);
        return `<tr><td>${s.name}</td><td style="text-align:center;font-weight:700;color:${scoreColor(score)}">${score}</td><td style="text-align:center;color:#999">100</td><td style="color:${scoreColor(score)}">${scoreLabel(score)}</td></tr>`;
      }).join('');

      w?.document.write(`<!DOCTYPE html><html><head><title>Report — ${pupil.name}</title>
      <style>${SHARED_REPORT_CSS}
      .ple{margin-top:20px;padding:14px;background:#f0f8f4;border-radius:8px}
      .ple h3{font-size:13px;font-weight:700;color:#1a6b3c;margin-bottom:10px}
      .grade-chip{display:inline-block;padding:5px 18px;border-radius:20px;font-size:17px;font-weight:700}
      </style></head><body>
      <button class="noprint" onclick="window.print()" style="display:block;margin:0 auto 20px;padding:9px 24px;background:#1a6b3c;color:#fff;border:none;border-radius:8px;cursor:pointer;font-size:13px;font-weight:700">Print / Save as PDF</button>
      <h1>Hill View Primary School</h1>
      <div class="sub">Academic Report Card &nbsp;|&nbsp; Term 2, 2025</div>
      <div class="meta">
        <div><span>Pupil</span><strong>${pupil.name}</strong></div>
        <div><span>Class</span><strong>${classId}</strong></div>
        <div><span>Position</span><strong>#${avg?.position ?? '-'}</strong></div>
      </div>
      <table><thead><tr><th>Subject</th><th style="text-align:center">Score</th><th style="text-align:center">/ 100</th><th>Remarks</th></tr></thead>
      <tbody>${reportRows}</tbody></table>
      <div class="meta" style="margin-top:16px">
        <div><span>Total Score</span><strong>${avg?.total ?? 0}</strong></div>
        <div><span>Average</span><strong>${(avg?.average ?? 0).toFixed(1)}%</strong></div>
        <div><span>Position</span><strong>#${avg?.position ?? '-'}</strong></div>
      </div>
      <footer>Generated by Hill View School Report Management System</footer>
      </body></html>`);
    }
    w?.document.close();
  };

  return (
    <div>
      <div className="marks-actions">
        <button className="btn btn-primary" onClick={handleSave} disabled={saving}>
          {saving ? <span className="spin"></span> : "Save Marks"}
        </button>
        {isNursery && (
          <button className="btn btn-ghost btn-sm" onClick={() => setShowColorSettings(!showColorSettings)}>
            {showColorSettings ? "Hide Colors" : "Level Colors"}
          </button>
        )}
        {message && !showToast && (
          <span className={message.includes("success") ? "msg-ok" : "msg-err"}>
            {message}
          </span>
        )}
      </div>
      {showColorSettings && isNursery && (
        <div className="color-settings">
          <h4>Nursery Level Colors</h4>
          <div className="color-grid">
            {([1, 2, 3, 4, 5] as const).map((level) => (
              <div key={level} className="color-item">
                <label>Level {level}:</label>
                <input
                  type="color"
                  value={levelColors[level]}
                  onChange={(e) => setLevelColors((prev) => ({ ...prev, [level]: e.target.value }))}
                />
              </div>
            ))}
          </div>
          <div className="color-preview">
            {renderDots(3, levelColors)}
          </div>
        </div>
      )}
      {pupilList.length === 0 || subjects.length === 0 ? (
        <div className="empty">
          No pupils or subjects found for this class.
        </div>
      ) : null}
      <div className="excel-wrap">
        <table className="excel-tbl">
          <thead>
            <tr>
              <th className="name-col">Pupil Name</th>
              {subjects.map((subject) => (
                <th key={subject.id} style={{ textAlign: "center" }}>
                  {subject.name.length > 13 ? subject.name.slice(0, 11) + "…" : subject.name}
                </th>
              ))}
              {subjects.map((subject) => (
                <th key={`cmt-${subject.id}`} style={{ textAlign: "center", minWidth: "100px" }}>
                  Cmt
                </th>
              ))}
              <th style={{ background: "#d8ead8" }}>Total</th>
              <th style={{ background: "#d8ead8" }}>Avg</th>
              <th style={{ background: "#d8ead8" }}>Pos</th>
              <th style={{ background: "#d8ead8" }}>Report</th>
            </tr>
          </thead>
          <tbody>
            {pupilList.map((pupil, rowIdx) => {
              const avg = averages.get(pupil.id);
              const isGood = avg && avg.average >= 60;
              return (
                <tr key={pupil.id}>
                  <td className="name-col">
                    <div style={{ display: "flex", alignItems: "center", gap: "6px" }}>
                      <span style={{ fontSize: "10px", color: "var(--muted)", minWidth: "16px", textAlign: "right" }}>
                        {rowIdx + 1}
                      </span>
                      <button
                        onClick={() => openPupilModal(pupil)}
                        style={{ background: "none", border: "none", color: "var(--primary)", cursor: "pointer", textAlign: "left", padding: 0, fontSize: "inherit", textDecoration: "underline" }}
                      >
                        {pupil.name}
                      </button>
                    </div>
                  </td>
                  {subjects.map((subject) => {
                    const key = `${pupil.id}${keySeparator}${subject.id}`;
                    const value = pending[key] ?? markMap.get(key) ?? 0;
                    const isPending = pending[key] !== undefined;
                    const comment = getComment(key);
                    return (
                      <td key={`score-${subject.id}`} className="input-cell">
                        <input
                          type="number"
                          min={0}
                          max={100}
                          step={1}
                          value={value}
                          onChange={(event) => handleChange(key, event.target.value)}
                          className={`xcel-inp ${isPending ? "changed" : ""}`}
                          title={`${pupil.name} — ${subject.name}`}
                        />
                      </td>
                    );
                  })}
                  {subjects.map((subject) => {
                    const key = `${pupil.id}${keySeparator}${subject.id}`;
                    const comment = getComment(key);
                    return (
                      <td key={`cmt-${subject.id}`} className="input-cell">
                        <input
                          type="text"
                          placeholder="Cmt"
                          value={comment}
                          onChange={(event) => handleCommentChange(key, event.target.value)}
                          className="xcel-inp comment-inp"
                          title={`Comment for ${subject.name}`}
                        />
                      </td>
                    );
                  })}
                  <td className="stat-col">
                    <span style={{ fontSize: "13px", fontWeight: 700, color: isGood ? "var(--g)" : "var(--danger)" }}>
                      {avg?.total ?? 0}
                    </span>
                  </td>
                  <td className="stat-col">
                    <strong style={{ color: isGood ? "var(--g)" : "var(--danger)" }}>
                      {avg?.average.toFixed(1) ?? "0.0"}
                    </strong>
                  </td>
                  <td className="stat-col">
                    <span className={`pb ${avg?.position === 1 ? "pb-1" : avg?.position && avg.position <= 3 ? "pb-2" : "pb-n"}`}>
                      #{avg?.position ?? "-"}
                    </span>
                  </td>
                  <td className="act-col">
                    <button
                      className="btn btn-ghost btn-sm"
                      onClick={() => printReport(pupil, avg)}
                    >
                      PDF
                    </button>
                  </td>
                </tr>
              );
            })}
            <tr>
              <td colSpan={subjects.length * 2 + 5} className="add-pupil-panel">
                <span style={{ fontSize: "18px", flexShrink: 0 }}>＋</span>
                <input
                  type="text"
                  placeholder="New pupil full name…"
                  value={newPupilName}
                  onChange={(event) => setNewPupilName(event.target.value)}
                  style={{ flex: 1, maxWidth: "280px" }}
                />
                <button className="btn btn-primary btn-sm" onClick={handleAddPupil}>
                  Add Pupil
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      <div className={`save-toast ${showToast ? "show" : ""}`}>
        ✓ Marks saved
      </div>

      {/* Pupil Details Modal */}
      {showPupilModal && selectedPupil && (
        <div style={{
          position: "fixed",
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          background: "rgba(0,0,0,0.5)",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          zIndex: 1000,
        }} onClick={closePupilModal}>
          <div style={{
            background: "#fff",
            borderRadius: "12px",
            padding: "24px",
            maxWidth: "420px",
            width: "90%",
            boxShadow: "0 8px 32px rgba(0,0,0,0.2)",
          }} onClick={(e) => e.stopPropagation()}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "16px" }}>
              <h3 style={{ margin: 0, color: "#1a6b3c" }}>Pupil Details</h3>
              <button onClick={closePupilModal} style={{ background: "none", border: "none", fontSize: "20px", cursor: "pointer", color: "#666" }}>×</button>
            </div>
            <div style={{ display: "flex", gap: "16px", marginBottom: "16px" }}>
              <div style={{ width: "80px", height: "96px", border: "2px solid #ccc", background: "#f0f0f0", display: "flex", alignItems: "center", justifyContent: "center", borderRadius: "6px", overflow: "hidden", flexShrink: 0 }}>
                {selectedPupil.avatar ? (
                  <img src={selectedPupil.avatar} alt={selectedPupil.name} style={{ width: "100%", height: "100%", objectFit: "cover" }} />
                ) : (
                  <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="#bbb" strokeWidth="1.2">
                    <circle cx="12" cy="8" r="4" />
                    <path d="M4 20c0-4 3.6-7 8-7s8 3 8 7" />
                  </svg>
                )}
              </div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: "18px", fontWeight: 700, color: "#1a6b3c", marginBottom: "8px" }}>{selectedPupil.name}</div>
                <div style={{ fontSize: "13px", color: "#555", marginBottom: "4px" }}><strong>House:</strong> {selectedPupil.house || "—"}</div>
                <div style={{ fontSize: "13px", color: "#555", marginBottom: "4px" }}><strong>School Pay Code:</strong> {selectedPupil.paycode || "—"}</div>
                <div style={{ fontSize: "13px", color: "#555" }}><strong>Class:</strong> {classId}</div>
              </div>
            </div>
            <button className="btn btn-primary" onClick={closePupilModal} style={{ width: "100%" }}>Close</button>
          </div>
        </div>
      )}
    </div>
  );
}