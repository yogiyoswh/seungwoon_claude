---
name: analyze-requirements
version: "1.0.0"
description: |
  요구사항 분석 및 문서화. Jira 티켓 기반으로 요구사항을 단계별로 구체화하고,
  조사 결과와 결정 사항을 파일에 기록하면서 진행합니다.
  /analyze-requirements 로 실행하거나, 요구사항 분석이 필요한 상황에서 자동 활성화.
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - Bash
  - Agent
  - AskUserQuestion
  - mcp__mcpyo__jira_get_ticket
  - mcp__mcpyo__jira_get_ticket_comments
hooks:
  PreToolUse:
    - matcher: "Write|Edit|Agent|Read|Glob|Grep|WebFetch"
      hooks:
        - type: command
          command: |
            BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
            PROGRESS="docs/${BRANCH}/progress.md"
            SCRIPT="${CLAUDE_PLUGIN_ROOT}/analyze-requirements/scripts/analyze.sh"
            if [ ! -f "$PROGRESS" ]; then
              echo ""
              echo "╔══════════════════════════════════════════════════════════════╗"
              echo "║  BLOCKED: analyze.sh init 먼저 실행 필요                    ║"
              echo "║  bash $SCRIPT init                                          ║"
              echo "║  progress.md가 없으면 다른 작업을 진행할 수 없습니다.       ║"
              echo "╚══════════════════════════════════════════════════════════════╝"
              echo ""
              exit 1
            fi
            echo "[analyze-requirements] Progress:"
            head -35 "$PROGRESS" 2>/dev/null || true
  PostToolUse:
    - matcher: "Write|Edit"
      hooks:
        - type: command
          command: |
            echo "[analyze-requirements] File updated."
            echo "If this completes a checklist item, update progress.md:"
            echo "  - Mark item: [ ] -> [x]"
            echo "  - Update phase status if all items done"
  Stop:
    - hooks:
        - type: command
          command: |
            bash "${CLAUDE_PLUGIN_ROOT}/analyze-requirements/scripts/analyze.sh" check
---

# Analyze Requirements

요구사항을 단계별로 구체화하고, 확인 내용을 파일에 기록하면서 진행합니다.
분석 결과는 `docs/{브랜치명}/` 폴더에 영역별로 분리하여 저장합니다.

## FIRST: Init

```bash
bash ${CLAUDE_PLUGIN_ROOT}/analyze-requirements/scripts/analyze.sh init
```

## Where Files Go

- **Templates** are in `${CLAUDE_PLUGIN_ROOT}/analyze-requirements/templates/`
- **분석 결과 파일**은 프로젝트의 `docs/{브랜치명}/` 에 생성

| Location | What Goes There |
|----------|-----------------|
| Plugin directory | Templates, scripts |
| `docs/{브랜치명}/` | progress.md, context.md, decisions.md, requirements.md, solution.md |

## 폴더 구조

```
docs/{브랜치명}/
├── progress.md           # 체크리스트 및 진행상황 (핵심 파일)
├── context.md            # Jira 티켓 정보 및 배경
├── investigation/        # 조사 결과 (subagent가 작성)
│   ├── code-analysis.md
│   ├── impact-analysis.md
│   └── ...
├── decisions.md          # 결정사항 기록 (확인 즉시 기록)
├── requirements.md       # 구체화된 요구사항
└── solution.md           # 최종 제안 솔루션
```

## Scripts

통합 CLI: `analyze.sh <command> [args...]`

| Command | Purpose | Usage |
|---------|---------|-------|
| `init` | 폴더 구조 및 파일 초기화 | `bash analyze.sh init` |
| `check` | 체크리스트 완료 상태 확인 | `bash analyze.sh check` |
| `update` | 체크리스트 항목 업데이트 | `bash analyze.sh update "항목" done` |
| `phase` | Phase 상태 변경 | `bash analyze.sh phase 2 complete` |
| `log` | 진행 로그 추가 | `bash analyze.sh log "메시지"` |
| `investigate` | 조사 항목 추가 | `bash analyze.sh investigate "name" "desc"` |
| `feedback` | 피드백 기록 | `bash analyze.sh feedback --type context "내용"` |
| `feedback-done` | 피드백 반영 완료 처리 | `bash analyze.sh feedback-done [번호\|--all]` |

## Templates

- [templates/progress.md](../../analyze-requirements/templates/progress.md) — 체크리스트 및 진행 로그
- [templates/context.md](../../analyze-requirements/templates/context.md) — Jira 컨텍스트
- [templates/decisions.md](../../analyze-requirements/templates/decisions.md) — 결정 사항
- [templates/requirements.md](../../analyze-requirements/templates/requirements.md) — 요구사항
- [templates/solution.md](../../analyze-requirements/templates/solution.md) — 솔루션
- [templates/investigation.md](../../analyze-requirements/templates/investigation.md) — 조사 항목

## 실행 절차

### Phase 1: 초기화 및 컨텍스트 수집

#### 1.1 Init 스크립트 실행
```bash
bash ${CLAUDE_PLUGIN_ROOT}/analyze-requirements/scripts/analyze.sh init
```

#### 1.2 Jira 정보 수집 → context.md
- 브랜치명에서 Jira 키 추출 (예: `order-8157-feature` → `ORDER-8157`)
- `jira_get_ticket`, `jira_get_ticket_comments`로 정보 수집
- `context.md`에 기록

#### 1.3 체크리스트 업데이트
```bash
bash ${CLAUDE_PLUGIN_ROOT}/analyze-requirements/scripts/analyze.sh update "Jira 티켓 정보 수집" done
```

### Phase 2: 조사 (Subagent 활용)

**중요: 조사 작업은 Agent tool로 subagent에게 위임하여 context 오염을 방지합니다.**

#### 2.1 조사 항목 추가
```bash
bash ${CLAUDE_PLUGIN_ROOT}/analyze-requirements/scripts/analyze.sh investigate "api-integration" "외부 API 연동 분석"
```

#### 2.2 Subagent로 조사 실행
```
Agent(subagent_type="Explore", prompt="""
[조사 내용 설명]

결과를 다음 파일에 작성해주세요:
docs/{브랜치명}/investigation/{파일명}.md
""")
```

#### 2.3 조사 완료 시 체크리스트 업데이트
```bash
bash ${CLAUDE_PLUGIN_ROOT}/analyze-requirements/scripts/analyze.sh phase 2 complete
```

### Phase 3: 요구사항 구체화 (사용자 상호작용)

#### 3.1 AskUserQuestion으로 요구사항 확인
- "어떤 문제를 해결하려고 하나요?" (배경/동기)
- "어떤 결과를 기대하나요?" (목표)
- "제약 조건이 있나요?" (성능, 호환성 등)

#### 3.2 decisions.md에 결정사항 즉시 기록

#### 3.3 requirements.md 작성

### Phase 4: 솔루션 도출

#### 4.1 solution.md 작성

#### 4.2 최종 체크
```bash
bash ${CLAUDE_PLUGIN_ROOT}/analyze-requirements/scripts/analyze.sh check
```

### Phase 5: 피드백 루프

#### 5.1 피드백 수집
```
"분석 결과를 확인해 주세요. 수정이나 보완이 필요한 부분이 있나요?"
```

#### 5.2 피드백 기록
```bash
bash ${CLAUDE_PLUGIN_ROOT}/analyze-requirements/scripts/analyze.sh feedback --type context "내용"
bash ${CLAUDE_PLUGIN_ROOT}/analyze-requirements/scripts/analyze.sh feedback --type investigation -i code-analysis "내용"
bash ${CLAUDE_PLUGIN_ROOT}/analyze-requirements/scripts/analyze.sh feedback --type requirement "내용"
bash ${CLAUDE_PLUGIN_ROOT}/analyze-requirements/scripts/analyze.sh feedback --type decision "내용"
```

#### 5.3 피드백 반영 완료
```bash
bash ${CLAUDE_PLUGIN_ROOT}/analyze-requirements/scripts/analyze.sh feedback-done --all
```

#### 5.4 최종 승인
```bash
bash ${CLAUDE_PLUGIN_ROOT}/analyze-requirements/scripts/analyze.sh phase 5 complete
```

## Critical Rules

1. **Init First** — 분석 시작 전 반드시 `analyze.sh init` 실행
2. **The 2-Action Rule** — 2번의 조회/분석 후, 즉시 발견 사항을 파일에 기록
3. **결정 즉시 기록** — 확인된 결정사항은 즉시 `decisions.md`에 기록
4. **Subagent로 조사** — 조사는 Agent tool로 위임, 메인 context는 요구사항에 집중
5. **체크리스트 업데이트** — 각 작업 완료 시 `progress.md` 체크리스트 업데이트
6. **피드백 즉시 기록** — 사용자 피드백은 즉시 `analyze.sh feedback`으로 기록

## 프로토콜 연계

**우선순위**: Hermeneia → Prothesis → Syneidesis → Katalepsis

| 상황 | 프로토콜 | 별칭 |
|------|----------|------|
| 응답이 모호하면 | `/hermeneia` | `/clarify`, `/hmn` |
| 설계 방향이 여러 개면 | `/prothesis` | `/lens` |
| 결정 전 확인이 필요하면 | `/syneidesis` | `/gap` |
| AI 작업 결과 이해가 필요하면 | `/katalepsis` | `/grasp` |

**Phase별 적용 가이드**:
- Phase 1 (컨텍스트 수집): Hermeneia - 요구사항 명확화
- Phase 3 (요구사항 구체화): Hermeneia, Prothesis - 방향 결정
- Phase 4 (솔루션 도출): Prothesis, Syneidesis - 설계 검토
- Phase 5 (피드백): Katalepsis - 결과물 이해 확인
