import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

// Server-side OAuth kickoff. The browser only sees a short URL on our own
// domain, sidestepping iOS Safari's complaints about long client-built OAuth
// links. The PKCE code-verifier is written to a cookie before redirect.
export async function GET(request: Request) {
  const url = new URL(request.url);
  const provider = (url.searchParams.get("provider") ?? "google") as "google" | "apple";
  const next = url.searchParams.get("next") ?? "/";

  const supabase = await createClient();
  const redirectTo = `${url.origin}/auth/callback?next=${encodeURIComponent(next)}`;
  const { data, error } = await supabase.auth.signInWithOAuth({
    provider,
    options: { redirectTo, skipBrowserRedirect: true },
  });

  if (error || !data?.url) {
    const back = new URL("/login", url.origin);
    back.searchParams.set("error", error?.message ?? "no_url");
    return NextResponse.redirect(back);
  }
  return NextResponse.redirect(data.url);
}
