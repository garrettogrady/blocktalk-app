# Edits & Deletes: Build Spec

> **Status: built.** The app side is implemented and the migration is written. This document is the reference for what was built and why, plus the checklist Garrett runs after applying `Supabase/00024_edits_and_deletes.sql`. Section 08 of the artifact "BlockTalk: Authority Tiers, Edits & Deletes" is the visual reference; where this file differs, this file wins (differences are listed in Part 8).
>
> Independent of Authority Tiers. Ships on its own, in either order relative to `00023_authority.sql`, though the migration numbers assume 00023 runs first.

---

## Contents

1. [What it does](#1-what-it-does)
2. [Edit rules](#2-edit-rules)
3. [Delete rules](#3-delete-rules)
4. [Migration `00024_edits_and_deletes.sql`](#4-migration-00024_edits_and_deletessql)
5. [Verify the migration](#5-verify-the-migration)
6. [App implementation](#6-app-implementation)
7. [Deployment order](#7-deployment-order)
8. [Decisions that differ from the artifact](#8-decisions-that-differ-from-the-artifact)
9. [Not built](#9-not-built)

---

## 1. What it does

A user can take back what they've written, without being able to rewrite history underneath people who already voted on it.

- **Edit** the body text of your own post or reply. Not the photo, not the pin. To change either, delete and repost.
- **Delete** your own post or reply. If nobody has replied, it's gone. If people have, your text is removed and their replies stay.

Your own posts and replies get an ellipsis button in the action row (where the flag is on everyone else's) with **Edit** and **Delete**.

## 2. Edit rules

Two zones, never a wall. Never refused, no time window.

| State of the content | What happens | Stored |
|---|---|---|
| 0 votes and 0 replies | Edits silently. No tag, no trace. | text only |
| Any vote or reply exists | Edit allowed, tagged "edited", original one tap away. | text + `original_text` |
| 2nd, 5th, 40th edit | Same. Tag already shown, original already captured. | text + `original_text` |

- **At most two versions of a row exist, ever.** `original_text = COALESCE(original_text, text)` captures the pre-edit text on the first marked edit and never overwrites it. There is no revision history table.
- **The silent zone keeps the tag meaningful.** A typo caught twenty seconds after posting carries no mark, so when "edited" appears on a post with 40 upvotes it means something.
- **The language gate re-runs.** `EditTextSheet` calls the same `LanguageCheck.containsHateSpeech` that compose uses. There is no server-side language check today for posting either; this keeps parity.
- **Rate limit:** roughly one edit per 30 seconds per item (`last_edit_at`, a hidden column). A limit on frequency, not on the right.
- **No diff-size cap.** "The landlord is great" to "the landlord is not great" is four characters and a total reversal; honest rewording easily exceeds 20% while meaning the same thing. The metric runs backwards, so it isn't built.
- **Editing does not reset votes and does not touch aura.**
- Tapping "edited" opens a sheet: **WHAT IT SAID** (time posted) / **WHAT IT SAYS NOW** (time edited) / "Votes and replies on this post came in before the edit."

## 3. Delete rules

Always allowed, two outcomes. Aura is never touched.

| State | Result |
|---|---|
| No replies, no reports | **Hard delete.** Row gone, out of feed, map and search. Votes, enrollments and queued pushes cascade. The pin is deleted if it was a street comment and nothing else points at it. Notifications that linked to the post are kept but unlinked. |
| Has replies | **Tombstone.** `status = 'deleted'`, body replaced with `[deleted]`, photo dropped. Replies and thread lines survive intact. Reply count stays. |
| Has any report, or is under review | **Tombstone regardless.** The row survives for the moderation queue and strike history. |
| Removed by a moderator | **Refused.** The removal notice and appeal path stay in place. |

Replies follow the same rule one level down: a reply with no children hard-deletes (the post's `reply_count` decrements via the existing trigger); a reply with children tombstones so the branch beneath it doesn't collapse.

**Why the thread survives:** the PRD already settled this for account deletion ("posts you've made will remain under the BlockTalker placeholder"). Other people's threads outliving your departure is existing policy; a deleted post applies it one level down.

**Why reported posts can't hard-delete:** without this, a user could post something harmful, get reported, and delete before a moderator sees it. The report would point at a row that no longer exists and the strike count (`00015_strikes_and_audit.sql`) would reset. Tombstoning closes that path with a targeted rule, which is what makes it safe to keep aura on voluntary deletes.

**Confirmation copy** (the surviving reply count is named to prevent "I deleted it, why is it still there"):

| Case | Title | Message |
|---|---|---|
| No replies | Delete this post? | It'll be gone from the feed, the map and search. This can't be undone. |
| Has replies | Delete this post? | Your text will be removed. The 7 replies underneath it will stay. Other people wrote those. |
| Reply, no children | Delete this reply? | It'll be gone. This can't be undone. |
| Reply, has children | Delete this reply? | Your text will be removed. The 3 replies underneath it will stay. Other people wrote those. |

## 4. Migration `00024_edits_and_deletes.sql`

Lives at `Supabase/00024_edits_and_deletes.sql`. Run it in the Supabase SQL Editor after `00023_authority.sql`. It was applied to a local Postgres with copies of the relevant tables and every check in Part 5 passed before it was committed.

What it does, in order:

1. **Columns.** `posts` and `replies` get `original_text`, `edited_at`, `edit_count`, `last_edit_at`. `replies` gets `status TEXT NOT NULL DEFAULT 'live'` (`live` | `deleted`). The `posts.status` check gains `'deleted'`.
2. **RLS.** The posts SELECT policy becomes `status IN ('live', 'deleted') OR user_id = auth.uid()` so anyone who can reach a thread (notification, share link, enrollment) can read its tombstone. The body is already blanked.
3. **`edit_post(p_post_id, p_text)`**, **`delete_post(p_post_id)`**, **`edit_reply(p_reply_id, p_text)`**, **`delete_reply(p_reply_id)`.** All `SECURITY DEFINER`, all verify `auth.uid()` is the owner, all decide every branch server-side and return JSONB (`success`, `error`, `message`, and on success `marked`/`text`/`original_text`/`edit_count` or `outcome`/`reply_count`). `edit_post` touches no column but `text`, `original_text`, `edited_at`, `edit_count`, `last_edit_at`; it cannot change `user_id` or `created_at`, which a broad table-level RLS UPDATE policy would permit. That's why these are RPCs and not table writes.

Every feed query already filters `status = 'live'`, so tombstones fall out of feeds, Discover, Search, `user_stats`, `user_created_posts` and the map's pin filter (`00020`) with no changes.

## 5. Verify the migration

Use two accounts, A and B. Run as A unless noted.

| Step | Expected |
|---|---|
| A edits their own fresh post (no votes, no replies) | Text changes; `edited_at` and `original_text` stay NULL; no "edited" tag in the app |
| A edits it again within 30 seconds | Error `rate_limited` |
| B upvotes it; A edits it | `marked: true`; `original_text` holds the pre-edit text; `edited_at` set; the app shows "edited" and tapping it shows both versions |
| A edits it a third time | `edit_count` 2; `original_text` unchanged |
| B calls `edit_post` on A's post | Error `not_owner` |
| A deletes a post with no replies and no reports (a street comment) | `outcome: hard`; row gone; its pin gone; the map no longer shows it |
| A deletes a post that has replies | `outcome: tombstone`; `status = 'deleted'`, `text = '[deleted]'`, `image_url` NULL; replies still there; B can still open the thread and sees "Deleted by author · N replies" at the top |
| A deletes a post that has a report and no replies | `outcome: tombstone` (never hard) |
| A deletes a post a moderator removed | Error `removed` |
| B (signed in as B) selects the tombstoned post | Visible. B selects A's `under_review` post | Not visible |
| A deletes a reply that has replies under it | `outcome: tombstone`; children still render; row shows "Deleted by author" |
| A deletes a leaf reply | `outcome: hard`; the post's `reply_count` drops by one |

## 6. App implementation

| Status | File | What |
|---|---|---|
| New | `Supabase/00024_edits_and_deletes.sql` | Migration (Part 4) |
| New | `BlockTalk/Services/ContentEditingService.swift` | The four RPC calls and their result types |
| New | `BlockTalk/Views/Modals/EditTextSheet.swift` | Edit sheet: prefilled text, counter, hate-speech gate, Save |
| New | `BlockTalk/Views/Modals/EditHistorySheet.swift` | "What it said / what it says now" |
| New | `BlockTalkTests/AppState/ContentEditStoreTests.swift` | 8 tests on the session store and reply tree helpers |
| Edit | `BlockTalk/App/AppState.swift` | `ContentEditStore`: session record of your edits and deletes so every list showing the item updates instantly, no refetch |
| Edit | `BlockTalk/App/BlockTalkApp.swift` | Injects `ContentEditStore` everywhere the other stores go |
| Edit | `BlockTalk/Models/Post.swift`, `Reply.swift` | `text` is now `var`; new optional `originalText`, `editedAt`, `editCount`; `PostStatus.deleted`; `Reply.status` and `ReplyStatus`; `Reply.descendantCount` |
| Edit | `BlockTalk/Views/Components/Tombstone.swift` | `.deleted` variant ("Deleted by author · N replies", dashed border, no author, no votes) and `ReplyDeletedRow` |
| Edit | `BlockTalk/Views/Components/PostCard.swift` | Owner ellipsis menu (Edit / Delete), confirm alert, "edited" in the action row as a dotted-underline tap target, tombstone in Post Detail, hard-deleted posts render nothing until the list refetches |
| Edit | `BlockTalk/Views/Detail/ReplyNode.swift` | Same for replies; a tombstoned reply keeps its children |
| Edit | `BlockTalk/Views/Detail/PostDetailView.swift` | A deleted post still shows its thread; the reply box stays hidden; the screen dismisses if you hard-delete the post you're on |
| Edit | `BlockTalk/Views/Modals/NotificationsView.swift` | A notification about a now-deleted post opens its thread instead of "no longer available" |

Where the "edited" tag sits: in the action row next to the time, `2h · edited · 7 replies` on posts and `2h · edited` on replies. Dotted underline, `btText3`, `btLine2` underline. Quiet by design: a footnote, not an accusation.

## 7. Deployment order

1. Push the code.
2. Garrett runs `00024_edits_and_deletes.sql` and the checks in Part 5.
3. Build.

Unlike the Authority migration, the app does not break if this one lags: the new columns are optional in the models, so posts and replies still decode without them. What breaks is only the new feature itself: Edit and Delete would fail with "function does not exist" until the migration runs. The `ReplyStatus` decode is the one exception to watch: `replies.status` is `NOT NULL DEFAULT 'live'`, and the Swift field is optional, so both before and after the migration decode fine.

## 8. Decisions that differ from the artifact

| Artifact said | This build does | Why |
|---|---|---|
| Migration `00023_edits_and_deletes.sql` | `00024` | `00023` is Authority Tiers |
| Moderation removal reverses aura | Nothing touches aura, ever | Cut on 2026-09-17; see `AUTHORITY_TIERS_SPEC.md` |
| Tombstone on "an open report" | Tombstone if any report exists, or status is `under_review` | `reports` has no open/closed state; a report that exists is the evidence that must survive |
| Edit re-runs the language check server-side | Client-side, same gate as compose | `LanguageCheck` is Swift; there is no server-side check for new posts today either |
| "Deleted by author" tombstone appears wherever the post renders | Only in Post Detail; feed and board rows render nothing until their next refetch | Feed queries filter `status = 'live'`, so a deleted post disappears from lists anyway; showing a tombstone card in a feed you'd then refresh out of is confusing |
| Delete on a moderator-removed post | Refused with a message | The removal notice and the appeal path must stay; deleting would erase both and the strike evidence |
| Undo toast after delete | Not built | Optional in the artifact; see Part 9 |

## 9. Not built

- **Undo toast** after delete. Cheap on the tombstone branch, needs deferred row removal on the hard-delete branch. Follow-up if wanted.
- **Admin dashboard** awareness of `deleted` status. The moderation queue still sees tombstoned rows because they keep their reports; the dashboard just doesn't label them as author-deleted yet.
- **Report on a reply.** `ReportModalView` is called for replies with `postId: reply.id` today, which the `reports` table can't store. Pre-existing gap, unrelated to this work.
