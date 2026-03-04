---
description: 요구사항 분석 및 문서화
allowed-tools:
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - Bash
  - Task
  - AskUserQuestion
  - mcp__mcpyo__jira_get_ticket
  - mcp__mcpyo__jira_get_ticket_comments
hooks:
  PreToolUse:
    - matcher: "Write|Edit|Task|Read|Glob|Grep|WebFetch"
      hooks:
        - type: command
          command: |
            BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
            PROGRESS="docs/${BRANCH}/progress.md"
            SCRIPT="${CLAUDE_PLUGIN_ROOT}/scripts/analyze.sh"
            if [ ! -f "$PROGRESS" ]; then
              echo ""
              echo "╔══════════════════════════════════════════════════════════════╗"
              echo "║  ⛔ BLOCKED: analyze.sh init 먼저 실행 필요                  ║"
              echo "║                                                              ║"
              echo "║  bash $SCRIPT init                                           ║"
              echo "║                                                              ║"
              echo "║  progress.md가 없으면 다른 작업을 진행할 수 없습니다.        ║"
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
            bash "${CLAUDE_PLUGIN_ROOT}/scripts/analyze.sh" check
---

# Analyze Requirements

요구사항을 단계별로 구체화하고, 확인 내용을 파일에 기록하면서 진행합니다.
분석 결과는 `docs/{브랜치명}/` 폴더에 영역별로 분리하여 저장합니다.

## FIRST: Check for Previous Session (v2.2.0)

**Before starting work**, check for unsynced context from a previous session:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/analyze.sh init
```

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

## 실행 절차

### Phase 1: 초기화 및 컨텍스트 수집

#### 1.1 Init 스크립트 실행
```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/analyze.sh init
```

이 스크립트가 생성하는 파일:
- `progress.md` - 체크리스트 및 진행 로그
- `context.md` - Jira 정보 템플릿
- `decisions.md` - 결정사항 기록
- `requirements.md` - 요구사항 템플릿
- `solution.md` - 솔루션 템플릿

#### 1.2 Jira 정보 수집 → context.md
- 브랜치명에서 Jira 키 추출 (예: `order-8157-feature` → `ORDER-8157`)
- `jira_get_ticket`, `jira_get_ticket_comments`로 정보 수집
- `context.md`에 기록

#### 1.3 체크리스트 업데이트
```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/analyze.sh update "Jira 티켓 정보 수집" done
```

### Phase 2: 조사 (Subagent 활용)

**중요: 조사 작업은 Task tool로 subagent에게 위임하여 context 오염을 방지합니다.**

#### 2.1 조사 항목 추가
```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/analyze.sh investigate "api-integration" "외부 API 연동 분석"
```

#### 2.2 Subagent로 조사 실행
```
Task(subagent_type="Explore", prompt="""
[조사 내용 설명]

결과를 다음 파일에 작성해주세요:
docs/{브랜치명}/investigation/{파일명}.md

포맷:
# {조사 주제}
## 요약
## 상세 분석
## 관련 파일
""")
```

#### 2.3 조사 완료 시 체크리스트 업데이트
- 각 subagent 완료 후 progress.md 체크리스트 업데이트
- 모든 조사 완료 시 Phase 2 상태 변경:
```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/analyze.sh phase 2 complete
```

### Phase 3: 요구사항 구체화 (사용자 상호작용)

#### 3.1 AskUserQuestion으로 요구사항 확인
```
- "어떤 문제를 해결하려고 하나요?" (배경/동기)
- "어떤 결과를 기대하나요?" (목표)
- "제약 조건이 있나요?" (성능, 호환성 등)
```

#### 3.2 부작용 분석 질문
```
- "이 변경으로 기존 모니터링/알림에 영향이 있나요?"
- "비동기 처리나 재처리 로직이 포함되나요?"
```

#### 3.3 decisions.md에 결정사항 즉시 기록
**중요: 확인된 내용은 즉시 decisions.md에 기록합니다.**

#### 3.4 requirements.md 작성
핵심 요구사항, 비기능 요구사항, 제약 조건 정리

### Phase 4: 솔루션 도출

#### 4.1 solution.md 작성
- 아키텍처 개요
- 검토한 옵션 (장단점 비교)
- 권장안 및 근거
- 구현 계획

#### 4.2 최종 체크
```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/analyze.sh check
```

### Phase 5: 피드백 루프

**Phase 4 완료 후, 사용자 피드백을 받아 결과물을 개선합니다.**

#### 5.1 피드백 수집
사용자에게 결과물 리뷰 요청:
```
"분석 결과를 확인해 주세요. 수정이나 보완이 필요한 부분이 있나요?"
```

#### 5.2 피드백 기록
피드백 유형에 따라 적절한 파일에 기록:
```bash
# 컨텍스트 관련 피드백 → context.md
bash ${CLAUDE_PLUGIN_ROOT}/scripts/analyze.sh feedback --type context "API 응답 형식 재확인 필요"

# 조사 관련 피드백 → investigation 파일
bash ${CLAUDE_PLUGIN_ROOT}/scripts/analyze.sh feedback --type investigation -i code-analysis "캐시 로직 추가 검토"

# 요구사항 관련 피드백 → requirements.md
bash ${CLAUDE_PLUGIN_ROOT}/scripts/analyze.sh feedback --type requirement "성능 요구사항 구체화 필요"

# 결정 관련 피드백 → decisions.md
bash ${CLAUDE_PLUGIN_ROOT}/scripts/analyze.sh feedback --type decision "옵션 A로 결정 확정"
```

#### 5.3 피드백 반영
- 기록된 피드백에 따라 해당 문서 수정
- 반영 완료 후 상태 업데이트:
```bash
# 대화형 모드 (pending 피드백 목록 보여주고 선택)
bash ${CLAUDE_PLUGIN_ROOT}/scripts/analyze.sh feedback-done

# 특정 피드백 번호로 직접 완료 처리
bash ${CLAUDE_PLUGIN_ROOT}/scripts/analyze.sh feedback-done 1

# 모든 pending 피드백 완료 처리
bash ${CLAUDE_PLUGIN_ROOT}/scripts/analyze.sh feedback-done --all
```
- 필요시 추가 조사는 Phase 2로 돌아가서 subagent 활용

#### 5.4 반복
피드백이 더 이상 없을 때까지 5.1-5.3 반복.
최종 승인 시:
```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/analyze.sh phase 5 complete
```

## Critical Rules

### 1. Init First
분석 시작 전 반드시 `analyze.sh init` 실행. Non-negotiable.

### 2. The 2-Action Rule
> "2번의 조회/분석 작업 후, 즉시 발견 사항을 파일에 기록"

이렇게 해야 정보가 context에서 사라지기 전에 저장됩니다.

### 3. 결정 즉시 기록
확인된 결정사항은 즉시 `decisions.md`에 기록. 나중으로 미루지 않음.

### 4. Subagent로 조사
조사 작업은 Task tool로 위임. 메인 context는 요구사항 구체화에 집중.

### 5. 체크리스트 업데이트
각 작업 완료 시 `progress.md` 체크리스트 업데이트. 진행 상황 추적.

### 6. 피드백 즉시 기록
사용자 피드백은 즉시 `analyze.sh feedback`으로 기록. Context 휘발 방지.

### 7. 진행 로그 기록
주요 작업 완료 시 `progress.md`의 "진행 로그" 테이블에 기록:
```markdown
| 시간 | 작업 | 결과 |
|------|------|------|
| HH:MM:SS | 작업 내용 | 결과 요약 |
```
기록 시점:
- Phase 전환 시
- 주요 문서 작성/수정 완료 시
- 피드백 반영 완료 시
- 중요한 결정 사항 확정 시

## 출력

1. 생성된 폴더 경로: `docs/{브랜치명}/`
2. 핵심 요구사항 요약 (requirements.md 기반)
3. 미결정 사항 (decisions.md 기반)
4. 다음 단계 안내
