-- Visitor tracking: visitor_id for cookie-based cross-link stitching
ALTER TABLE clicks ADD COLUMN IF NOT EXISTS visitor_id text;

-- Index for looking up all clicks by the same visitor
CREATE INDEX IF NOT EXISTS idx_clicks_visitor_id ON clicks (visitor_id);
