-- 00036_storage_policies.sql
-- Lock down the post-images storage bucket so users can only upload to
-- their own folder and can't overwrite or delete other users' images.
--
-- The bucket is public (public: true) so anyone can read via the public URL.
-- These policies cover INSERT, UPDATE and DELETE on storage.objects.
--
-- Run in the Supabase SQL Editor after 00035. Safe to run more than once.

-- Ensure the bucket exists and is public (no-op if already created via dashboard).
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'post-images',
  'post-images',
  true,
  5242880,  -- 5 MB
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/heic']
)
ON CONFLICT (id) DO UPDATE SET
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- Drop any existing policies to avoid conflicts.
DROP POLICY IF EXISTS "Users upload to own folder" ON storage.objects;
DROP POLICY IF EXISTS "Users can update own images" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own images" ON storage.objects;
DROP POLICY IF EXISTS "Public read for post images" ON storage.objects;

-- 1. Upload: authenticated users can only insert into their own userId/ folder.
CREATE POLICY "Users upload to own folder" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'post-images'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- 2. Update: only your own images (prevents overwriting someone else's photo).
CREATE POLICY "Users can update own images" ON storage.objects
  FOR UPDATE TO authenticated
  USING (
    bucket_id = 'post-images'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- 3. Delete: only your own images.
CREATE POLICY "Users can delete own images" ON storage.objects
  FOR DELETE TO authenticated
  USING (
    bucket_id = 'post-images'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- 4. Read: the bucket is public so getPublicURL works without auth.
--    This SELECT policy covers signed reads if the bucket ever goes private.
CREATE POLICY "Public read for post images" ON storage.objects
  FOR SELECT TO authenticated, anon
  USING (bucket_id = 'post-images');
