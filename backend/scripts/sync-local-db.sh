#!/usr/bin/env bash
# Brings the local Postgres copy in line with Supabase:
#   1. applies any pending Prisma migrations to Supabase and to local
#   2. replaces local data with a fresh copy of Supabase's data
# Supabase is the source of truth (both the local and the online app use it).
# Needs DIRECT_URL, SUPABASE_URL and LOCAL_DATABASE_URL in backend/.env and
# the PostgreSQL 17 client tools.
set -euo pipefail

cd "$(dirname "$0")/.."
export PATH="/c/Program Files/PostgreSQL/17/bin:$PATH"

env_get() {
  node -e 'require("dotenv").config({quiet:true});process.stdout.write(process.env[process.argv[1]]||"")' "$1"
}

LOCAL_URL="$(env_get LOCAL_DATABASE_URL | sed -E 's/\?.*$//')"
SUPA_URL="$(env_get SUPABASE_URL)?connect_timeout=60"
[ -n "$LOCAL_URL" ] && [ -n "$(env_get SUPABASE_URL)" ] || { echo "LOCAL_DATABASE_URL / SUPABASE_URL missing in .env" >&2; exit 1; }

echo "== Migrations: Supabase"
npx prisma migrate deploy
echo "== Migrations: local"
DATABASE_URL="$LOCAL_URL" DIRECT_URL="$LOCAL_URL" npx prisma migrate deploy

echo "== Backup of local data before replacing it"
mkdir -p db-backups
BACKUP="db-backups/local-$(date +%Y%m%d-%H%M%S).dump"
pg_dump "$LOCAL_URL" -Fc -f "$BACKUP"
echo "saved $BACKUP (restore: pg_restore --clean -d <local url> $BACKUP)"

echo "== Data: Supabase -> local"
DUMP="$(mktemp)"
trap 'rm -f "$DUMP"' EXIT
pg_dump "$SUPA_URL" --data-only --schema=public \
  --exclude-table='public._prisma_migrations' --no-owner --no-privileges \
  --rows-per-insert=50 -f "$DUMP"

TABLES="$(psql "$LOCAL_URL" -Atc "select string_agg(format('public.%I', tablename), ', ')
  from pg_tables where schemaname='public' and tablename<>'_prisma_migrations'")"

{
  echo "BEGIN;"
  echo "TRUNCATE $TABLES RESTART IDENTITY CASCADE;"
  echo "SET LOCAL session_replication_role = replica;"
  cat "$DUMP"
  echo "COMMIT;"
} | psql "$LOCAL_URL" -v ON_ERROR_STOP=1 -q -o /dev/null

echo "== Row counts (local | supabase)"
COUNT_SQL="select string_agg(format('select %L t, count(*) n from public.%I', tablename, tablename), ' union all ' order by tablename)
  from pg_tables where schemaname='public' and tablename<>'_prisma_migrations'"
diff <(psql "$LOCAL_URL" -At -F' ' -c "$(psql "$LOCAL_URL" -Atc "$COUNT_SQL") order by 1") \
     <(psql "$SUPA_URL" -At -F' ' -c "$(psql "$SUPA_URL" -Atc "$COUNT_SQL") order by 1") \
  && echo "local matches Supabase"
