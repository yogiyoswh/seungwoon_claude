---
name: katalepsis
aliases:
  - grasp
description: Achieve certain comprehension after AI work. Transforms unknown knowns into known knowns through structured verification of AI-generated changes.
user-invocable: true
---

# Katalepsis Protocol

Achieve certain comprehension of AI work through structured verification, enabling the user to follow along and reach firm understanding.

## Definition

**Katalepsis** (κατάληψις): A dialogical act of achieving firm comprehension—from Stoic philosophy meaning "a grasping firmly"—transforming AI-generated results into verified user understanding through categorized entry points and progressive verification.

```
── FLOW ──
R → C → Sₑ → Tᵣ → P → Δ → Q → A → Tᵤ → P' → (loop until katalepsis)

── TYPES ──
R  = AI's result (the work output)
C  = Categories extracted from R
Sₑ = User-selected entry points
Tᵣ = Task registration for tracking
P  = User's phantasia (current representation/understanding)
Δ  = Detected comprehension gap
Q  = Verification question (via AskUserQuestion)
A  = User's answer
Tᵤ = Task update (progress tracking)
P' = Updated phantasia (refined understanding)

── PHASE TRANSITIONS ──
Phase 0: R → Categorize(R) → C                         -- analysis (silent)
Phase 1: C → Q[AskUserQuestion](entry points) → Sₑ     -- entry point selection [Tool]
Phase 2: Sₑ → TaskCreate[selected] → Tᵣ                -- task registration [Tool]
Phase 3: Tᵣ → TaskUpdate(current) → P → Δ              -- comprehension check
       → Q[AskUserQuestion](Δ) → A → P' → Tᵤ           -- verification loop [Tool]

── CONVERGENCE ──
Katalepsis = ∀t ∈ Tasks: t.status = completed
           ∧ P' ≅ R (user understanding matches AI result)

── TOOL GROUNDING ──
Phase 1 Q   → AskUserQuestion (entry point selection)
Phase 2 Tᵣ  → TaskCreate (category tracking)
Phase 3 Q   → AskUserQuestion (comprehension verification)
Phase 3 Tᵤ  → TaskUpdate (progress tracking)
```

## Core Principle

**Comprehension over Explanation**: AI verifies user's understanding rather than lecturing. The goal is confirmed comprehension, not information transfer.

## Protocol Priority

```
Hermeneia → Prothesis → Syneidesis → Katalepsis
(의도 명확화 → 관점 제시 → Gap 표면화 → 이해 확인)
```

## Distinction from Other Protocols

| Protocol | Initiator | Transition | Focus |
|----------|-----------|------------|-------|
| **Prothesis** | AI | Unknown unknowns → Known unknowns | Perspective selection |
| **Syneidesis** | AI | Unknown unknowns → Known unknowns | Decision-point gaps |
| **Hermeneia** | User | Known unknowns → Known knowns | Expression clarification |
| **Katalepsis** | User | Unknown knowns → Known knowns | Comprehension verification |

## Mode Activation

### Triggers

| Signal | Examples |
|--------|----------|
| Direct request | "explain this", "help me understand", "walk me through" |
| Comprehension signal | "I don't get it", "what did you change?", "why?" |
| Following along | "let me catch up", "what's happening here?" |
| Review request | "show me what you did", "summarize the changes" |
| 한국어 | "이게 뭐야", "뭘 한 거야", "설명해줘", "이해가 안 돼" |

**Skip**:
- User demonstrates understanding through accurate statements
- User explicitly declines explanation
- Changes are trivial (typo fixes, formatting)

### Mode Deactivation

| Trigger | Effect |
|---------|--------|
| All selected tasks completed | Katalepsis achieved; proceed |
| User explicitly cancels | Accept current understanding |
| User demonstrates full comprehension | Early termination |

## Category Taxonomy

| Category | Description | Example |
|----------|-------------|---------|
| **New Code** | Newly created functions, classes, files | "Added `validateInput()` function" |
| **Modification** | Changes to existing code | "Modified error handling in `parse()`" |
| **Refactoring** | Structural changes without behavior change | "Extracted helper method" |
| **Dependency** | Changes to imports, packages, configs | "Added new npm package" |
| **Architecture** | Structural or design pattern changes | "Introduced factory pattern" |
| **Bug Fix** | Corrections to existing behavior | "Fixed null pointer in edge case" |

## Gap Taxonomy

| Type | Detection | Question Form |
|------|-----------|---------------|
| **Expectation** | User's assumed behavior differs from actual | "Did you expect this to return X?" |
| **Causality** | User doesn't understand why something happens | "Do you understand why this value comes from here?" |
| **Scope** | User doesn't see full impact | "Did you notice this also affects Y?" |
| **Sequence** | User doesn't understand execution order | "Do you see that A happens before B?" |

## Protocol Phases

### Phase 0: Categorization (Silent)

Analyze AI work result and extract categories:
1. **Identify changes**: Parse diff, new files, modifications
2. **Categorize**: Group by taxonomy above
3. **Prioritize**: Order by importance (architecture > new code > modification > ...)
4. **Summarize**: Prepare concise category descriptions

### Phase 1: Entry Point Selection

**Call the AskUserQuestion tool** to let user select where to start.

```
What would you like to understand first?

Options (multiSelect):
1. [Category A]: [brief description]
2. [Category B]: [brief description]
3. [Category C]: [brief description]
4. All of the above
```

**Design principles**:
- Show max 4 categories per question
- Include "All of the above" when appropriate
- Allow multi-select for related categories

### Phase 2: Task Registration

**Call TaskCreate** for each selected category:

```
TaskCreate({
  subject: "[Katalepsis] Category name",
  description: "Brief description of what to understand",
  activeForm: "Understanding [category]"
})
```

Set task dependencies if categories have logical order.

### Phase 3: Comprehension Loop

For each task (category):

1. **TaskUpdate** to `in_progress`

2. **Present overview**: Brief summary of the category

3. **Verify comprehension** via AskUserQuestion:
   ```
   Do you understand [specific aspect]?

   Options:
   1. Yes, I get it — [proceed to next aspect or category]
   2. Not quite — [explains further, then re-verify]
   3. Let me see the code — [shows relevant code, then re-verify]
   ```

4. **On confirmed comprehension**:
   - TaskUpdate to `completed`
   - Move to next pending task

5. **On gap detected**:
   - Provide targeted explanation
   - Re-verify understanding
   - Do not mark complete until user confirms

### Verification Style

**Socratic verification**: Ask rather than tell.

Instead of:
```
"This function does X because of Y."
```

Use:
```
"What do you think this function does?"
→ If correct: "That's right. Ready for the next part?"
→ If incorrect: "Actually, it does X. Does that make sense now?"
```

**Chunking**: Break complex changes into digestible pieces. Verify each chunk before proceeding.

**Code reference**: When explaining, always reference specific line numbers or file paths.

## Intensity

| Level | When | Format |
|-------|------|--------|
| Light | Simple change, user seems familiar | "This adds X. Got it?" |
| Medium | Moderate complexity | "Let me walk through this. [explanation]. Clear?" |
| Heavy | Complex architecture or unfamiliar pattern | "This is a significant change. Let's take it step by step." |

## orderyo 프로젝트 적용 예시

### New Code 카테고리
```
사용자: "Order 모델에 뭘 추가한 거야?"

Phase 0 (분석):
- Category: New Code
- Changes: calculate_total(), validate_items() 메서드 추가

Phase 1 (진입점):
AskUserQuestion:
- "calculate_total() 메서드" → 주문 총액 계산 로직
- "validate_items() 메서드" → 상품 유효성 검증
- "둘 다" → 순차적으로 설명

Phase 3 (검증 루프):
"calculate_total()이 할인 적용 후 총액을 반환하는 거 이해되셨어요?"
→ "네" → TaskUpdate completed, 다음으로
→ "아니오" → 할인 로직 상세 설명, 재검증
```

### Architecture 카테고리
```
사용자: "checkout 리팩토링 뭐가 바뀐 거야?"

Phase 0 (분석):
- Category: Architecture
- Changes: CheckoutService 레이어 분리, 책임 분리

Phase 1 (진입점):
AskUserQuestion:
- "새로운 레이어 구조" → CheckoutService 도입 이유
- "기존 코드와의 관계" → 호환성 및 마이그레이션
- "전체 흐름" → 순차적 설명

Phase 3 (검증 루프 - Heavy):
"CheckoutService가 기존 checkout view에서 비즈니스 로직을 분리한 거 이해되셨어요?"
→ Gap(Causality): "왜 분리했는지" 추가 설명
→ Gap(Scope): "테스트 용이성 향상" 영향 설명
```

### Cross-cutting 변경
```
사용자: "외부 연동 로직 변경한 거 설명해줘"

Phase 0 (분석):
- Categories: Modification, Architecture
- Changes: logiyo/frontyo adapter 패턴 적용

Phase 1 (진입점):
AskUserQuestion:
- "Adapter 패턴 도입" → 추상화 계층 설명
- "각 연동별 변경" → logiyo, frontyo 개별 설명
- "에러 처리" → 새로운 retry 로직

Phase 3 (검증 루프):
"LogiyoAdapter가 기존 직접 호출을 대체하는 거 이해되셨어요?"
→ "네" → TaskUpdate completed
→ Gap(Sequence): "요청 → Adapter → 실제 API → 응답 변환" 흐름 설명
```

## Rules

1. **User-initiated only**: Activate only when user signals desire to understand
2. **Recognition over Recall**: Present options for selection, don't ask open questions
3. **Verify, don't lecture**: Confirm understanding through questions, not explanations
4. **Chunk complexity**: Break large changes into digestible categories
5. **Task tracking**: Use TaskCreate/TaskUpdate for progress visibility
6. **Code grounding**: Reference specific code locations
7. **User authority**: User's "I understand" is final
8. **Convergence persistence**: Mode remains active until all selected tasks completed
9. **Escape hatch**: User can exit at any time
10. **Phantasia update**: Each verification updates internal model of user's understanding
