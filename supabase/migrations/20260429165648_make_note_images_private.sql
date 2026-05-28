-- Make note-images bucket private
UPDATE storage.buckets SET public = false WHERE id = 'note-images';

-- Drop public read policy
DROP POLICY IF EXISTS "Public read note images" ON storage.objects;

-- Allow authenticated users to read note images
CREATE POLICY "Authenticated users can read note images"
ON storage.objects FOR SELECT TO authenticated
USING (bucket_id = 'note-images');
