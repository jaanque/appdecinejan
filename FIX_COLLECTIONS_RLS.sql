-- FIX_COLLECTIONS_RLS.sql
-- Run this script in your Supabase SQL Editor to fix the "new row violates row-level security policy" (Code 42501) error.

-- 1. Reset & Re-create RLS Policies
-- We drop both old and potential new names to be safe
DROP POLICY IF EXISTS "Users can view their own collections" ON public.collections;
DROP POLICY IF EXISTS "Users can insert their own collections" ON public.collections;
DROP POLICY IF EXISTS "Users can delete their own collections" ON public.collections;
DROP POLICY IF EXISTS "Users can update their own collections" ON public.collections;

DROP POLICY IF EXISTS "Enable read access for owners" ON public.collections;
DROP POLICY IF EXISTS "Enable insert for owners" ON public.collections;
DROP POLICY IF EXISTS "Enable delete for owners" ON public.collections;
DROP POLICY IF EXISTS "Enable update for owners" ON public.collections;

-- Enable RLS just in case
ALTER TABLE public.collections ENABLE ROW LEVEL SECURITY;

-- SELECT
CREATE POLICY "Enable read access for owners"
ON public.collections FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

-- INSERT
CREATE POLICY "Enable insert for owners"
ON public.collections FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

-- DELETE
CREATE POLICY "Enable delete for owners"
ON public.collections FOR DELETE
TO authenticated
USING (auth.uid() = user_id);

-- UPDATE
CREATE POLICY "Enable update for owners"
ON public.collections FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- 2. Explicit Grants (Crucial for Permission Denied errors)
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON TABLE public.collections TO authenticated;

-- IMPORTANT: Grant access to sequences for auto-increment IDs
-- This is often the cause of 42501 errors on insert
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- 3. Reload Cache
NOTIFY pgrst, 'reload schema';
