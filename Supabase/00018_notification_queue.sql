-- Notification queue for push delivery via Edge Functions
CREATE TABLE IF NOT EXISTS notification_queue (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
    kind TEXT NOT NULL CHECK (kind IN ('reply', 'moderation', 'weekly_prompt')),
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'batched', 'skipped', 'failed')),
    send_after TIMESTAMPTZ NOT NULL DEFAULT now(),
    attempt_count INT NOT NULL DEFAULT 0,
    last_error TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    processed_at TIMESTAMPTZ
);

CREATE INDEX idx_notification_queue_pending ON notification_queue(status, send_after)
    WHERE status = 'pending';
CREATE INDEX idx_notification_queue_user ON notification_queue(user_id);

-- No authenticated RLS — only service_role (Edge Functions) accesses this table
ALTER TABLE notification_queue ENABLE ROW LEVEL SECURITY;
-- No policies = no authenticated access
