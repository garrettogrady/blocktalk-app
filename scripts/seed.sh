#!/bin/bash
# ============================================================
# BlockTalk: One-shot database seed
# Cleans all mock data and re-seeds users, posts, pins, replies, daily prompt.
# Uses psql against your Supabase project's direct connection string.
#
# Usage:
#   ./scripts/seed.sh
#   ./scripts/seed.sh "postgresql://postgres.xxx:password@host:5432/postgres"
#
# If no connection string is passed, it reads from SUPABASE_DB_URL env var.
# Find your connection string in: Supabase Dashboard → Settings → Database → Connection string → URI
# Use the "direct" connection (port 5432), not the pooler.
# ============================================================

set -euo pipefail

DB_URL="${1:-${SUPABASE_DB_URL:-}}"

if [ -z "$DB_URL" ]; then
  echo "Error: No database connection string provided."
  echo ""
  echo "Usage:"
  echo "  ./scripts/seed.sh \"postgresql://postgres.[ref]:[password]@aws-0-[region].pooler.supabase.com:5432/postgres\""
  echo ""
  echo "Or set SUPABASE_DB_URL:"
  echo "  export SUPABASE_DB_URL=\"postgresql://...\""
  echo "  ./scripts/seed.sh"
  echo ""
  echo "Find your connection string in:"
  echo "  Supabase Dashboard → Settings → Database → Connection string (URI)"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "==> Seeding BlockTalk database..."
echo ""

# Run seed_mock.sql (users, posts, pins, daily prompt)
echo "[1/2] Seeding users, posts, pins, daily prompt..."
psql "$DB_URL" -f "$SCRIPT_DIR/seed_mock.sql" -v ON_ERROR_STOP=1

echo ""

# Run seed_replies.sql (reply threads)
echo "[2/2] Seeding reply threads..."
psql "$DB_URL" -f "$SCRIPT_DIR/seed_replies.sql" -v ON_ERROR_STOP=1

echo ""
echo "==> Done! Seeded:"
echo "    • 14 mock users (auth + public)"
echo "    • 34 LES posts (29 regular + 5 street comments)"
echo "    • 5 pins (LES corners)"
echo "    • 1 active daily prompt"
echo "    • 112 replies (74 root + 33 children + 5 grandchildren)"
