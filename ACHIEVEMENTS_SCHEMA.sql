-- Create a table to track unlocked achievements for each user
CREATE TABLE IF NOT EXISTS public.user_achievements (
    id bigint generated always as identity primary key,
    user_id uuid references auth.users not null default auth.uid(),
    achievement_id text not null,
    unlocked_at timestamp with time zone default timezone('utc'::text, now()) not null,
    constraint user_achievements_user_id_achievement_id_key unique (user_id, achievement_id)
);

-- Enable Row Level Security
ALTER TABLE public.user_achievements ENABLE ROW LEVEL SECURITY;

-- Policy: Users can see only their own achievements
CREATE POLICY "Users can view their own achievements"
ON public.user_achievements
FOR SELECT
USING (auth.uid() = user_id);

-- Policy: Users can insert their own achievements
-- Note: In a production app with server-side logic, you might restrict this to service role only.
-- For this app's architecture (Client-side logic), we allow authenticated users to insert.
CREATE POLICY "Users can insert their own achievements"
ON public.user_achievements
FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Policy: Users can delete their own achievements (optional, for resetting)
CREATE POLICY "Users can delete their own achievements"
ON public.user_achievements
FOR DELETE
USING (auth.uid() = user_id);

-- Grant permissions
GRANT SELECT, INSERT, DELETE ON public.user_achievements TO authenticated;
GRANT SELECT ON public.user_achievements TO service_role;
