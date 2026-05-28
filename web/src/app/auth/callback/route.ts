import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import type { EmailOtpType } from "@supabase/supabase-js";

// Supabase sends users back here from three flows:
//   1) OAuth / PKCE magic link  -> ?code=...
//   2) Email signup confirmation -> ?token_hash=...&type=signup
//   3) Magic link (token_hash variant) -> ?token_hash=...&type=magiclink
// We accept all three so the same callback handles every Supabase auth method.
export async function GET(request: Request) {
  const url = new URL(request.url);
  const code = url.searchParams.get("code");
  const tokenHash = url.searchParams.get("token_hash");
  const type = url.searchParams.get("type") as EmailOtpType | null;
  const next = url.searchParams.get("next") ?? "/";

  const supabase = await createClient();
  let exchangeError: string | null = null;
  let succeeded = false;

  if (code) {
    const { error } = await supabase.auth.exchangeCodeForSession(code);
    if (error) exchangeError = `exchange: ${error.message}`;
    else succeeded = true;
  } else if (tokenHash && type) {
    const { error } = await supabase.auth.verifyOtp({ token_hash: tokenHash, type });
    if (error) exchangeError = `verify: ${error.message}`;
    else succeeded = true;
  } else {
    exchangeError = "no auth token in callback URL";
  }

  if (succeeded) {
    // Ensure profile row exists (the auth.users → profiles trigger handles
    // this normally, but we backstop it for safety).
    const { data } = await supabase.auth.getUser();
    const user = data.user;
    if (user) {
      const { data: existing } = await supabase
        .from("profiles")
        .select("id")
        .eq("id", user.id)
        .maybeSingle();
      if (!existing) {
        const meta = user.user_metadata ?? {};
        await supabase.from("profiles").insert({
          id: user.id,
          display_name:
            (meta.full_name as string | undefined) ??
            (meta.name as string | undefined) ??
            randomNickname(),
          avatar_url: (meta.avatar_url as string | undefined) ?? null,
          provider: user.app_metadata?.provider ?? "email",
        });
      }
    }
    return NextResponse.redirect(new URL(next, url.origin));
  }

  const errUrl = new URL("/auth/error", url.origin);
  if (exchangeError) errUrl.searchParams.set("msg", exchangeError);
  return NextResponse.redirect(errUrl);
}

function randomNickname(): string {
  const a = ["귀여운", "빛나는", "씩씩한", "따뜻한", "활발한", "행복한", "신나는", "용감한", "멋있는", "상큼한"];
  const b = ["크리에이터", "작가", "별", "달", "나무", "구름", "바다", "하늘", "꽃", "새"];
  return a[Math.floor(Math.random() * a.length)] + b[Math.floor(Math.random() * b.length)];
}
