#!/usr/bin/env bash

set -euo pipefail

log() {
  printf '[rewrite-history] %s\n' "$*"
}

error() {
  printf '[rewrite-history] ERROR: %s\n' "$*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
Rewrite git history into a single fresh commit and force-push it to remote.

Usage:
  scripts/rewrite-git-history.sh [options]

Options:
  --remote <name>                 Remote name. Default: origin
  --target-branch <branch>        Branch to overwrite. Default: auto detect
  --commit-message <message>      Commit message for the new root commit
                                  Default: chore: reset history
  --delete-remote-branches        Delete all remote branches except target (default)
  --keep-remote-branches          Keep remote branches
  --delete-remote-tags            Delete all remote tags (default)
  --keep-remote-tags              Keep remote tags
  --allow-dirty                   Allow running with a dirty working tree
  --yes                           Skip interactive confirmation
  --dry-run                       Print commands without executing
  -h, --help                      Show this help message

Examples:
  scripts/rewrite-git-history.sh --target-branch main --yes
  scripts/rewrite-git-history.sh --dry-run --target-branch main
EOF
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || error "Required command not found: $1"
}

run() {
  if [ "$DRY_RUN" = "true" ]; then
    printf '+ '
    printf '%q ' "$@"
    printf '\n'
    return 0
  fi
  "$@"
}

REMOTE='origin'
TARGET_BRANCH=''
COMMIT_MESSAGE='chore: reset history'
DELETE_REMOTE_BRANCHES='true'
DELETE_REMOTE_TAGS='true'
ALLOW_DIRTY='false'
ASSUME_YES='false'
DRY_RUN='false'

while [ "$#" -gt 0 ]; do
  case "$1" in
    --remote)
      [ "$#" -ge 2 ] || error "Missing value for --remote"
      REMOTE="$2"
      shift 2
      ;;
    --target-branch)
      [ "$#" -ge 2 ] || error "Missing value for --target-branch"
      TARGET_BRANCH="$2"
      shift 2
      ;;
    --commit-message)
      [ "$#" -ge 2 ] || error "Missing value for --commit-message"
      COMMIT_MESSAGE="$2"
      shift 2
      ;;
    --delete-remote-branches)
      DELETE_REMOTE_BRANCHES='true'
      shift
      ;;
    --keep-remote-branches)
      DELETE_REMOTE_BRANCHES='false'
      shift
      ;;
    --delete-remote-tags)
      DELETE_REMOTE_TAGS='true'
      shift
      ;;
    --keep-remote-tags)
      DELETE_REMOTE_TAGS='false'
      shift
      ;;
    --allow-dirty)
      ALLOW_DIRTY='true'
      shift
      ;;
    --yes)
      ASSUME_YES='true'
      shift
      ;;
    --dry-run)
      DRY_RUN='true'
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      error "Unknown option: $1"
      ;;
  esac
done

require_cmd git
require_cmd awk
require_cmd sed

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || error 'Current directory is not a git repository'
git remote get-url "$REMOTE" >/dev/null 2>&1 || error "Remote does not exist: $REMOTE"

if [ -z "$TARGET_BRANCH" ]; then
  REMOTE_HEAD="$(git symbolic-ref --quiet --short "refs/remotes/${REMOTE}/HEAD" 2>/dev/null || true)"
  if [ -n "$REMOTE_HEAD" ]; then
    TARGET_BRANCH="${REMOTE_HEAD#${REMOTE}/}"
  else
    TARGET_BRANCH="$(git symbolic-ref --quiet --short HEAD 2>/dev/null || true)"
  fi
fi

[ -n "$TARGET_BRANCH" ] || error 'Unable to detect target branch. Please pass --target-branch'

if [ "$ALLOW_DIRTY" = 'false' ] && [ -n "$(git status --porcelain)" ]; then
  error 'Working tree is dirty. Commit/stash changes or pass --allow-dirty'
fi

log "Remote: ${REMOTE}"
log "Target branch: ${TARGET_BRANCH}"
log "Delete remote branches: ${DELETE_REMOTE_BRANCHES}"
log "Delete remote tags: ${DELETE_REMOTE_TAGS}"
log "Dry run: ${DRY_RUN}"

if [ "$ASSUME_YES" = 'false' ] && [ -z "${CI:-}" ]; then
  printf 'Type "rewrite" to continue: '
  read -r CONFIRM
  [ "$CONFIRM" = 'rewrite' ] || error 'Cancelled'
fi

TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
TMP_BRANCH="history-rewrite-${TIMESTAMP}"
PREV_REF="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)"

if [ -z "$PREV_REF" ]; then
  PREV_REF='HEAD'
fi

log 'Creating orphan branch and fresh root commit'
run git checkout --orphan "$TMP_BRANCH"
run git add -A

if [ "$DRY_RUN" = 'false' ] && git diff --cached --quiet; then
  error 'No files staged for commit. Nothing to rewrite'
fi

run git commit -m "$COMMIT_MESSAGE"
run git branch -f "$TARGET_BRANCH" "$TMP_BRANCH"
run git checkout "$TARGET_BRANCH"
run git branch -D "$TMP_BRANCH"

log "Force pushing ${TARGET_BRANCH} to ${REMOTE}"
run git push "$REMOTE" "${TARGET_BRANCH}:${TARGET_BRANCH}" --force

if [ "$DELETE_REMOTE_BRANCHES" = 'true' ]; then
  if [ "$DRY_RUN" = 'true' ]; then
    log "Dry run: would delete all remote branches on ${REMOTE} except ${TARGET_BRANCH}"
  else
    log 'Deleting remote branches except target branch'
    while IFS= read -r BRANCH; do
      [ -z "$BRANCH" ] && continue
      [ "$BRANCH" = "$TARGET_BRANCH" ] && continue
      run git push "$REMOTE" --delete "$BRANCH"
    done < <(git ls-remote --heads "$REMOTE" | awk '{print $2}' | sed 's#refs/heads/##')
  fi
fi

if [ "$DELETE_REMOTE_TAGS" = 'true' ]; then
  if [ "$DRY_RUN" = 'true' ]; then
    log "Dry run: would delete all remote tags on ${REMOTE}"
  else
    log 'Deleting all remote tags'
    while IFS= read -r TAG; do
      [ -z "$TAG" ] && continue
      run git push "$REMOTE" --delete "refs/tags/${TAG}"
    done < <(git ls-remote --tags --refs "$REMOTE" | awk '{print $2}' | sed 's#refs/tags/##')
  fi
fi

if [ "$DRY_RUN" = 'false' ] && [ -n "$PREV_REF" ] && [ "$PREV_REF" != 'HEAD' ] && [ "$PREV_REF" != "$TARGET_BRANCH" ]; then
  run git checkout "$PREV_REF"
fi

log 'History rewrite completed.'
log 'Collaborators must re-clone the repository after this operation.'
