-- Device info columns for clicks table
ALTER TABLE clicks ADD COLUMN IF NOT EXISTS browser text;
ALTER TABLE clicks ADD COLUMN IF NOT EXISTS os text;
ALTER TABLE clicks ADD COLUMN IF NOT EXISTS device_type text;
ALTER TABLE clicks ADD COLUMN IF NOT EXISTS device_json jsonb;

-- Index for filtering by device type / browser
CREATE INDEX IF NOT EXISTS idx_clicks_device_type ON clicks (device_type);
CREATE INDEX IF NOT EXISTS idx_clicks_browser ON clicks (browser);

-- Update the links_with_counts view to be aware of new columns (no change needed,
-- SELECT * already includes them, but let's make sure RPC functions still work)
