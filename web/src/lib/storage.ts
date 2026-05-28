import { createClient } from "@/lib/supabase/client";

const BUCKET = "note-images";

export async function uploadNoteImage(userId: string, file: File): Promise<string | null> {
  const supabase = createClient();
  const ext = file.name.split(".").pop()?.toLowerCase() || "jpg";
  const path = `${userId}/${crypto.randomUUID()}.${ext}`;
  const { error } = await supabase.storage.from(BUCKET).upload(path, file, {
    contentType: file.type || "image/jpeg",
    upsert: false,
  });
  if (error) {
    console.error("upload error", error);
    return null;
  }
  return path;
}

export async function getSignedUrl(path: string): Promise<string | null> {
  const supabase = createClient();
  const { data, error } = await supabase.storage.from(BUCKET).createSignedUrl(path, 3600);
  if (error || !data) return null;
  return data.signedUrl;
}

export async function getSignedUrls(paths: string[]): Promise<Record<string, string>> {
  if (paths.length === 0) return {};
  const supabase = createClient();
  const { data, error } = await supabase.storage.from(BUCKET).createSignedUrls(paths, 3600);
  if (error || !data) return {};
  const map: Record<string, string> = {};
  data.forEach((d, i) => {
    if (d.signedUrl) map[paths[i]] = d.signedUrl;
  });
  return map;
}

export async function deleteNoteImages(paths: string[]): Promise<void> {
  if (paths.length === 0) return;
  const supabase = createClient();
  await supabase.storage.from(BUCKET).remove(paths);
}
