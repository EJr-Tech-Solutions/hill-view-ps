import { NextResponse } from "next/server";
import { cookies } from "next/headers";
import { createRouteHandlerClient } from "@supabase/auth-helpers-nextjs";

export const dynamic = "force-dynamic";

export async function GET() {
  const supabase = createRouteHandlerClient({ cookies });

  const { data, error } = await supabase
    .from("academic_terms")
    .select("*")
    .order("year", { ascending: false })
    .order("term", { ascending: true });

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  return NextResponse.json({ terms: data });
}

export async function POST(request: Request) {
  const supabase = createRouteHandlerClient({ cookies });
  const body = await request.json();

  const { term, year, start_date, end_date, stream } = body;

  if (!term || !year || !start_date || !end_date) {
    return NextResponse.json({ error: "Missing required fields" }, { status: 400 });
  }

  const { data, error } = await supabase
    .from("academic_terms")
    .insert({
      term,
      year,
      start_date,
      end_date,
      stream: stream || "Main",
      is_active: false,
    })
    .select()
    .single();

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  return NextResponse.json({ term: data });
}

export async function PATCH(request: Request) {
  const supabase = createRouteHandlerClient({ cookies });
  const body = await request.json();

  const { id, is_active } = body;

  if (is_active) {
    // Deactivate all other terms
    await supabase
      .from("academic_terms")
      .update({ is_active: false })
      .neq("id", "00000000-0000-0000-0000-000000000000");

    // Activate the selected term
    const { error } = await supabase
      .from("academic_terms")
      .update({ is_active: true, updated_at: new Date().toISOString() })
      .eq("id", id);

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 500 });
    }
  }

  return NextResponse.json({ success: true });
}
