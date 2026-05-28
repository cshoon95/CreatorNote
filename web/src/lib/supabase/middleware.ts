import { createServerClient, type CookieOptions } from "@supabase/ssr";
import { NextResponse, type NextRequest } from "next/server";

type SetCookie = { name: string; value: string; options?: CookieOptions };

const PUBLIC_PATHS = [
  "/login",
  "/auth/start",
  "/auth/callback",
  "/auth/error",
  "/_next",
  "/favicon.ico",
  "/robots.txt",
  "/sitemap.xml",
];

export async function updateSession(request: NextRequest) {
  let response = NextResponse.next({ request });

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll();
        },
        setAll(cookiesToSet: SetCookie[]) {
          cookiesToSet.forEach(({ name, value }) => request.cookies.set(name, value));
          response = NextResponse.next({ request });
          cookiesToSet.forEach(({ name, value, options }) =>
            response.cookies.set(name, value, options),
          );
        },
      },
    },
  );

  // IMPORTANT: getUser refreshes the session if expired and re-sends cookies.
  const {
    data: { user },
  } = await supabase.auth.getUser();

  const path = request.nextUrl.pathname;
  const isPublic = PUBLIC_PATHS.some((p) => path === p || path.startsWith(p + "/"));

  if (!user && !isPublic) {
    // API routes: return JSON 401 instead of redirecting to /login.
    // Browsers/clients expect a proper status code for fetch() calls.
    if (path.startsWith("/api/")) {
      return new NextResponse(
        JSON.stringify({ error: "unauthorized" }),
        { status: 401, headers: { "Content-Type": "application/json" } },
      );
    }
    const url = request.nextUrl.clone();
    url.pathname = "/login";
    url.searchParams.set("next", path);
    return NextResponse.redirect(url);
  }

  if (user && path === "/login") {
    const url = request.nextUrl.clone();
    url.pathname = "/";
    return NextResponse.redirect(url);
  }

  // Disable browser caching for the login flow so iOS Safari doesn't keep
  // serving a stale version of the login page (which previously had bad
  // OAuth hrefs that triggered "주소가 유효하지 않습니다" errors).
  if (path === "/login" || path.startsWith("/auth/")) {
    response.headers.set("Cache-Control", "no-store, max-age=0, must-revalidate");
  }
  return response;
}
