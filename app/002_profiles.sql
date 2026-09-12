-- 002_profiles.sql
-- Setup for the Persistent Player and Leaderboard System

-- Create the players table
CREATE TABLE IF NOT EXISTS public.players (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    display_name TEXT NOT NULL,
    best_score FLOAT DEFAULT 0.0,
    total_score FLOAT DEFAULT 0.0,
    games_played INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE public.players ENABLE ROW LEVEL SECURITY;

-- Policies for players
-- Anyone can read player profiles (needed for leaderboards)
CREATE POLICY "Profiles are viewable by everyone"
    ON public.players
    FOR SELECT
    USING (true);

-- Users can insert their own profile
CREATE POLICY "Users can insert their own profile"
    ON public.players
    FOR INSERT
    WITH CHECK (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
    ON public.players
    FOR UPDATE
    USING (auth.uid() = id);

-- Create scores table (assuming it might not exist yet from 001)
CREATE TABLE IF NOT EXISTS public.scores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    player_id UUID REFERENCES public.players(id) ON DELETE CASCADE,
    score FLOAT NOT NULL,
    accuracy FLOAT NOT NULL,
    event_detected BOOLEAN NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS for scores
ALTER TABLE public.scores ENABLE ROW LEVEL SECURITY;

-- Policies for scores
-- Anyone can read scores
CREATE POLICY "Scores are viewable by everyone"
    ON public.scores
    FOR SELECT
    USING (true);

-- Users can insert their own scores
CREATE POLICY "Users can insert their own scores"
    ON public.scores
    FOR INSERT
    WITH CHECK (auth.uid() = player_id);

-- Create a view for the leaderboard for easier querying (optional but helpful)
CREATE OR REPLACE VIEW public.leaderboard AS
SELECT 
    id AS player_id,
    display_name,
    best_score,
    total_score,
    games_played
FROM public.players
WHERE games_played > 0
ORDER BY best_score DESC, total_score DESC;
