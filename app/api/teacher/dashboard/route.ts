import { NextRequest, NextResponse } from "next/server";
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

export async function GET(req: NextRequest) {
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

  // Fetch all classes assigned to this teacher
  const { data: teacherClasses } = await supabase
    .from("teacher_classes")
    .select("class_id, classes(id, name)")
    .eq("teacher_id", appUser.id);

  const assignedClasses: { id: string; name: string }[] = (teacherClasses ?? [])
    .map((tc) => tc.classes as { id: string; name: string })
    .filter(Boolean);

  // Fallback to users.class_id if no teacher_classes entries
  if (assignedClasses.length === 0 && appUser.class_id) {
    const { data: fallbackClass } = await supabase
      .from("classes")
      .select("id, name")
      .eq("id", appUser.class_id)
      .single();
    if (fallbackClass) assignedClasses.push(fallbackClass);
  }

  // Determine which class to show: use URL param or first assigned class
  const searchParams = req.nextUrl.searchParams;
  const requestedClassId = searchParams.get("classId");
  const activeClass =
    assignedClasses.find((c) => c.id === requestedClassId) ?? assignedClasses[0] ?? null;

  let pupils: Array<{
    id: string;
    name: string;
    avatar?: string | null;
    house?: string | null;
    paycode?: string | null;
  }> = [];
  let subjects: Array<{ id: string; name: string }> = [];
  let marks: Array<{
    id: string;
    pupil_id: string;
    subject_id: string;
    score: number;
    teacher_comment?: string | null;
  }> = [];
  let performance: {
    class_name: string;
    average_score: number;
    best_pupil: string | null;
    weakest_pupil: string | null;
  } | null = null;

  if (activeClass) {
    const subjectLevel = resolveSubjectLevel(activeClass.name);

    const { data: pupilsData } = await supabase
      .from("pupils")
      .select("id, name, avatar, house, paycode")
      .eq("class_id", activeClass.id)
      .order("name");

    pupils = pupilsData ?? [];

    const { data: subjectsData } = await supabase
      .from("subjects")
      .select("id, name")
      .eq("level", subjectLevel)
      .order("name");

    subjects = subjectsData ?? [];

    const pupilIds = pupils.map((p) => p.id);
    if (pupilIds.length) {
      const { data: marksData } = await supabase
        .from("marks")
        .select("id, pupil_id, subject_id, score, teacher_comment")
        .in("pupil_id", pupilIds);
      marks = marksData ?? [];
    }

    const { data: perfData } = await supabase
      .from("class_performance")
      .select("class_name, average_score, best_pupil, weakest_pupil")
      .eq("class_id", activeClass.id)
      .single();
    performance = perfData ?? null;
  }

  return NextResponse.json({
    user: {
      id: appUser.id,
      email: appUser.email,
      name: appUser.name,
      classId: activeClass?.id ?? appUser.class_id
    },
    classInfo: activeClass,
    assignedClasses,
    pupils,
    subjects,
    marks,
    performance
  });
}
