-- ============================================================
-- Enbridge App — Supabase Schema
-- Run these in the Supabase SQL Editor
-- ============================================================

-- Calendar Events table
CREATE TABLE IF NOT EXISTS calendar_events (
  id            TEXT PRIMARY KEY,
  user_id       UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title         TEXT NOT NULL,
  description   TEXT,
  date          TIMESTAMPTZ NOT NULL,
  reminder_at   TIMESTAMPTZ,
  has_reminder  BOOLEAN DEFAULT FALSE,
  type          TEXT DEFAULT 'general',
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- Row Level Security — users can only see their own events
ALTER TABLE calendar_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own events"
  ON calendar_events FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own events"
  ON calendar_events FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own events"
  ON calendar_events FOR DELETE
  USING (auth.uid() = user_id);

-- Index for fast per-user date queries
CREATE INDEX IF NOT EXISTS idx_calendar_events_user_date
  ON calendar_events (user_id, date);
