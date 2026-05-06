type SubjectMark = {
  subject_name: string;
  score: number;
  teacher_comment?: string | null;
};

type ReportSummary = {
  pupil_name: string;
  class_name: string;
  total_score: number;
  average_score: number;
  position: number | null;
  uneb_grade: string | null;
  teacher_remark?: string | null;
  house?: string | null;
  paycode?: string | null;
  term?: string;
  year?: string;
  req_fee?: string | null;
  next_fee?: string | null;
  balance?: string | null;
  development?: string | null;
  term_ended?: string | null;
  next_term?: string | null;
};

type Props = {
  summary: ReportSummary;
  subjects: SubjectMark[];
  progressive?: {
    bot: Record<string, number>;
    mid: Record<string, number>;
  } | null;
};

const reportGrade = (score: number) => {
  if (score >= 95) return "D1";
  if (score >= 80) return "D2";
  if (score >= 70) return "C3";
  if (score >= 65) return "C4";
  if (score >= 60) return "C5";
  if (score >= 50) return "C6";
  if (score >= 45) return "P7";
  if (score >= 35) return "P8";
  return "F9";
};

const gradeRemark = (grade: string) => {
  const remarks: Record<string, string> = {
    'D1': 'Distinction',
    'D2': 'Distinction',
    'C3': 'Credit',
    'C4': 'Credit',
    'C5': 'Credit',
    'C6': 'Credit',
    'P7': 'Pass',
    'P8': 'Pass',
    'F9': 'Fail'
  };
  return remarks[grade] || '';
};

const toAgg = (score: number) => {
  if (score >= 95) return 1;
  if (score >= 80) return 2;
  if (score >= 70) return 3;
  if (score >= 65) return 4;
  if (score >= 60) return 5;
  if (score >= 50) return 6;
  if (score >= 45) return 7;
  if (score >= 35) return 8;
  return 9;
};

const primarySubjects = [
  "English",
  "Mathematics",
  "Social Studies and RE",
  "Integrated Science",
  "Computer Studies",
  "Practical Work"
];

const nurserySkills = [
  "Toilet habits",
  "Singing",
  "Colours",
  "Writing",
  "Sharing",
  "Body hygiene",
  "Cleanliness",
  "Attendance",
  "Behaviour",
  "Counting"
];

const scoreToLevel = (score: number) => {
  if (score >= 90) return 5;
  if (score >= 75) return 4;
  if (score >= 60) return 3;
  if (score >= 45) return 2;
  if (score >= 25) return 1;
  return 0;
};

export default function ReportCard({ summary, subjects, progressive }: Props) {
  const isNursery = summary.class_name?.startsWith("KG");
  const term = summary.term || "Term 2";
  const year = summary.year || "2025";

  if (isNursery) {
    const subjectScores = new Map(subjects.map((s) => [s.subject_name, s.score]));

    return (
      <div style={{ width: "720px", background: "#fff", border: "2px solid #555", padding: "20px 24px 16px", fontFamily: "Arial, sans-serif", fontSize: "11.5px" }}>
        {/* Header */}
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", gap: "10px", marginBottom: "8px" }}>
          <div style={{ width: "80px", height: "80px", flexShrink: 0, display: "flex", alignItems: "center", justifyContent: "center" }}>
            <svg viewBox="0 0 200 200" width="80" height="80" xmlns="http://www.w3.org/2000/svg">
              <circle cx="100" cy="100" r="98" fill="#8B0000"/>
              <circle cx="100" cy="100" r="93" fill="none" stroke="#D4AF37" strokeWidth="2.5"/>
              <circle cx="100" cy="100" r="89" fill="none" stroke="#D4AF37" strokeWidth="0.8"/>
              <circle cx="100" cy="100" r="75" fill="#fff"/>
              <text fontSize="11" fontWeight="bold" fill="#fff" letterSpacing="0.8" fontFamily="Arial">
                <textPath href="#top" startOffset="50%" textAnchor="middle">HILL VIEW NUR. & PRIMARY SCHOOL</textPath>
              </text>
              <text fontSize="9.5" fontWeight="bold" fill="#8B0000" letterSpacing="1.2" fontFamily="Arial">
                <textPath href="#bot" startOffset="50%" textAnchor="middle">PLAN FOR TOMORROW</textPath>
              </text>
              <defs>
                <path id="top" d="M 14,100 A 86,86 0 0,1 186,100" fill="none"/>
                <path id="bot" d="M 28,132 A 78,78 0 0,0 172,132" fill="none"/>
              </defs>
            </svg>
          </div>
          <div style={{ flex: 1, textAlign: "center" }}>
            <div style={{ color: "#cc1010", fontWeight: 900, fontSize: "18px", letterSpacing: ".02em", textTransform: "uppercase", lineHeight: 1.1 }}>
              Hill View Nursery School – Nkoowe
            </div>
            <div style={{ fontSize: "10px", fontWeight: 700, color: "#111", marginTop: "3px", lineHeight: 1.7 }}>
              Location: 13 Miles Along Kampala – Hoima Road | P.O Box 76, Wakiso<br/>
              Tel: 0772/ 0701 692 329/ 0774 420 243 &nbsp;&nbsp; Email: hillviewschool1@gmail.com
            </div>
            <div style={{ fontWeight: 900, fontSize: "13px", letterSpacing: ".1em", textDecoration: "underline", textUnderlineOffset: "3px", marginTop: "4px" }}>
              Terminal Report
            </div>
          </div>
          <div style={{ width: "76px", height: "92px", border: "1.5px solid #777", background: "#e8e8e8", display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0 }}>
            {summary.paycode ? (
              <span style={{ fontSize: "10px", color: "#666" }}>{summary.paycode}</span>
            ) : (
              <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="#bbb" strokeWidth="1.2">
                <circle cx="12" cy="8" r="4"/><path d="M4 20c0-4 3.6-7 8-7s8 3 8 7"/>
              </svg>
            )}
          </div>
        </div>

        {/* Info Row */}
        <div style={{ display: "flex", flexWrap: "wrap", gap: "0 20px", fontSize: "11.5px", fontWeight: 700, borderTop: "2px solid #000", borderBottom: "2px solid #000", padding: "5px 0", margin: "7px 0 5px" }}>
          <div style={{ display: "flex", alignItems: "center", gap: "4px" }}><span>Learner's Name:</span> <span style={{ display: "inline-block", width: "120px", borderBottom: "1px solid #555", height: "14px" }}>{summary.pupil_name}</span></div>
          <div style={{ display: "flex", alignItems: "center", gap: "4px" }}><span>Term</span> <span style={{ display: "inline-block", width: "50px", borderBottom: "1px solid #555", height: "14px" }}>{term}</span></div>
          <div style={{ display: "flex", alignItems: "center", gap: "4px" }}><span>Year.</span> <span style={{ display: "inline-block", width: "50px", borderBottom: "1px solid #555", height: "14px" }}>{year}</span></div>
          <div style={{ display: "flex", alignItems: "center", gap: "4px" }}><span>Class</span> <span style={{ display: "inline-block", width: "90px", borderBottom: "1px solid #555", height: "14px" }}>{summary.class_name}</span></div>
          <div style={{ display: "flex", alignItems: "center", gap: "4px" }}><span>House.</span> <span style={{ display: "inline-block", width: "90px", borderBottom: "1px solid #555", height: "14px" }}>{summary.house || ""}</span></div>
          <div style={{ display: "flex", alignItems: "center", gap: "4px" }}><span>School Pay Code.</span> <span style={{ display: "inline-block", width: "50px", borderBottom: "1px solid #555", height: "14px" }}>{summary.paycode || ""}</span></div>
        </div>

        {/* Key */}
        <div style={{ display: "flex", gap: "18px", fontSize: "11.5px", fontWeight: 700, alignItems: "center", flexWrap: "wrap", margin: "6px 0 10px" }}>
          <b style={{ fontSize: "12px" }}>00 KEY</b>
          <span><span style={{ width: "16px", height: "16px", borderRadius: "50%", display: "inline-block", marginRight: "4px", verticalAlign: "middle", border: "1px solid rgba(0,0,0,.15)", background: "#f5c518" }}></span><b>Very Good</b></span>
          <span><span style={{ width: "16px", height: "16px", borderRadius: "50%", display: "inline-block", marginRight: "4px", verticalAlign: "middle", border: "1px solid rgba(0,0,0,.15)", background: "#dc3545" }}></span><b>Good</b></span>
          <span><span style={{ width: "16px", height: "16px", borderRadius: "50%", display: "inline-block", marginRight: "4px", verticalAlign: "middle", border: "1px solid rgba(0,0,0,.15)", background: "#198754" }}></span><b>Needs Improvement</b></span>
          <span><span style={{ width: "16px", height: "16px", borderRadius: "50%", display: "inline-block", marginRight: "4px", verticalAlign: "middle", border: "1px solid rgba(0,0,0,.15)", background: "#0d6efd" }}></span><b>Tries</b></span>
        </div>

        {/* Skills Grid */}
        <div style={{ display: "grid", gridTemplateColumns: "repeat(5,1fr)", borderTop: "1.5px solid #444", borderLeft: "1.5px solid #444" }}>
          {nurserySkills.map((skill) => {
            const score = subjectScores.get(skill) ?? 0;
            const level = scoreToLevel(score);
            const dotColor = level >= 5 ? "#f5c518" : level >= 4 ? "#dc3545" : level >= 2 ? "#198754" : "#0d6efd";
            return (
              <div key={skill} style={{ borderRight: "1.5px solid #444", borderBottom: "1.5px solid #444" }}>
                <div style={{ fontWeight: 900, fontSize: "9px", textAlign: "center", padding: "3px 2px", borderBottom: "1px solid #ccc", textTransform: "capitalize", lineHeight: 1.2, background: "#f7f7f7", letterSpacing: ".02em" }}>{skill}</div>
                <div style={{ position: "relative", height: "88px", display: "flex", alignItems: "center", justifyContent: "center", background: "#f0f0f0" }}>
                  <div style={{ width: "16px", height: "16px", borderRadius: "50%", position: "absolute", bottom: "5px", right: "5px", border: "1.5px solid rgba(0,0,0,.18)", background: dotColor }}></div>
                  <span style={{ fontSize: "11px", fontWeight: 700, color: "#555" }}>{level}/5</span>
                </div>
              </div>
            );
          })}
        </div>

        {/* Comments */}
        <div style={{ marginTop: "10px" }}>
          <div><span style={{ fontWeight: 900 }}>Class Teacher's Comment: </span><span style={{ display: "inline-block", width: "320px", borderBottom: "1px solid #666", height: "14px", verticalAlign: "bottom" }}>{summary.teacher_remark || ""}</span></div>
          <div style={{ borderBottom: "1px dotted #888", margin: "6px 0 5px" }}></div>
          <div style={{ display: "flex", justifyContent: "flex-end", fontSize: "10px", color: "#444" }}>SIGNATURE .....................................</div>
          <div style={{ margin: "6px 0 2px" }}><span style={{ fontWeight: 900 }}>Headteacher's Comment</span> <span style={{ display: "inline-block", width: "290px", borderBottom: "1px solid #666", height: "14px", verticalAlign: "bottom" }}></span></div>
          <div style={{ borderBottom: "1px dotted #888" }}></div>
          <div style={{ display: "flex", justifyContent: "flex-end", fontSize: "10px", color: "#444" }}>SIGNATURE .....................................</div>
        </div>

        {/* Fees */}
        <div style={{ display: "flex", flexWrap: "wrap", gap: "3px 24px", fontSize: "11px", fontWeight: 700, margin: "7px 0" }}>
          <span><b>Requirement Fee:</b> <span style={{ display: "inline-block", width: "80px", borderBottom: "1px solid #555", height: "13px", verticalAlign: "bottom" }}>{summary.req_fee || ""}</span></span>
          <span><b>Next Term's Fees:</b> <span style={{ display: "inline-block", width: "80px", borderBottom: "1px solid #555", height: "13px", verticalAlign: "bottom" }}>{summary.next_fee || ""}</span></span>
        </div>
        <div style={{ display: "flex", flexWrap: "wrap", gap: "3px 24px", fontSize: "11px", fontWeight: 700 }}>
          <span><b>School Fees Balance</b> <span style={{ display: "inline-block", width: "120px", borderBottom: "1px solid #555", height: "13px", verticalAlign: "bottom" }}>{summary.balance || ""}</span></span>
          <span><b>Development:</b> <span style={{ display: "inline-block", width: "120px", borderBottom: "1px solid #555", height: "13px", verticalAlign: "bottom" }}>{summary.development || ""}</span></span>
        </div>

        {/* Dates */}
        <div style={{ display: "flex", justifyContent: "space-between", fontSize: "11px", fontWeight: 900, margin: "6px 0" }}>
          <span>This Term Ended On: <span style={{ display: "inline-block", width: "80px", borderBottom: "1px solid #555", height: "13px", verticalAlign: "bottom" }}>{summary.term_ended || ""}</span></span>
          <span>Next Term Starts On: <span style={{ display: "inline-block", width: "80px", borderBottom: "1px solid #555", height: "13px", verticalAlign: "bottom" }}>{summary.next_term || ""}</span></span>
        </div>

        {/* Note */}
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-end", marginTop: "6px" }}>
          <div style={{ fontSize: "10px", fontWeight: 700 }}><b>Note</b><br/>This report is valid only when it bears school stamp</div>
          <div style={{ fontSize: "10px", fontWeight: 700, alignSelf: "flex-end" }}>School stamp</div>
          <div style={{ width: "64px", height: "64px", border: "2px dashed #aaa", borderRadius: "50%", display: "flex", alignItems: "center", justifyContent: "center", fontSize: "8.5px", color: "#aaa", fontWeight: 700, textAlign: "center" }}>School<br/>Stamp</div>
        </div>
        <div style={{ fontWeight: 900, fontSize: "13px", letterSpacing: ".08em", marginTop: "7px", borderTop: "2.5px solid #000", paddingTop: "6px", textAlign: "center" }}>Motto: ' Plan For Tomorrow</div>
      </div>
    );
  }

  // PRIMARY REPORT CARD
  const subjectScores = new Map(subjects.map((s) => [s.subject_name, s.score]));
  const commentMap = new Map(subjects.filter(s => s.teacher_comment).map(s => [s.subject_name, s.teacher_comment]));

  const total = subjects.reduce((sum, s) => sum + (s.score || 0), 0);
  const aggregate = primarySubjects.reduce((sum, subject) => {
    const score = subjectScores.get(subject) ?? 0;
    return sum + toAgg(score);
  }, 0);

  return (
    <div style={{ width: "720px", background: "#fff", border: "2px solid #555", padding: "20px 24px 16px", fontFamily: "Arial, sans-serif", fontSize: "11.5px" }}>
      {/* Header */}
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", gap: "10px", marginBottom: "8px" }}>
        <div style={{ width: "80px", height: "80px", flexShrink: 0, display: "flex", alignItems: "center", justifyContent: "center" }}>
          <svg viewBox="0 0 200 200" width="80" height="80" xmlns="http://www.w3.org/2000/svg">
            <circle cx="100" cy="100" r="98" fill="#8B0000"/>
            <circle cx="100" cy="100" r="93" fill="none" stroke="#D4AF37" strokeWidth="2.5"/>
            <circle cx="100" cy="100" r="89" fill="none" stroke="#D4AF37" strokeWidth="0.8"/>
            <circle cx="100" cy="100" r="75" fill="#fff"/>
            <text fontSize="11" fontWeight="bold" fill="#fff" letterSpacing="0.8" fontFamily="Arial">
              <textPath href="#top2" startOffset="50%" textAnchor="middle">HILL VIEW NUR. & PRIMARY SCHOOL</textPath>
            </text>
            <text fontSize="9.5" fontWeight="bold" fill="#8B0000" letterSpacing="1.2" fontFamily="Arial">
              <textPath href="#bot2" startOffset="50%" textAnchor="middle">PLAN FOR TOMORROW</textPath>
            </text>
            <defs>
              <path id="top2" d="M 14,100 A 86,86 0 0,1 186,100" fill="none"/>
              <path id="bot2" d="M 28,132 A 78,78 0 0,0 172,132" fill="none"/>
            </defs>
          </svg>
        </div>
        <div style={{ flex: 1, textAlign: "center" }}>
          <div style={{ color: "#cc1010", fontWeight: 900, fontSize: "21px", letterSpacing: ".02em", textTransform: "uppercase", lineHeight: 1.1 }}>
            Hill View Primary School – Nkoowe
          </div>
          <div style={{ fontSize: "10px", fontWeight: 700, color: "#111", marginTop: "3px", lineHeight: 1.7 }}>
            Location: 13 Miles Along Kampala – Hoima Road | P.O Box 76, Wakiso<br/>
            Tel: 0772/ 0701 692 329/ 0774 420 243 &nbsp;&nbsp; Email: hillviewschool1@gmail.com
          </div>
          <div style={{ fontWeight: 900, fontSize: "13px", letterSpacing: ".1em", textDecoration: "underline", textUnderlineOffset: "3px", marginTop: "4px" }}>
            Terminal Report
          </div>
        </div>
        <div style={{ width: "76px", height: "92px", border: "1.5px solid #777", background: "#e8e8e8", display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0 }}>
          {summary.paycode ? (
            <span style={{ fontSize: "10px", color: "#666" }}>{summary.paycode}</span>
          ) : (
            <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="#bbb" strokeWidth="1.2">
              <circle cx="12" cy="8" r="4"/><path d="M4 20c0-4 3.6-7 8-7s8 3 8 7"/>
            </svg>
          )}
        </div>
      </div>

      {/* Info Row */}
      <div style={{ display: "flex", flexWrap: "wrap", gap: "0 20px", fontSize: "11.5px", fontWeight: 700, borderTop: "2px solid #000", borderBottom: "2px solid #000", padding: "5px 0", margin: "7px 0 5px" }}>
        <div style={{ display: "flex", alignItems: "center", gap: "4px" }}><span>Learner's Name</span> <span style={{ display: "inline-block", width: "120px", borderBottom: "1px solid #555", height: "14px" }}>{summary.pupil_name}</span></div>
        <div style={{ display: "flex", alignItems: "center", gap: "4px" }}><span>Term</span> <span style={{ display: "inline-block", width: "50px", borderBottom: "1px solid #555", height: "14px" }}>{term}</span></div>
        <div style={{ display: "flex", alignItems: "center", gap: "4px" }}><span>Year.</span> <span style={{ display: "inline-block", width: "50px", borderBottom: "1px solid #555", height: "14px" }}>{year}</span></div>
        <div style={{ display: "flex", alignItems: "center", gap: "4px" }}><span>Class</span> <span style={{ display: "inline-block", width: "90px", borderBottom: "1px solid #555", height: "14px" }}>{summary.class_name}</span></div>
        <div style={{ display: "flex", alignItems: "center", gap: "4px" }}><span>House.</span> <span style={{ display: "inline-block", width: "90px", borderBottom: "1px solid #555", height: "14px" }}>{summary.house || ""}</span></div>
        <div style={{ display: "flex", alignItems: "center", gap: "4px" }}><span>School Pay Code.</span> <span style={{ display: "inline-block", width: "50px", borderBottom: "1px solid #555", height: "14px" }}>{summary.paycode || ""}</span></div>
      </div>

      {/* End of Term Performance */}
      <div style={{ textAlign: "center", fontWeight: 900, fontSize: "12px", textDecoration: "underline", margin: "7px 0 4px", textTransform: "uppercase", letterSpacing: ".07em" }}>End of Term Performance</div>

      <table style={{ width: "100%", borderCollapse: "collapse", fontSize: "11.5px" }}>
        <thead>
          <tr>
            <th style={{ width: "30%", textAlign: "left", paddingLeft: "8px", border: "1.5px solid #444", padding: "3px 6px", fontWeight: 900, fontSize: "10.5px", textTransform: "uppercase", background: "#fff" }}>Subject</th>
            <th style={{ border: "1.5px solid #444", padding: "3px 6px", fontWeight: 900, fontSize: "10.5px", textTransform: "uppercase", background: "#fff" }}>Full Marks</th>
            <th style={{ border: "1.5px solid #444", padding: "3px 6px", fontWeight: 900, fontSize: "10.5px", textTransform: "uppercase", background: "#fff" }}>Marks Scored</th>
            <th style={{ border: "1.5px solid #444", padding: "3px 6px", fontWeight: 900, fontSize: "10.5px", textTransform: "uppercase", background: "#fff" }}>Grade</th>
            <th style={{ border: "1.5px solid #444", padding: "3px 6px", fontWeight: 900, fontSize: "10.5px", textTransform: "uppercase", background: "#fff" }}>Remarks</th>
            <th style={{ border: "1.5px solid #444", padding: "3px 6px", fontWeight: 900, fontSize: "10.5px", textTransform: "uppercase", background: "#fff" }}>Initials</th>
          </tr>
        </thead>
        <tbody>
          {primarySubjects.map((subject) => {
            const score = subjectScores.get(subject) ?? 0;
            const grade = score > 0 ? reportGrade(score) : "";
            const remark = commentMap.get(subject) || (score > 0 ? gradeRemark(grade) : "");
            return (
              <tr key={subject}>
                <td style={{ textAlign: "left", fontWeight: 700, paddingLeft: "8px", border: "1.5px solid #444", padding: "3px 6px" }}>{subject}</td>
                <td style={{ textAlign: "center", border: "1.5px solid #444", padding: "3px 6px" }}>100</td>
                <td style={{ textAlign: "center", border: "1.5px solid #444", padding: "3px 6px" }}>{score > 0 ? score : ""}</td>
                <td style={{ textAlign: "center", border: "1.5px solid #444", padding: "3px 6px", fontWeight: 700 }}>{grade}</td>
                <td style={{ textAlign: "center", border: "1.5px solid #444", padding: "3px 6px", fontSize: "11px" }}>{remark}</td>
                <td style={{ textAlign: "center", border: "1.5px solid #444", padding: "3px 6px" }}></td>
              </tr>
            );
          })}
        </tbody>
      </table>

      {/* AGG and DIV */}
      <div style={{ display: "flex", justifyContent: "center", gap: "40px", fontWeight: 900, fontSize: "13px", margin: "6px 0", alignItems: "center" }}>
        <div style={{ display: "flex", alignItems: "center", gap: "6px" }}>AGG: <span style={{ display: "inline-block", width: "48px", borderBottom: "1px solid #555", height: "14px" }}>{aggregate}</span></div>
        <div style={{ display: "flex", alignItems: "center", gap: "6px" }}>DIV: <span style={{ display: "inline-block", width: "48px", borderBottom: "1px solid #555", height: "14px" }}>{summary.uneb_grade || ""}</span></div>
      </div>

      {/* Progressive Assessment Records */}
      <div style={{ textAlign: "center", fontWeight: 900, fontSize: "12px", textDecoration: "underline", margin: "7px 0 4px", textTransform: "uppercase", letterSpacing: ".07em" }}>Progressive Assessment Records</div>
      <table style={{ width: "100%", borderCollapse: "collapse", fontSize: "11.5px" }}>
        <thead>
          <tr>
            <th style={{ textAlign: "left", paddingLeft: "8px", border: "1.5px solid #444", padding: "3px 6px", fontWeight: 900, fontSize: "10.5px", textTransform: "uppercase", background: "#fff" }}>Subject</th>
            <th style={{ border: "1.5px solid #444", padding: "3px 6px", fontWeight: 900, fontSize: "10.5px", textTransform: "uppercase", background: "#fff" }}>ENG</th>
            <th style={{ border: "1.5px solid #444", padding: "3px 6px", fontWeight: 900, fontSize: "10.5px", textTransform: "uppercase", background: "#fff" }}>MTC</th>
            <th style={{ border: "1.5px solid #444", padding: "3px 6px", fontWeight: 900, fontSize: "10.5px", textTransform: "uppercase", background: "#fff" }}>S.ST and R.E</th>
            <th style={{ border: "1.5px solid #444", padding: "3px 6px", fontWeight: 900, fontSize: "10.5px", textTransform: "uppercase", background: "#fff" }}>INT. SCIE</th>
            <th style={{ border: "1.5px solid #444", padding: "3px 6px", fontWeight: 900, fontSize: "10.5px", textTransform: "uppercase", background: "#fff" }}>AGG</th>
            <th style={{ border: "1.5px solid #444", padding: "3px 6px", fontWeight: 900, fontSize: "10.5px", textTransform: "uppercase", background: "#fff" }}>Division</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td style={{ textAlign: "left", fontWeight: 700, paddingLeft: "8px", border: "1.5px solid #444", padding: "3px 6px" }}>B.O.T</td>
            {primarySubjects.slice(0, 4).map((subject) => {
              const score = progressive?.bot?.[subject] ?? "";
              return <td key={subject} style={{ textAlign: "center", border: "1.5px solid #444", padding: "3px 6px" }}>{score}</td>;
            })}
            <td style={{ textAlign: "center", border: "1.5px solid #444", padding: "3px 6px" }}></td>
            <td style={{ textAlign: "center", border: "1.5px solid #444", padding: "3px 6px" }}></td>
          </tr>
          <tr>
            <td style={{ textAlign: "left", fontWeight: 700, paddingLeft: "8px", border: "1.5px solid #444", padding: "3px 6px" }}>Mid Term</td>
            {primarySubjects.slice(0, 4).map((subject) => {
              const score = progressive?.mid?.[subject] ?? "";
              return <td key={subject} style={{ textAlign: "center", border: "1.5px solid #444", padding: "3px 6px" }}>{score}</td>;
            })}
            <td style={{ textAlign: "center", border: "1.5px solid #444", padding: "3px 6px" }}></td>
            <td style={{ textAlign: "center", border: "1.5px solid #444", padding: "3px 6px" }}></td>
          </tr>
        </tbody>
      </table>

      {/* Grading Box */}
      <div style={{ margin: "7px 0 0", fontSize: "10.5px", fontWeight: 700, border: "1px solid #444", padding: "4px 6px" }}>
        <div style={{ display: "grid", gridTemplateColumns: "80px repeat(8,1fr)", gap: 0 }}>
          <div style={{ fontWeight: 900, textAlign: "right", paddingRight: "6px" }}>Grading</div>
          <div style={{ textAlign: "center", padding: "1px 2px", borderRight: "1px solid #aaa" }}>00-34</div>
          <div style={{ textAlign: "center", padding: "1px 2px", borderRight: "1px solid #aaa" }}>35-39</div>
          <div style={{ textAlign: "center", padding: "1px 2px", borderRight: "1px solid #aaa" }}>40-44</div>
          <div style={{ textAlign: "center", padding: "1px 2px", borderRight: "1px solid #aaa" }}>45-49</div>
          <div style={{ textAlign: "center", padding: "1px 2px", borderRight: "1px solid #aaa" }}>50-59</div>
          <div style={{ textAlign: "center", padding: "1px 2px", borderRight: "1px solid #aaa" }}>60-69</div>
          <div style={{ textAlign: "center", padding: "1px 2px", borderRight: "1px solid #aaa" }}>70-79</div>
          <div style={{ textAlign: "center", padding: "1px 2px", borderRight: "1px solid #aaa" }}>80-94</div>
          <div style={{ textAlign: "center", padding: "1px 2px" }}>95-100</div>
        </div>
        <div style={{ display: "grid", gridTemplateColumns: "80px repeat(8,1fr)", gap: 0, marginTop: "1px" }}>
          <div style={{ fontWeight: 900, textAlign: "right", paddingRight: "6px" }}>Scale</div>
          <div style={{ textAlign: "center", padding: "1px 2px", borderRight: "1px solid #aaa" }}>F9</div>
          <div style={{ textAlign: "center", padding: "1px 2px", borderRight: "1px solid #aaa" }}>P8</div>
          <div style={{ textAlign: "center", padding: "1px 2px", borderRight: "1px solid #aaa" }}>P7</div>
          <div style={{ textAlign: "center", padding: "1px 2px", borderRight: "1px solid #aaa" }}>C6</div>
          <div style={{ textAlign: "center", padding: "1px 2px", borderRight: "1px solid #aaa" }}>C5</div>
          <div style={{ textAlign: "center", padding: "1px 2px", borderRight: "1px solid #aaa" }}>C4</div>
          <div style={{ textAlign: "center", padding: "1px 2px", borderRight: "1px solid #aaa" }}>C3</div>
          <div style={{ textAlign: "center", padding: "1px 2px", borderRight: "1px solid #aaa" }}>D2</div>
          <div style={{ textAlign: "center", padding: "1px 2px" }}>D1</div>
        </div>
      </div>

      {/* Comments */}
      <div style={{ marginTop: "7px" }}>
        <div><span style={{ fontWeight: 900 }}>Class Teacher's Comment: </span><span style={{ display: "inline-block", width: "340px", borderBottom: "1px solid #666", height: "14px", verticalAlign: "bottom" }}>{summary.teacher_remark || ""}</span></div>
        <div style={{ borderBottom: "1px dotted #888", margin: "5px 0" }}></div>
        <div style={{ display: "flex", justifyContent: "flex-end", fontSize: "10px", color: "#444" }}>SIGNATURE .....................................</div>
        <div style={{ margin: "6px 0 2px" }}><span style={{ fontWeight: 900 }}>Headteacher's Comment</span> <span style={{ display: "inline-block", width: "300px", borderBottom: "1px solid #666", height: "14px", verticalAlign: "bottom" }}></span></div>
        <div style={{ borderBottom: "1px dotted #888" }}></div>
        <div style={{ display: "flex", justifyContent: "flex-end", fontSize: "10px", color: "#444" }}>SIGNATURE .....................................</div>
      </div>

      {/* Fees */}
      <div style={{ display: "flex", flexWrap: "wrap", gap: "3px 24px", fontSize: "11px", fontWeight: 700, margin: "7px 0" }}>
        <span><b>Requirement Fee:</b> <span style={{ display: "inline-block", width: "80px", borderBottom: "1px solid #555", height: "13px", verticalAlign: "bottom" }}>{summary.req_fee || ""}</span></span>
        <span><b>Next Term's Fees:</b> <span style={{ display: "inline-block", width: "80px", borderBottom: "1px solid #555", height: "13px", verticalAlign: "bottom" }}>{summary.next_fee || ""}</span></span>
      </div>
      <div style={{ display: "flex", flexWrap: "wrap", gap: "3px 24px", fontSize: "11px", fontWeight: 700 }}>
        <span><b>School Fees Balance</b> <span style={{ display: "inline-block", width: "120px", borderBottom: "1px solid #555", height: "13px", verticalAlign: "bottom" }}>{summary.balance || ""}</span></span>
        <span><b>Development:</b> <span style={{ display: "inline-block", width: "120px", borderBottom: "1px solid #555", height: "13px", verticalAlign: "bottom" }}>{summary.development || ""}</span></span>
      </div>

      {/* Dates */}
      <div style={{ display: "flex", justifyContent: "space-between", fontSize: "11px", fontWeight: 900, margin: "6px 0" }}>
        <span>This Term Ended On: <span style={{ display: "inline-block", width: "80px", borderBottom: "1px solid #555", height: "13px", verticalAlign: "bottom" }}>{summary.term_ended || ""}</span></span>
        <span>Next Term Starts On: <span style={{ display: "inline-block", width: "80px", borderBottom: "1px solid #555", height: "13px", verticalAlign: "bottom" }}>{summary.next_term || ""}</span></span>
      </div>

      {/* Note */}
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-end", marginTop: "6px" }}>
        <div style={{ fontSize: "10px", fontWeight: 700 }}><b>Note</b><br/>This report is valid only when it bears school stamp</div>
        <div style={{ fontSize: "10px", fontWeight: 700, alignSelf: "flex-end" }}>School stamp</div>
        <div style={{ width: "64px", height: "64px", border: "2px dashed #aaa", borderRadius: "50%", display: "flex", alignItems: "center", justifyContent: "center", fontSize: "8.5px", color: "#aaa", fontWeight: 700, textAlign: "center" }}>School<br/>Stamp</div>
      </div>
      <div style={{ fontWeight: 900, fontSize: "13px", letterSpacing: ".08em", marginTop: "7px", borderTop: "2.5px solid #000", paddingTop: "6px", textAlign: "center" }}>Motto: ' Plan For Tomorrow</div>
    </div>
  );
}
