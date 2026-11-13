-- Conversion webhooks: forward click events to external services (Facebook CAPI, Google, etc.)
ALTER TABLE links ADD COLUMN IF NOT EXISTS webhook_url text;

-- Index for querying links with webhooks configured
CREATE INDEX IF NOT EXISTS idx_links_webhook ON links (webhook_url) WHERE webhook_url IS NOT NULL;
