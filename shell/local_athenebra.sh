#! /bin/env bash
# Athenebra helpers for TheGBeast (bash and zsh). Machine-specific, untracked.
#
#   ath                  cd to the repo
#   ath-lint             ruff, ruff format --check, mypy (offline)
#   ath-test [args]      pytest with test.env (integration tests included)
#   ath-check            ath-lint + ath-test: what CI runs
#   ath-apply P...       git apply --check all patches, apply them, uv sync, ath-check
#   ath-migrate          db upgrade as owner, re-run roles.sql, alembic check
#   ath-snapshot         live data snapshot, console logs, prints the exit code
#   ath-qc [--as-of T]   data-quality gates
#   ath-status           row counts and freshness per table
#   ath-psql [role]      psql into athenebra (default role: athenebra_ro)
#   ath-sql 'SELECT ..'  one read-only query
#   ath-raw ID|SHA       first bytes of a stored raw response (ID: messageId or fetch_id)
#   ath-logs             journal of the snapshot service
#
# Override the paths below in local_changes.sh if they move.

: "${ATHENEBRA_DIR:=$HOME/Project/Athenebra}"
: "${ATHENEBRA_CONF:=$HOME/.config/athenebra}"
: "${ATHENEBRA_ROLES_SQL:=$ATHENEBRA_DIR/patches/ops/postgres/roles.sql}"
: "${ATHENEBRA_SNAPSHOTS:=$HOME/.local/share/athenebra/snapshots}"

# Run a command in the repo with one env file loaded: _ath_with <app|migrate|test> cmd...
# For app and migrate the file is also the credentials file (ATHENEBRA_ENV_FILE);
# tests get only its variables, so config tests see the repo defaults.
_ath_with() {
    local kind="$1" f="$ATHENEBRA_CONF/$1.env"
    [ "$kind" = app ] && f="$ATHENEBRA_CONF/env"
    shift
    if [ ! -r "$f" ]; then
        echo "ath: missing $f" >&2
        return 2
    fi
    (
        cd "$ATHENEBRA_DIR" || exit 2
        set -a
        # shellcheck source=/dev/null
        . "$f"
        set +a
        if [ "$kind" != test ]; then
            export ATHENEBRA_ENV_FILE="$f"
            export ATHENEBRA_LOGGING__FORMAT="${ATHENEBRA_LOGGING__FORMAT:-console}"
        fi
        "$@"
    )
}

ath() {
    cd "$ATHENEBRA_DIR" || return
}

ath-lint() {
    (cd "$ATHENEBRA_DIR" && uv run ruff check && uv run ruff format --check && uv run mypy)
}

ath-test() {
    _ath_with test uv run pytest -q "$@"
}

# shellcheck disable=SC2120
ath-check() {
    ath-lint && ath-test "$@" && echo "ath: all checks passed"
}

ath-apply() {
    if [ $# -eq 0 ]; then
        echo "usage: ath-apply patches/00NN-*.diff ..." >&2
        return 2
    fi
    local p
    for p in "$@"; do
        p=$(realpath "$p") || return
        git -C "$ATHENEBRA_DIR" apply --check "$p" || {
            echo "ath: $p does not apply; nothing changed" >&2
            return 1
        }
    done
    for p in "$@"; do
        git -C "$ATHENEBRA_DIR" apply "$(realpath "$p")" && echo "applied $p"
    done
    (cd "$ATHENEBRA_DIR" && uv sync -q) && ath-check
}

ath-migrate() {
    _ath_with migrate uv run athenebra db upgrade || return
    # shellcheck disable=SC2024  # the file is readable by us; psql runs as postgres
    sudo -u postgres psql -X -q -v ON_ERROR_STOP=1 < "$ATHENEBRA_ROLES_SQL" || return
    _ath_with migrate uv run alembic check
}

ath-snapshot() {
    mkdir -p "$ATHENEBRA_SNAPSHOTS"
    _ath_with app uv run athenebra data snapshot "$@"
    local rc=$?
    echo "ath: snapshot exit $rc (0 ok, 1 partial: see 'failed:' lines)"
    return $rc
}

ath-qc() {
    _ath_with app uv run athenebra data check "$@"
}

ath-psql() {
    psql -h localhost -U "${1:-athenebra_ro}" athenebra
}

ath-sql() {
    psql -h localhost -U athenebra_ro -X -P pager=off athenebra -c "$1"
}

ath-status() {
    ath-sql "
SELECT 'raw_snapshots' AS tbl, count(*) AS n, max(fetched_at)::text AS latest FROM raw_snapshots
UNION ALL SELECT 'listings open', count(*), max(last_seen_on)::text FROM listings WHERE listed_to IS NULL
UNION ALL SELECT 'prices', count(*), max(trade_date)::text FROM prices
UNION ALL SELECT 'corporate_actions', count(*), max(known_at)::text FROM corporate_actions
UNION ALL SELECT 'quality_issues', count(*), max(as_of)::text FROM quality_issues
UNION ALL SELECT 'model_runs', count(*), max(started_at)::text FROM model_runs;"
    ath-sql "SELECT source, http_status, count(*) FROM raw_snapshots GROUP BY 1, 2 ORDER BY 1, 2;"
}

ath-raw() {
    local sha="$1"
    case "$sha" in
        '' ) echo "usage: ath-raw <fetch_id|sha256> [bytes]" >&2; return 2 ;;
        *[!0-9]* ) ;;
        # A number is a Newsweb messageId if one matches, else a fetch_id.
        * ) sha=$(psql -h localhost -U athenebra_ro -XAt athenebra -c "
                SELECT sha256 FROM raw_snapshots
                WHERE params->>'messageId' = '$sha' OR fetch_id = $sha
                ORDER BY (params->>'messageId' = '$sha') DESC NULLS LAST, fetch_id DESC
                LIMIT 1") || return ;;
    esac
    if [ -z "$sha" ]; then
        echo "ath-raw: no stored body for $1" >&2
        return 1
    fi
    local cut
    cut=$(printf %.2s "$sha")
    zcat "$ATHENEBRA_SNAPSHOTS/$cut/$sha.gz" | head -c "${2:-2000}"
    echo
}

ath-logs() {
    journalctl -u athenebra-snapshot.service -n "${1:-100}" --no-pager
}
