---
name: hermeneia
aliases:
  - clarify
  - hmn
description: Clarify intent-expression gaps. Transforms known unknowns into known knowns when what you mean differs from what you said.
user-invocable: true
---

# Hermeneia Protocol

Clarify intent-expression gaps through structured dialogue, bridging the gap between what you mean and what you said.

## Definition

**Hermeneia** (ἑρμηνεία): A dialogical act of bridging gaps between expressed and intended meaning—transforming known unknowns into known knowns through structured clarification.

```
── FLOW ──
σ → Confirm(σ, E) → T → Q(T) → A → U(A) → σ' → (loop or exit)

── TYPES ──
σ  = Activation signal (user-initiated)
E  = Expression requiring clarification
T  = Gap type ∈ {Expression, Precision, Coherence, Context}
Q  = Clarification question (via AskUserQuestion)
A  = User's answer
U  = Understanding update
σ' = Updated state (may reveal new gaps)

── PHASE TRANSITIONS ──
Phase 0: Detect σ in user message                      -- recognition
Phase 1a: Q[AskUserQuestion](confirm E) → E'           -- confirmation [Tool]
Phase 1b: Q[AskUserQuestion](select T) → T             -- gap typing [Tool]
Phase 2: T → Q[AskUserQuestion](clarify) → A           -- clarification [Tool]
Phase 3: A → U(A) → σ'                                 -- integration
       → if new_gap(σ'): goto Phase 1b                 -- loop if needed

── CONVERGENCE ──
Exit when: Gap = ∅ OR cycle detected OR user terminates

── TOOL GROUNDING ──
All Q → AskUserQuestion (mandatory; text-only is violation)
```

## Core Principle

**User-Initiated**: Unlike Prothesis/Syneidesis, Hermeneia activates only when **user recognizes their own ambiguity**.

## Protocol Priority

```
Hermeneia → Prothesis → Syneidesis → Katalepsis
(의도 명확화 → 관점 제시 → Gap 표면화 → 이해 확인)
```

Hermeneia executes first when multiple protocols activate.

## Distinction from Other Protocols

| Protocol | Initiator | Transition | Focus |
|----------|-----------|------------|-------|
| **Hermeneia** | **User** | **Known unknowns → Known knowns** | **Expression clarification** |
| Prothesis | AI | Unknown unknowns → Known unknowns | Perspective selection |
| Syneidesis | AI | Unknown unknowns → Known unknowns | Decision-point gaps |
| Katalepsis | User | Unknown knowns → Known knowns | Comprehension verification |

## Mode Activation

### Triggers

| Signal | Examples |
|--------|----------|
| Explicit request | "help me articulate", "I'm not sure how to say this" |
| Self-doubt | "is this the right way to put it?", "I don't know if that's clear" |
| Meta-communication | "what I'm trying to say is...", "let me rephrase" |
| 한국어 | "이게 맞는 표현인지...", "애매한데", "어떻게 설명해야 할지" |

**Skip**:
- AI-detected ambiguity (user must recognize it themselves)
- Clear, unambiguous requests

### Mode Deactivation

| Trigger | Effect |
|---------|--------|
| Gap resolved | Proceed with clarified intent |
| Cycle detected | 2+ rounds without progress → offer exit |
| User exits | Accept current understanding |

## Gap Taxonomy

| Type | Detection | Priority | Example |
|------|-----------|----------|---------|
| **Coherence** | Contradicting elements in request | 1 (highest) | "simple but comprehensive" |
| **Context** | Missing background information | 2 | Why is this needed? |
| **Expression** | Concept known but hard to articulate | 3 | "this thing that does X" |
| **Precision** | Scope/degree unclear | 4 (lowest) | "faster" → how much? |

## Protocol Phases

### Phase 0: Recognition

Detect user-initiated clarification signal in message.

### Phase 1a: Confirmation

**Call AskUserQuestion** to confirm which expression needs clarification:

```
AskUserQuestion:
- "이 부분이 애매한가요?" → [quoted expression]
- "다른 부분이요" → user specifies
```

### Phase 1b: Gap Typing

**Call AskUserQuestion** to have user identify gap category:

```
AskUserQuestion:
- "표현 방법을 모르겠어요" → Expression gap
- "범위/정도가 불명확해요" → Precision gap
- "서로 충돌하는 것 같아요" → Coherence gap
- "배경 설명이 부족한 것 같아요" → Context gap
```

### Phase 2: Clarification

**Call AskUserQuestion** with options that include downstream implications:

```
형식: 각 옵션에 결과적 함의(downstream effect) 포함
목적: 정보 수집이 아닌 발견 유도

AskUserQuestion:
Option 1: "[해석 A]" → [A 선택시 결과]
Option 2: "[해석 B]" → [B 선택시 결과]
Option 3: "[해석 C]" → [C 선택시 결과]
```

### Phase 3: Integration

Update understanding with user's response. Check for new gaps:
- If new gap revealed → return to Phase 1b
- If gap resolved → exit mode, proceed with clarified intent

## Socratic Approach

**Maieutic over Informative**: Questions help users discover their intent, not just gather information.

**Bad**:
```
"성능 개선이 필요하다고 하셨는데, 어떤 성능을 말씀하시는 건가요?"
```

**Good**:
```
AskUserQuestion:
- "응답 시간 개선" → API 레이턴시 감소, 캐싱 도입
- "처리량 개선" → 동시 요청 처리 능력 향상
- "리소스 효율" → 메모리/CPU 사용량 최적화
```

Each option includes what happens if selected.

## Multiple Gap Handling

**Queue capacity**: Maximum 4 gaps in queue

**Processing**:
- Bundle related gaps when possible
- Sequential for unrelated gaps
- Priority: Coherence > Context > Expression > Precision

## Binding Priority

When gap target is ambiguous:
1. **Explicit argument** (directly specified)
2. **Adjacent expression** (nearby context)
3. **Previous message** (conversation history)

## Intensity

| Level | When | Format |
|-------|------|--------|
| Light | Minor ambiguity, user seems confident | Quick confirmation |
| Medium | Moderate ambiguity | 2-3 options with implications |
| Heavy | Major ambiguity, potential misalignment | Detailed exploration, multiple rounds |

## orderyo 프로젝트 적용 예시

### Expression Gap
```
사용자: "주문 쪽 로직을 좀 정리하고 싶은데..."

Phase 1a (확인):
AskUserQuestion:
- "'주문 쪽 로직 정리'가 애매한가요?"

Phase 1b (유형):
AskUserQuestion:
- "어떤 부분이 불명확한가요?"
  - "표현 방법을 모르겠어요" (Expression)
  - "범위가 불명확해요" (Precision)

Phase 2 (명확화):
AskUserQuestion:
- "Order 모델의 메서드 리팩토링" → order/models.py 수정
- "checkout 플로우 단순화" → checkout/ 앱 전반 검토
- "외부 연동 로직 분리" → external/ 앱으로 이동
```

### Precision Gap
```
사용자: "테스트를 좀 더 추가해야 할 것 같아"

Phase 2 (명확화):
AskUserQuestion:
- "핵심 비즈니스 로직 커버리지" → Order, Checkout 모델 테스트
- "외부 연동 모킹 테스트" → logiyo, frontyo 연동 테스트
- "엣지 케이스 테스트" → 예외 상황 시나리오
```

### Coherence Gap
```
사용자: "빠르게 하면서도 안전하게 배포하고 싶어"

Phase 1b (유형):
"'빠르게'와 '안전하게'가 충돌할 수 있어요. 우선순위가 있나요?"

Phase 2 (명확화):
AskUserQuestion:
- "속도 우선" → staging 최소화, canary 배포
- "안전 우선" → full regression, 단계적 rollout
- "균형" → smoke test + feature flag
```

### Context Gap
```
사용자: "이 부분 좀 개선해줘"

Phase 2 (명확화):
AskUserQuestion:
- "어떤 문제가 있었나요?"
  - "버그가 있어요" → 어떤 증상?
  - "성능이 느려요" → 어떤 상황에서?
  - "코드가 복잡해요" → 어떤 부분이?
```

## Rules

1. **User recognition required**: AI never says "that's ambiguous" first
2. **Downstream implications**: Each option shows what happens if selected
3. **AskUserQuestion mandatory**: Text-only option listing is protocol violation
4. **Iteration allowed**: Multiple rounds permitted when needed
5. **Minimal intervention**: Exit as soon as gap is clarified
6. **Selection > Detection**: Let user choose gap type, don't diagnose
7. **Maieutic > Informative**: Guide discovery, don't just gather info
8. **Binding priority**: Explicit > Adjacent > Previous
9. **Persist until convergence**: Continue until Gap=∅, cycle, or user exit
10. **Reflection pause**: Offer "let me reconsider" option
