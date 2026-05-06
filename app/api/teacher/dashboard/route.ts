import { NextResponse } from "next/server";
import { cookies } from "next/headers";
import { createRouteHandlerClient } from "@supabase/auth-helpers-nextjs";

export const dynamic = "force-dynamic";

const resolveSubjectLevel = (className: string) => {
  if (className.startsWith("KG")) return "nursery";
  if (
    className.startsWith("P1") ||
    className.startsWith("P2") ||
    className.startsWith("P3")
  ) {
    return "p1-p3";
  }
  return "p4-p7";
};

export async function GET() {
  const supabase = createRouteHandlerClient({ cookies });
  const {
    data: { user }
  } = await supabase.auth.getUser();

  if (!user) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const { data: appUser, error: appUserError } = await supabase
    .from("users")
    .select("id, email, name, role, class_id")
    .eq("id", user.id)
    .single();

  if (appUserError || !appUser) {
    return NextResponse.json(
      { error: "User record not found" },
      { status: 404 }
    );
  }

  if (appUser.role !== "teacher") {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  const { data: classInfo } = await supabase
    .from("classes")
    .select("id, name")
    .eq("id", appUser.class_id)
    .single();

  const subjectLevel = classInfo ? resolveSubjectLevel(classInfo.name) : "p4-p7";

  const { data: pupils } = await supabase
    .from("pupils")
    .select("id, name, avatar, house, paycode")
    .eq("class_id", appUser.class_id)
    .order("name");

  const { data: subjects } = await supabase
    .from("subjects")
    .select("id, name")
    .eq("level", subjectLevel)
    .order("name");

  const pupilIds = (pupils ?? []).map((pupil) => pupil.id);

  const { data: marks } = pupilIds.length
    ? await supabase
        .from("marks")
        .select("id, pupil_id, subject_id, score, teacher_comment")
        .in("pupil_id", pupilIds)
    : { data: [] as Array<{ id: string; pupil_id: string; subject_id: string; score: number; teacher_comment?: string | null }> };

  const { data: performance } = await supabase
    .from("class_performance")
    .select("class_name, average_score, best_pupil, weakest_pupil")
    .eq("class_id", appUser.class_id)
    .single();

  return NextResponse.json({
    user: {
      id: appUser.id,
      email: appUser.email,
      name: appUser.name,
      classId: appUser.class_id
    },
    classInfo,
    pupils: pupils ?? [],
    subjects: subjects ?? [],
    marks: marks ?? [],
    performance: performance ?? null
  });
}
