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

# Append a row to a markdown table section in progress.md
# Usage: append_table_row "section_header" "col1" "col2" ...
append_table_row() {
    local section="$1"; shift
    local row="| $(printf '%s | ' "$@")"
    row="${row% | }"  # trim trailing " | "

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
    local DATE=$(kst_date)
    local TIME=$(kst_time)
    local JIRA_KEY=$(echo "$BRANCH_NAME" | grep -oE '^[a-zA-Z]+-[0-9]+' | tr '[:lower:]' '[:upper:]' || echo "")

    echo "=== Analyze Requirements Init ==="
    echo "Branch: $BRANCH_NAME"
    echo "Jira Key: ${JIRA_KEY:-N/A}"
    echo "Target Dir: $DOCS_DIR"
    echo ""

    mkdir -p "$INVESTIGATION_DIR"

    # Create progress.md
    if [ ! -f "$DOCS_DIR/progress.md" ]; then
        cat > "$DOCS_DIR/progress.md" << EOF
# 분석 진행 상황

> 브랜치: \`$BRANCH_NAME\`
> Jira: ${JIRA_KEY:-N/A}
> 시작: $DATE $TIME

## 체크리스트

### Phase 1: 컨텍스트 수집
- [ ] Jira 티켓 정보 수집 → context.md
- [ ] 사용자 초기 요구사항 확인
- **Status:** in_progress

### Phase 2: 조사 (subagent 활용)
- [ ] 관련 코드 분석 → investigation/code-analysis.md
- [ ] 영향 범위 분석 → investigation/impact-analysis.md
- **Status:** pending

### Phase 3: 요구사항 구체화
- [ ] 핵심 요구사항 정리 → requirements.md
- [ ] 결정 사항 기록 → decisions.md
- **Status:** pending

### Phase 4: 솔루션 도출
- [ ] 옵션 검토 및 권장안 → solution.md
- **Status:** pending

### Phase 5: 피드백 루프
- [ ] 초기 결과물 리뷰 요청
- **Status:** pending
- **Iterations:** 0

## 피드백 기록
| 시간 | 대상 | 피드백 내용 | 반영 상태 |
|------|------|-------------|----------|

## 진행 로그
| 시간 | 작업 | 결과 |
|------|------|------|
| $TIME | 분석 시작 | 폴더 구조 생성 |
EOF
        echo "Created: $DOCS_DIR/progress.md"
    else
        echo "Exists: $DOCS_DIR/progress.md"
    fi

    # Template files: name -> content
    local -a files=(context decisions requirements solution)

    if [ ! -f "$DOCS_DIR/context.md" ]; then
        cat > "$DOCS_DIR/context.md" << EOF
# 컨텍스트

## Jira 티켓
- **키:** ${JIRA_KEY:-TBD}
- **제목:**
- **상태:**
- **담당자:**

## 티켓 설명
[Jira description 내용을 여기에 기록]

## 주요 코멘트
[중요 코멘트 요약]

## 관련 링크
- Jira: ${JIRA_KEY:+https://jira.example.com/browse/$JIRA_KEY}

## 사용자 피드백
[분석 과정에서 받은 사용자 피드백 기록]
EOF
        echo "Created: $DOCS_DIR/context.md"
    else
        echo "Exists: $DOCS_DIR/context.md"
    fi

    if [ ! -f "$DOCS_DIR/decisions.md" ]; then
        cat > "$DOCS_DIR/decisions.md" << EOF
# 결정 사항

## 확정된 결정
| 일시 | 항목 | 결정 내용 | 근거 |
|------|------|----------|------|

## 미결정 사항
| 항목 | 옵션들 | 권장 | 상태 |
|------|--------|------|------|

## 결정 로그
[결정 과정에서의 논의 사항 기록]
EOF
        echo "Created: $DOCS_DIR/decisions.md"
    else
        echo "Exists: $DOCS_DIR/decisions.md"
    fi

    if [ ! -f "$DOCS_DIR/requirements.md" ]; then
        cat > "$DOCS_DIR/requirements.md" << EOF
# 요구사항

## 핵심 요구사항
1.

## 비기능 요구사항
- 성능:
- 호환성:
- 보안:

## 제약 조건
-

## 수용 기준 (Acceptance Criteria)
- [ ]
EOF
        echo "Created: $DOCS_DIR/requirements.md"
    else
        echo "Exists: $DOCS_DIR/requirements.md"
    fi

    if [ ! -f "$DOCS_DIR/solution.md" ]; then
        cat > "$DOCS_DIR/solution.md" << EOF
# 제안 솔루션

## 아키텍처 개요
[다이어그램 또는 흐름 설명]

## 검토한 옵션
| 옵션 | 설명 | 장점 | 단점 |
|------|------|------|------|

## 권장안
[선택한 옵션과 이유]

## 구현 계획
### Phase 1:
### Phase 2:

## 데이터 일관성 고려사항
[비동기/재처리 로직이 있는 경우]

## 리스크 및 완화 방안
| 리스크 | 영향 | 완화 방안 |
|--------|------|----------|
EOF
        echo "Created: $DOCS_DIR/solution.md"
    else
        echo "Exists: $DOCS_DIR/solution.md"
    fi

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
    local DATE=$(kst_date)
    local TIME=$(kst_time)

    # Create investigation file
    if [ ! -f "$FILEPATH" ]; then
        mkdir -p "$INVESTIGATION_DIR"
        cat > "$FILEPATH" << EOF
# $DESCRIPTION

> 생성: $DATE $TIME
> 상태: 조사 중

## 요약
[조사 결과 요약]

## 상세 분석
[상세 분석 내용]

## 관련 파일
-

## 발견 사항
-

## 결론
[결론 및 권장 사항]
EOF
        echo "Created: $FILEPATH"
    else
        echo "Exists: $FILEPATH"
    fi

    # Add to Phase 2 checklist
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

    # Parse arguments
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
        echo ""
        echo "Examples:"
        echo "  $0 feedback --type context \"API 응답 형식 확인 필요\""
        echo "  $0 feedback --type investigation -i code-analysis \"캐시 로직 추가 검토\""
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

    # Add feedback to target file
    if [ -n "$TARGET_FILE" ] && [ -f "$TARGET_FILE" ]; then
        if ! grep -q "## $SECTION" "$TARGET_FILE"; then
            echo "" >> "$TARGET_FILE"
            echo "## $SECTION" >> "$TARGET_FILE"
        fi
        echo "- [$TIME] $FEEDBACK" >> "$TARGET_FILE"
        echo "Added to: $TARGET_FILE (## $SECTION)"
    fi

    # Add to feedback log table
    local DISPLAY_TARGET=$(basename "${TARGET_FILE:-progress.md}")
    local FEEDBACK_SHORT="${FEEDBACK:0:50}"
    append_table_row "피드백 기록" "$TIME" "$DISPLAY_TARGET" "$FEEDBACK_SHORT..." "pending"

    # Add to progress log
    add_progress_log "피드백 추가: $DISPLAY_TARGET"

    # Increment iteration count
    local CURRENT_ITER=$(grep '\*\*Iterations:\*\*' "$PROGRESS_FILE" | sed 's/.*\*\*Iterations:\*\* \([0-9]*\).*/\1/' || echo "0")
    CURRENT_ITER=${CURRENT_ITER:-0}
    local NEW_ITER=$((CURRENT_ITER + 1))
    sed_inplace "s/\*\*Iterations:\*\* $CURRENT_ITER/\*\*Iterations:\*\* $NEW_ITER/" "$PROGRESS_FILE"

    # Activate Phase 5 if pending
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
            # List then prompt
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
