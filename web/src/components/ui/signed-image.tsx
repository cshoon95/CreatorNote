"use client";

import { useEffect, useState } from "react";
import { getSignedUrl, getSignedUrls } from "@/lib/storage";

interface SignedImageProps {
  /** Storage path. If `url` is also provided, `url` wins (no extra fetch). */
  path: string;
  /** Pre-resolved signed URL (for batch parents). */
  url?: string | null;
  alt?: string;
  className?: string;
  onClick?: () => void;
}

export function SignedImage({ path, url: urlProp, alt, className, onClick }: SignedImageProps) {
  const [url, setUrl] = useState<string | null>(urlProp ?? null);

  useEffect(() => {
    if (urlProp) {
      setUrl(urlProp);
      return;
    }
    let active = true;
    getSignedUrl(path).then((u) => {
      if (active) setUrl(u);
    });
    return () => {
      active = false;
    };
  }, [path, urlProp]);

  if (!url) {
    return (
      <div
        className={className}
        style={{ background: "var(--border)", display: "flex", alignItems: "center", justifyContent: "center" }}
      >
        <span style={{ color: "var(--text-tertiary)", fontSize: 12 }}>...</span>
      </div>
    );
  }
  // eslint-disable-next-line @next/next/no-img-element
  return <img src={url} alt={alt ?? ""} className={className} onClick={onClick} />;
}

/**
 * Hook: resolve signed URLs for a list of paths in a single batched request.
 * Returns a map (path → url) that updates as the batch resolves.
 */
export function useSignedUrls(paths: string[]): Record<string, string> {
  const [urls, setUrls] = useState<Record<string, string>>({});
  const key = paths.join("|");

  useEffect(() => {
    if (paths.length === 0) {
      setUrls({});
      return;
    }
    let active = true;
    getSignedUrls(paths).then((map) => {
      if (active) setUrls(map);
    });
    return () => {
      active = false;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [key]);

  return urls;
}
