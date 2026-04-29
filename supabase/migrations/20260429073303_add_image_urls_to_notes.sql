-- Add image_urls column to both note tables
ALTER TABLE reels_notes ADD COLUMN IF NOT EXISTS image_urls text[] DEFAULT '{}';
ALTER TABLE general_notes ADD COLUMN IF NOT EXISTS image_urls text[] DEFAULT '{}';

-- Create storage bucket for note images
INSERT INTO storage.buckets (id, name, public)
VALUES ('note-images', 'note-images', true)
ON CONFLICT (id) DO NOTHING;

-- Allow authenticated users to upload
CREATE POLICY "Authenticated users can upload note images"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'note-images');

-- Allow public read
CREATE POLICY "Public read note images"
ON storage.objects FOR SELECT TO public
USING (bucket_id = 'note-images');

-- Allow users to delete their own images
CREATE POLICY "Users can delete own note images"
ON storage.objects FOR DELETE TO authenticated
USING (bucket_id = 'note-images');
