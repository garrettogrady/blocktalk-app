-- BlockTalk MOCK Seed — Reported Content
-- Seeds reports against existing mock posts to populate the moderation queue.
-- Uses deterministic UUIDs (f0... for reports) so this is safe to re-run.
--
-- Creates 3 scenarios:
--   1. Post with 1 report  → status = 'under_review'
--   2. Post with 2 reports → status = 'under_review'
--   3. Posts with 3+ reports → status = 'removed' (auto-hidden)

-- ============================================================
-- 0. Clean prior report seed (safe to re-run)
-- ============================================================
DELETE FROM reports WHERE id::text LIKE 'f0000000-%';

-- Reset statuses on the posts we're about to report
UPDATE posts SET status = 'live', report_count = 0
WHERE id IN (
  'd0000000-0000-0000-0000-000000000008',
  'd0000000-0000-0000-0000-000000000012',
  'd0000000-0000-0000-0000-000000000019',
  'd0000000-0000-0000-0000-000000000006',
  'd0000000-0000-0000-0000-000000000017'
);

-- ============================================================
-- 1. Post 08 (clintonst — "unmarked black sedan") — 1 report → under_review
--    Reason: spam
-- ============================================================
INSERT INTO reports (id, reporter_id, post_id, reason, free_text, created_at) VALUES
  ('f0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000002', 'd0000000-0000-0000-0000-000000000008', 'spam', NULL, now() - interval '2 hours');

-- ============================================================
-- 2. Post 12 (BlockTalker — "saturday 3am on Ludlow") — 2 reports → under_review
--    Reasons: pii, other
-- ============================================================
INSERT INTO reports (id, reporter_id, post_id, reason, free_text, created_at) VALUES
  ('f0000000-0000-0000-0000-000000000002', 'b0000000-0000-0000-0000-000000000009', 'd0000000-0000-0000-0000-000000000012', 'pii', NULL, now() - interval '3 hours'),
  ('f0000000-0000-0000-0000-000000000003', 'b0000000-0000-0000-0000-000000000014', 'd0000000-0000-0000-0000-000000000012', 'other', 'Calling out specific people at a specific bar feels like doxxing', now() - interval '2 hours');

-- ============================================================
-- 3. Post 19 (clintonst — bouncer at Local 138) — 3 reports → removed
--    Reasons: pii, threats, other
-- ============================================================
INSERT INTO reports (id, reporter_id, post_id, reason, free_text, created_at) VALUES
  ('f0000000-0000-0000-0000-000000000004', 'b0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000019', 'pii', NULL, now() - interval '6 hours'),
  ('f0000000-0000-0000-0000-000000000005', 'b0000000-0000-0000-0000-000000000004', 'd0000000-0000-0000-0000-000000000019', 'threats', NULL, now() - interval '5 hours'),
  ('f0000000-0000-0000-0000-000000000006', 'b0000000-0000-0000-0000-000000000010', 'd0000000-0000-0000-0000-000000000019', 'other', 'Names a real business and a real person working there — not cool', now() - interval '4 hours');

-- ============================================================
-- 4. Post 06 (norfolkghost — "guy outside Beauty & Essex") — 3 reports → removed
--    Reasons: pii, hate, pii
-- ============================================================
INSERT INTO reports (id, reporter_id, post_id, reason, free_text, created_at) VALUES
  ('f0000000-0000-0000-0000-000000000007', 'b0000000-0000-0000-0000-000000000011', 'd0000000-0000-0000-0000-000000000006', 'pii', NULL, now() - interval '8 hours'),
  ('f0000000-0000-0000-0000-000000000008', 'b0000000-0000-0000-0000-000000000008', 'd0000000-0000-0000-0000-000000000006', 'hate', NULL, now() - interval '7 hours'),
  ('f0000000-0000-0000-0000-000000000009', 'b0000000-0000-0000-0000-000000000012', 'd0000000-0000-0000-0000-000000000006', 'pii', NULL, now() - interval '6 hours');

-- ============================================================
-- 5. Post 17 (ludlow_loiter — "girl on Stanton at 2:47am") — 4 reports → removed
--    Reasons: pii, sexual, threats, other
-- ============================================================
INSERT INTO reports (id, reporter_id, post_id, reason, free_text, created_at) VALUES
  ('f0000000-0000-0000-0000-000000000010', 'b0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000017', 'pii', NULL, now() - interval '10 hours'),
  ('f0000000-0000-0000-0000-000000000011', 'b0000000-0000-0000-0000-000000000006', 'd0000000-0000-0000-0000-000000000017', 'sexual', NULL, now() - interval '9 hours'),
  ('f0000000-0000-0000-0000-000000000012', 'b0000000-0000-0000-0000-000000000004', 'd0000000-0000-0000-0000-000000000017', 'threats', NULL, now() - interval '8 hours'),
  ('f0000000-0000-0000-0000-000000000013', 'b0000000-0000-0000-0000-000000000013', 'd0000000-0000-0000-0000-000000000017', 'other', 'Describing a real person at a specific time and place without consent', now() - interval '7 hours');

-- Done. Moderation queue should now show:
--   2 posts "under_review" (1 report, 2 reports)
--   3 posts "removed" (3, 3, and 4 reports)
