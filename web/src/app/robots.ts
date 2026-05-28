import type { MetadataRoute } from "next";

export default function robots(): MetadataRoute.Robots {
  const base =
    process.env.NEXT_PUBLIC_SITE_URL ?? "https://creatornote-web.vercel.app";
  return {
    rules: [
      {
        userAgent: "*",
        allow: ["/login", "/auth/error"],
        // Authenticated app shouldn't be indexed
        disallow: [
          "/dashboard",
          "/sponsorships",
          "/settlements",
          "/notes",
          "/calendar",
          "/search",
          "/settings",
          "/ai",
          "/onboarding",
          "/pending",
          "/auth/callback",
          "/auth/start",
          "/api/",
        ],
      },
    ],
    sitemap: `${base}/sitemap.xml`,
    host: base,
  };
}
