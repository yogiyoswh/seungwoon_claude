#!/bin/bash
# analyze.sh - Unified CLI for analyze-requirements workflow
# Usage: analyze.sh <command> [args...]
#
# Commands:
#   init                              Initialize folder structure
#   check                             Check progress status
#   update "item text" [done|todo]    Mark checklist item
#   phase N [complete|in_progress|pending]  Update phase status
#   log "message" [result]            Add progress log entry
#   investigate "name" ["description"] Add investigation item
#   feedback --type <type> "content"  Add feedback
#   feedback-done [N|--all]           Mark feedback as done

set -e

# ============================================================
# Common setup
# ============================================================

BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown-branch")
DOCS_DIR="docs/${BRANCH_NAME}"
PROGRESS_FILE="$DOCS_DIR/progress.md"
INVESTIGATION_DIR="$DOCS_DIR/investigation"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/../templates"

kst_date() { TZ='Asia/Seoul' date +%Y-%m-%d; }
kst_time() { TZ='Asia/Seoul' date +%H:%M:%S; }

require_progress() {
    if [ ! -f "$PROGRESS_FILE" ]; then
        echo "ERROR: $PROGRESS_FILE not found"
        echo "Run: bash $0 init"
        exit 1
    fi
}

sed_inplace() {
    sed -i.bak "$@"
    local target="${@: -1}"
    rm -f "${target}.bak"
}

# Fill template placeholders and write to target
# Usage: fill_template "template_name" "target_path"
fill_template() {
    local template="$TEMPLATE_DIR/$1"
    local target="$2"
    local JIRA_KEY=$(echo "$BRANCH_NAME" | grep -oE '^[a-zA-Z]+-[0-9]+' | tr '[:lower:]' '[:upper:]' || echo "")

    if [ ! -f "$template" ]; then
        echo "ERROR: Template not found: $template"
        return 1
    fi

    sed \
        -e "s|__BRANCH__|$BRANCH_NAME|g" \
        -e "s|__JIRA_KEY__|${JIRA_KEY:-N/A}|g" \
        -e "s|__DATE__|$(kst_date)|g" \
        -e "s|__TIME__|$(kst_time)|g" \
        -e "s|__JIRA_URL__|${JIRA_KEY:+https://jira.example.com/browse/$JIRA_KEY}|g" \
        "$template" > "$target"
}

# Append a row to a markdown table section in progress.md
append_table_row() {
    local section="$1"; shift
    local row="| $(printf '%s | ' "$@")"
    row="${row% | }"

    awk -v section="$section" -v row="$row" '
        $0 ~ "^## " section { in_section=1 }
        in_section && /^\|.*\|$/ { last_table_line=NR }
        in_section && /^## / && $0 !~ "^## " section { in_section=0 }
        { lines[NR]=$0 }
        END {
            for(i=1; i<=NR; i++) {
                print lines[i]
                if(i == last_table_line) print row
            }
        }
    ' "$PROGRESS_FILE" > "$PROGRESS_FILE.tmp" && mv "$PROGRESS_FILE.tmp" "$PROGRESS_FILE"
}

add_progress_log() {
    local msg="$1"
    local result="${2:--}"
    append_table_row "진행 로그" "$(kst_time)" "$msg" "$result"
}

# ============================================================
# Commands
# ============================================================

cmd_init() {
    echo "=== Analyze Requirements Init ==="
    echo "Branch: $BRANCH_NAME"
    echo "Target Dir: $DOCS_DIR"
    echo ""

    mkdir -p "$INVESTIGATION_DIR"

    local templates=(progress context decisions requirements solution)
    for name in "${templates[@]}"; do
        if [ ! -f "$DOCS_DIR/${name}.md" ]; then
            fill_template "${name}.md" "$DOCS_DIR/${name}.md"
            echo "Created: $DOCS_DIR/${name}.md"
        else
            echo "Exists: $DOCS_DIR/${name}.md"
        fi
    done

    echo ""
    echo "=== Init Complete ==="
    echo "Docs: $DOCS_DIR/"
    echo "Files: progress.md, context.md, decisions.md, requirements.md, solution.md"
    echo "Investigation: $INVESTIGATION_DIR/"
}

cmd_check() {
    require_progress

    echo "=== Analyze Requirements: Progress Check ==="
    echo "Branch: $BRANCH_NAME"
    echo "File: $PROGRESS_FILE"
    echo ""

    local TOTAL=$(grep -c "### Phase" "$PROGRESS_FILE" 2>/dev/null) || TOTAL=0
    local COMPLETE=$(grep -cF "**Status:** complete" "$PROGRESS_FILE" 2>/dev/null) || COMPLETE=0
    local IN_PROGRESS=$(grep -cF "**Status:** in_progress" "$PROGRESS_FILE" 2>/dev/null) || IN_PROGRESS=0
    local PENDING=$(grep -cF "**Status:** pending" "$PROGRESS_FILE" 2>/dev/null) || PENDING=0

    local TOTAL_ITEMS=$(grep -c "^\- \[" "$PROGRESS_FILE" 2>/dev/null) || TOTAL_ITEMS=0
    local DONE_ITEMS=$(grep -c "^\- \[x\]" "$PROGRESS_FILE" 2>/dev/null) || DONE_ITEMS=0
    local TODO_ITEMS=$(grep -c "^\- \[ \]" "$PROGRESS_FILE" 2>/dev/null) || TODO_ITEMS=0

    echo "=== Phase Status ==="
    echo "Total phases:   $TOTAL"
    echo "Complete:       $COMPLETE"
    echo "In progress:    $IN_PROGRESS"
    echo "Pending:        $PENDING"
    echo ""

    echo "=== Checklist Status ==="
    echo "Total items:    $TOTAL_ITEMS"
    echo "Done:           $DONE_ITEMS"
    echo "Todo:           $TODO_ITEMS"
    echo ""

    if [ "$TODO_ITEMS" -gt 0 ]; then
        echo "=== Remaining Items ==="
        grep "^\- \[ \]" "$PROGRESS_FILE" | head -10
        echo ""
    fi

    if [ "$COMPLETE" -eq "$TOTAL" ] && [ "$TOTAL" -gt 0 ]; then
        echo "ALL PHASES COMPLETE"
    else
        echo "ANALYSIS NOT COMPLETE"
        echo ""
        echo "Complete all phases before finishing."
    fi
}

cmd_update() {
    require_progress
    local ITEM_TEXT="$1"
    local ACTION="${2:-done}"

    if [ -z "$ITEM_TEXT" ]; then
        echo "Usage: $0 update \"item text\" [done|todo]"
        exit 1
    fi

    case "$ACTION" in
        done)
            sed_inplace "s/- \[ \] $ITEM_TEXT/- [x] $ITEM_TEXT/" "$PROGRESS_FILE"
            echo "Marked as done: $ITEM_TEXT"
            ;;
        todo)
            sed_inplace "s/- \[x\] $ITEM_TEXT/- [ ] $ITEM_TEXT/" "$PROGRESS_FILE"
            echo "Marked as todo: $ITEM_TEXT"
            ;;
        *)
            echo "ERROR: Unknown action '$ACTION'. Use 'done' or 'todo'."
            exit 1
            ;;
    esac
    echo "Updated: $PROGRESS_FILE"
}

cmd_phase() {
    require_progress
    local PHASE_NUM="$1"
    local STATUS="${2:-complete}"

    if [ -z "$PHASE_NUM" ]; then
        echo "Usage: $0 phase N [complete|in_progress|pending]"
        exit 1
    fi

    sed_inplace -E "/### Phase $PHASE_NUM:/,/\*\*Status:\*\*/ s/\*\*Status:\*\* [a-z_]+/**Status:** $STATUS/" "$PROGRESS_FILE"
    echo "Updated Phase $PHASE_NUM to: $STATUS"
    echo "Updated: $PROGRESS_FILE"
}

cmd_log() {
    require_progress
    local MESSAGE="$1"
    local RESULT="${2:--}"

    if [ -z "$MESSAGE" ]; then
        echo "Usage: $0 log \"message\" [result]"
        exit 1
    fi

    add_progress_log "$MESSAGE" "$RESULT"
    echo "Added log entry: $MESSAGE"
}

cmd_investigate() {
    require_progress
    local NAME="$1"
    local DESCRIPTION="${2:-$NAME 분석}"

    if [ -z "$NAME" ]; then
        echo "Usage: $0 investigate \"name\" [description]"
        echo "Example: $0 investigate \"api-integration\" \"외부 API 연동 분석\""
        exit 1
    fi

    local FILENAME=$(echo "$NAME" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
    local FILEPATH="$INVESTIGATION_DIR/${FILENAME}.md"

    if [ ! -f "$FILEPATH" ]; then
        mkdir -p "$INVESTIGATION_DIR"
        sed \
            -e "s|__DESCRIPTION__|$DESCRIPTION|g" \
            -e "s|__DATE__|$(kst_date)|g" \
            -e "s|__TIME__|$(kst_time)|g" \
            "$TEMPLATE_DIR/investigation.md" > "$FILEPATH"
        echo "Created: $FILEPATH"
    else
        echo "Exists: $FILEPATH"
    fi

    if ! grep -q "$FILENAME.md" "$PROGRESS_FILE"; then
        sed_inplace "/### Phase 2:/,/\*\*Status:\*\*/ {
            /\*\*Status:\*\*/i\\
- [ ] $DESCRIPTION → investigation/${FILENAME}.md
        }" "$PROGRESS_FILE"
        echo "Added to checklist: $DESCRIPTION"
    fi

    add_progress_log "조사 항목 추가: $DESCRIPTION"

    echo ""
    echo "Investigation file: $FILEPATH"
    echo "Mark done: $0 update \"$DESCRIPTION\" done"
}

cmd_feedback() {
    require_progress

    local TYPE="general"
    local INVESTIGATION_NAME=""
    local FEEDBACK=""
    while [[ $# -gt 0 ]]; do
        case $1 in
            --type|-t) TYPE="$2"; shift 2 ;;
            --investigation|-i) INVESTIGATION_NAME="$2"; shift 2 ;;
            *) FEEDBACK="$1"; shift ;;
        esac
    done

    if [ -z "$FEEDBACK" ]; then
        echo "Usage: $0 feedback --type <type> \"content\""
        echo ""
        echo "Types: context, investigation, requirement, decision, general"
        exit 1
    fi

    local TIME=$(kst_time)
    local TARGET_FILE="" SECTION=""

    case $TYPE in
        context)
            TARGET_FILE="$DOCS_DIR/context.md"; SECTION="사용자 피드백" ;;
        investigation)
            if [ -z "$INVESTIGATION_NAME" ]; then
                echo "ERROR: --investigation <name> required for investigation type"
                exit 1
            fi
            local FILENAME=$(echo "$INVESTIGATION_NAME" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
            TARGET_FILE="$DOCS_DIR/investigation/${FILENAME}.md"
            if [ ! -f "$TARGET_FILE" ]; then
                echo "ERROR: Investigation file not found: $TARGET_FILE"
                exit 1
            fi
            SECTION="피드백"
            ;;
        requirement) TARGET_FILE="$DOCS_DIR/requirements.md"; SECTION="피드백" ;;
        decision)    TARGET_FILE="$DOCS_DIR/decisions.md"; SECTION="결정 로그" ;;
        general)     ;;
        *) echo "ERROR: Unknown type: $TYPE"; exit 1 ;;
    esac

    if [ -n "$TARGET_FILE" ] && [ -f "$TARGET_FILE" ]; then
        if ! grep -q "## $SECTION" "$TARGET_FILE"; then
            echo "" >> "$TARGET_FILE"
            echo "## $SECTION" >> "$TARGET_FILE"
        fi
        echo "- [$TIME] $FEEDBACK" >> "$TARGET_FILE"
        echo "Added to: $TARGET_FILE (## $SECTION)"
    fi

    local DISPLAY_TARGET=$(basename "${TARGET_FILE:-progress.md}")
    local FEEDBACK_SHORT="${FEEDBACK:0:50}"
    append_table_row "피드백 기록" "$TIME" "$DISPLAY_TARGET" "$FEEDBACK_SHORT..." "pending"
    add_progress_log "피드백 추가: $DISPLAY_TARGET"

    local CURRENT_ITER=$(grep '\*\*Iterations:\*\*' "$PROGRESS_FILE" | sed 's/.*\*\*Iterations:\*\* \([0-9]*\).*/\1/' || echo "0")
    CURRENT_ITER=${CURRENT_ITER:-0}
    local NEW_ITER=$((CURRENT_ITER + 1))
    sed_inplace "s/\*\*Iterations:\*\* $CURRENT_ITER/\*\*Iterations:\*\* $NEW_ITER/" "$PROGRESS_FILE"

    sed_inplace '/### Phase 5:/,/\*\*Status:\*\*/ {
        s/\*\*Status:\*\* pending/**Status:** in_progress/
    }' "$PROGRESS_FILE"

    echo ""
    echo "=== Feedback Added ==="
    echo "Type: $TYPE"
    echo "Content: $FEEDBACK"
    echo "Iteration: $NEW_ITER"
    [ -n "$TARGET_FILE" ] && echo "Target: $TARGET_FILE"
}

_mark_feedback_by_index() {
    local index=$1 current=0 line_num=0 target_line=0
    while IFS= read -r line; do
        line_num=$((line_num + 1))
        if [[ "$line" =~ \|.*\|.*\|.*\|.*pending.*\| ]]; then
            current=$((current + 1))
            [ $current -eq $index ] && { target_line=$line_num; break; }
        fi
    done < "$PROGRESS_FILE"

    if [ $target_line -eq 0 ]; then
        echo "ERROR: Feedback #$index not found"
        return 1
    fi
    sed_inplace "${target_line}s/| pending |/| done |/" "$PROGRESS_FILE"
    add_progress_log "피드백 #$index 반영 완료"
    echo "Marked feedback #$index as done"
}

cmd_feedback_done() {
    require_progress

    case "${1:-}" in
        --all|-a)
            sed_inplace 's/| pending |/| done |/g' "$PROGRESS_FILE"
            add_progress_log "모든 피드백 반영 완료"
            echo "Marked all feedbacks as done"
            ;;
        --list|-l)
            echo "=== Pending Feedbacks ==="
            local count=0
            while IFS= read -r line; do
                if [[ "$line" =~ \|.*\|.*\|.*\|.*pending.*\| ]]; then
                    count=$((count + 1))
                    local f_time=$(echo "$line" | cut -d'|' -f2 | xargs)
                    local f_target=$(echo "$line" | cut -d'|' -f3 | xargs)
                    local f_content=$(echo "$line" | cut -d'|' -f4 | xargs)
                    echo "[$count] $f_time | $f_target | $f_content"
                fi
            done < "$PROGRESS_FILE"
            [ $count -eq 0 ] && echo "No pending feedbacks found."
            echo "Total: $count pending feedback(s)"
            ;;
        [0-9]*)
            _mark_feedback_by_index "$1"
            ;;
        "")
            cmd_feedback_done --list
            echo ""
            read -p "Enter number to mark done (or 'all'/'q'): " choice
            case "$choice" in
                q|Q) echo "Cancelled." ;;
                all|ALL) cmd_feedback_done --all ;;
                [0-9]*) _mark_feedback_by_index "$choice" ;;
                *) echo "Invalid: $choice"; exit 1 ;;
            esac
            ;;
        *)
            echo "Usage: $0 feedback-done [N|--all|--list]"
            exit 1
            ;;
    esac
}

cmd_help() {
    echo "analyze.sh - Unified CLI for analyze-requirements"
    echo ""
    echo "Usage: $0 <command> [args...]"
    echo ""
    echo "Commands:"
    echo "  init                                Initialize folder structure"
    echo "  check                               Check progress status"
    echo "  update \"item\" [done|todo]            Mark checklist item"
    echo "  phase N [complete|in_progress|pending]  Update phase status"
    echo "  log \"message\" [result]               Add progress log entry"
    echo "  investigate \"name\" [\"description\"]    Add investigation item"
    echo "  feedback --type <type> \"content\"      Add feedback"
    echo "  feedback-done [N|--all|--list]       Mark feedback as done"
    echo "  help                                Show this help"
}

# ============================================================
# Dispatch
# ============================================================

COMMAND="${1:-help}"
shift 2>/dev/null || true

case "$COMMAND" in
    init)          cmd_init "$@" ;;
    check)         cmd_check "$@" ;;
    update)        cmd_update "$@" ;;
    phase)         cmd_phase "$@" ;;
    log)           cmd_log "$@" ;;
    investigate)   cmd_investigate "$@" ;;
    feedback)      cmd_feedback "$@" ;;
    feedback-done) cmd_feedback_done "$@" ;;
    help|--help|-h) cmd_help ;;
    *)
        echo "Unknown command: $COMMAND"
        echo "Run '$0 help' for usage."
        exit 1
        ;;
esac
