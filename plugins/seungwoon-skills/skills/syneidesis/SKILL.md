---
name: syneidesis
aliases:
  - gap
description: Gap surfacing before decisions. Raises procedural, consideration, assumption, and alternative gaps as questions to transform unknown unknowns into known considerations.
user-invocable: true
---

# Syneidesis Protocol

Surface potential gaps at decision points through questions, enabling user to notice what might otherwise remain unnoticed.

## Definition

**Syneidesis** (συνείδησις): A dialogical act of surfacing potential gaps—procedural, consideration, assumption, or alternative—at decision points, transforming unknown unknowns into questions the user can evaluate.

```
── FLOW ──
D → Scan(D) → G → Sel(G, D) → Gₛ → Q(Gₛ) → J → A(J, D, Σ) → Σ'

── TYPES ──
D      = Decision point ∈ Stakes × Context
Stakes = {Low, Med, High}
G      = Gap ∈ {Procedural, Consideration, Assumption, Alternative}
Scan   = Detection: D → Set(G)
Sel    = Selection: Set(G) × D → Gₛ
Gₛ     = Selected gaps (|Gₛ| ≤ 2)
Q      = Question formation (assertion-free)
J      = Judgment ∈ {Addresses(c), Dismisses, Silence}
c      = Clarification (user-provided response)
A      = Adjustment: J × D × Σ → Σ'
Σ      = State { reviewed: Set(GapType), deferred: List(G), blocked: Bool }

── PHASE TRANSITIONS ──
Phase 0: D → Scan(D) → G                            -- detection (silent)
Phase 1: G → TaskCreate[all gaps] → Gₛ → Q[AskUserQuestion](Gₛ[0]) → J  -- register + surface [Tool]
Phase 2: J → A(J, D, Σ) → TaskUpdate → Σ'           -- adjustment + update [Tool]

── LOOP ──
After Phase 2: re-scan for newly surfaced gaps from user response.
If new gaps: TaskCreate → add to queue.
Continue until: all tasks completed OR user ESC.

── ADJUSTMENT RULES ──
A(Addresses(c), _, σ) = σ { incorporate(c) }        -- modifies plan
A(Dismisses, _, σ)    = σ { reviewed ← reviewed ∪ {Gₛ.type} }
A(Silence, d, σ)      = match stakes(d):
                          Low|Med → σ { deferred ← Gₛ :: deferred }
                          High    → σ { blocked ← true }

── SELECTION RULE ──
Sel(G, d) = take(priority_sort(G, stakes(d)), min(|G|, stakes(d) = High ? 2 : 1))

── CONTINUATION ──
proceed(Σ) = ¬blocked(Σ)

── TOOL GROUNDING ──
Q (extern)     → AskUserQuestion tool (mandatory)
Σ (state)      → TaskCreate/TaskUpdate (gap tracking)
Scan (detect)  → Read, Grep (context for gap identification)
```

## Core Principle

**Surfacing over Deciding**: AI makes visible; user judges.

## Protocol Priority

```
Hermeneia → Prothesis → Syneidesis → Katalepsis
(의도 명확화 → 관점 제시 → Gap 표면화 → 이해 확인)
```

## Distinction from Other Protocols

| Protocol | Initiator | Transition | Focus |
|----------|-----------|------------|-------|
| Hermeneia | User | Known unknowns → Known knowns | Expression clarification |
| Prothesis | AI | Unknown unknowns → Known unknowns | Perspective selection |
| **Syneidesis** | **AI** | **Unknown unknowns → Known unknowns** | **Decision-point gaps** |
| Katalepsis | User | Unknown knowns → Known knowns | Comprehension verification |

## Mode Activation

### Triggers

| Signal | Examples |
|--------|----------|
| Scope | "all", "every", "entire" |
| Irreversibility | "delete", "push", "deploy", "migrate" |
| Time compression | "quickly", "just", "right now" |
| Uncertainty | "maybe", "probably", "I think" |
| Stakes | production, security, data, external API |
| 한국어 | "모든", "전체", "삭제", "배포", "빨리", "일단" |

**Skip**:
- User explicitly confirmed in current session
- Mechanical task (no judgment involved)
- User already mentioned the gap category

### Mode Deactivation

| Trigger | Effect |
|---------|--------|
| Task completion | Auto-deactivate after final resolution |
| User dismisses 2+ consecutive gaps | Reduce intensity for session |

## Gap Taxonomy

| Type | Detection | Question Form | Priority |
|------|-----------|---------------|----------|
| **Procedural** | Expected step absent from plan | "Was [step] completed?" | 1 |
| **Consideration** | Relevant factor not mentioned | "Was [factor] considered?" | 2 |
| **Assumption** | Unstated premise inferred | "Are you assuming [X]?" | 3 |
| **Alternative** | Known option not referenced | "Was [alternative] considered?" | 4 |

## Stakes Assessment

```
High   = Irreversible + High impact
Medium = Irreversible + Low impact OR Reversible + High impact
Low    = Reversible + Any impact
```

## Protocol Phases

### Phase 0: Detection (Silent)

1. **Stakes assessment**: Evaluate irreversibility × impact
2. **Gap scan**: Check taxonomy against user's stated plan
3. **Filter**: Surface only gaps with observable evidence (not speculation)

### Phase 1: Batch Registration + Sequential Surfacing

**TaskCreate for ALL detected gaps, then surface first:**

```
Workflow:
1. Scan → detect ALL gaps at decision point
2. TaskCreate for each gap (batch registration, all `pending`)
3. TaskUpdate first gap to `in_progress`
4. AskUserQuestion for current gap
```

**Task format**:
```
TaskCreate({
  subject: "[Gap:Type] Question",
  description: "Rationale and context",
  activeForm: "Surfacing [Type] gap"
})
```

**AskUserQuestion format**:
```
Format: "[Question]" (rationale: [1-line])
High-stakes: append "Anything else to verify?"
```

- One gap per decision point
- Exception: Multiple high-stakes gaps → surface up to 2, prioritized by irreversibility

### Phase 2: Adjustment + Re-scan

**Process user response:**

| Response | Action | Task Status | Next Step |
|----------|--------|-------------|-----------|
| Addresses | Incorporate into plan | completed | Next pending gap |
| Dismisses | Accept, no follow-up | completed | Skip similar gaps |
| Silence (Low/Med) | Proceed | deferred | Revisit later |
| Silence (High) | **Wait** | blocked | Block until resolved |

**Dynamic discovery:**
```
After each response:
1. Re-scan for newly revealed gaps
2. If new gaps found → TaskCreate
3. TaskUpdate next pending to `in_progress`
4. Loop until: no pending tasks OR user ESC
```

**State transition diagram:**
```
pending → in_progress → completed
                    ↘ deferred (Low/Med silence)
                    ↘ blocked (High silence)
```

## Intensity

| Level | When | Format |
|-------|------|--------|
| Light | Reversible, low impact | "[X] confirmed?" |
| Medium | Reversible+high OR Irreversible+low | "[X] reviewed? (rationale)" |
| Heavy | Irreversible + high impact | "Before proceeding, [X]? (rationale)" |

## Task State Management

### Session Start
```
1. Check existing deferred gaps (TaskList)
2. If blocked gaps exist → request resolution first
3. Remind unresolved gaps before new decisions
```

### Session End
```
1. Summarize incomplete gaps
2. Warn if blocked gaps exist
3. Suggest revisiting deferred gaps
```

## Plan Mode Integration

When combined with Plan mode, apply Syneidesis at **Phase boundaries**:

| Phase Transition | Gap Check Focus |
|------------------|-----------------|
| Planning → Implementation | Scope completeness, missing requirements |
| Phase N → Phase N+1 | Previous phase completion, dependency satisfaction |
| Implementation → Commit | Changed assumptions, deferred decisions |

**Cycle**: [Deliberation → Gap → Revision → Execution]

## orderyo 프로젝트 적용 예시

### 배포 결정
```
[탐지] 트리거: "production 배포하자"
[Stakes] High (비가역적 + 고영향)

Phase 1 - 일괄 등록:
TaskCreate:
- [Gap:Procedural] staging에서 해당 시나리오 테스트했나요?
- [Gap:Consideration] 롤백 계획 준비되어 있나요?
- [Gap:Assumption] 현재 트래픽이 낮은 시간대인가요?

TaskUpdate: 첫 번째 gap → in_progress

AskUserQuestion (Heavy):
"진행 전에, staging에서 해당 시나리오 테스트했나요?"
(근거: production 배포는 비가역적 고영향 작업)
[추가] "확인할 것이 더 있나요?"

Phase 2 - 조정:
사용자: "네, 테스트 완료"
→ TaskUpdate: completed
→ 다음: 롤백 계획 gap
```

### DB 마이그레이션
```
[탐지] 트리거: "마이그레이션 실행"
[Stakes] High (비가역적 + 고영향)

TaskCreate:
- [Gap:Procedural] 롤백 스크립트 준비됐나요?
- [Gap:Consideration] 기존 데이터 백업했나요?
- [Gap:Alternative] 무중단 마이그레이션 검토했나요?

AskUserQuestion (Heavy):
"진행 전에, 롤백 스크립트 준비됐나요?"
(근거: 스키마 변경은 운영 데이터에 직접 영향)
```

### 외부 연동 변경
```
[탐지] 트리거: "logiyo API 변경"
[Stakes] Medium (가역적 + 고영향)

TaskCreate:
- [Gap:Consideration] 하위 호환성 확인했나요?
- [Gap:Assumption] logiyo 측 변경 일정 확인했나요?

AskUserQuestion (Medium):
"logiyo API 변경에 대한 하위 호환성을 확인했나요?"
(근거: 외부 시스템 의존성 변경은 연쇄 영향 가능)
```

### 동적 발견 예시
```
[사용자 응답] "staging 테스트 안 했어"

[재검토 결과] 새로운 Gap 발견:
TaskCreate:
- [Gap:Procedural] 테스트 시나리오 목록 있나요?

[연쇄 조정] 기존 Gap 상태 유지, 새 Gap 추가

AskUserQuestion:
"테스트 시나리오 목록 있나요?"
(근거: staging 테스트를 위한 기준 필요)
```

## 종료 조건

- 모든 Gap이 completed 또는 사용자가 명시적으로 무시
- blocked Gap 없음 (또는 사용자가 명시적 승인)
- 사용자가 "진행해" 또는 최종 결정 표현

## Rules

1. **Question > Assertion**: Ask "was X considered?", never "you missed X"
2. **Batch registration**: Register ALL detected gaps via TaskCreate before surfacing
3. **Observable evidence**: Surface only gaps with concrete indicators
4. **User authority**: Dismissal is final
5. **Minimal intrusion**: Lightest intervention that achieves awareness
6. **Stakes calibration**: Intensity follows stakes matrix
7. **Convergence persistence**: Mode active until all gaps resolved or ESC
8. **Dynamic discovery**: Re-scan after each response; new gaps → TaskCreate
9. **Gap dependencies**: Use task blocking when gaps have logical order
10. **AskUserQuestion mandatory**: Text-only gap listing is protocol violation
