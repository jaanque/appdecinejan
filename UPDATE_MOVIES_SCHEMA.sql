-- Add genres and overview columns to user_movies table
ALTER TABLE user_movies
ADD COLUMN IF NOT EXISTS genres text[],
ADD COLUMN IF NOT EXISTS overview text;

-- Notify PostgREST to reload schema
NOTIFY pgrst, 'reload schema';
