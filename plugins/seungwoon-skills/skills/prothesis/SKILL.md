---
name: prothesis
aliases:
  - lens
description: Lens for multi-perspective analysis. Select viewpoints before analysis to transform unknown unknowns into known unknowns.
user-invocable: true
---

# Prothesis Protocol

Present epistemic perspectives as selectable options when inquiries lack a clear analytical approach, enabling selection before any perspective-requiring cognition.

## Definition

**Prothesis** (πρόθεσις): A dialogical act of presenting available epistemic perspectives as options when the inquirer does not know from which viewpoint to proceed.

```
── FLOW ──
R → Ctx → L → Q(L) → Sₚ → A[isolated] → Synth → Suff → (loop or exit)

── TYPES ──
R    = Request (underspecified inquiry)
Ctx  = Context gathered from R
L    = List of perspectives (epistemic frameworks)
Q    = Selection question (via AskUserQuestion)
Sₚ   = Selected perspectives
A    = Analysis (via isolated Task subagents)
Synth = Synthesis of perspective outputs
Suff = Sufficiency check

── PHASE TRANSITIONS ──
Phase 0: R → Gather(R) → Ctx                           -- context (silent)
Phase 1: Ctx → L → Q[AskUserQuestion](L) → Sₚ          -- selection [Tool]
Phase 2: Sₚ → Task[isolated](Sₚ) → A                   -- parallel inquiry [Tool]
Phase 3: A → Synthesize(A) → Synth                     -- synthesis
Phase 4: Synth → Q[AskUserQuestion](sufficient?) → J   -- sufficiency [Tool]
       → if more_needed(J): goto Phase 1               -- loop if needed

── CONVERGENCE ──
Exit when: User confirms sufficiency OR user terminates

── ISOLATION REQUIREMENT ──
Each Task subagent runs WITHOUT prior conversation context
→ Architecturally mandatory for bias prevention

── TOOL GROUNDING ──
Phase 1 Q → AskUserQuestion (perspective selection)
Phase 2 A → Task tool (isolated subagents)
Phase 4 Q → AskUserQuestion (sufficiency check)
```

## Core Principle

**Recognition over Recall**: User selects from presented perspectives rather than having to articulate them.

## Protocol Priority

```
Hermeneia → Prothesis → Syneidesis → Katalepsis
(의도 명확화 → 관점 제시 → Gap 표면화 → 이해 확인)
```

## Distinction from Other Protocols

| Protocol | Initiator | Transition | Focus |
|----------|-----------|------------|-------|
| Hermeneia | User | Known unknowns → Known knowns | Expression clarification |
| **Prothesis** | **AI** | **Unknown unknowns → Known unknowns** | **Perspective selection** |
| Syneidesis | AI | Unknown unknowns → Known unknowns | Decision-point gaps |
| Katalepsis | User | Unknown knowns → Known knowns | Comprehension verification |

## Mode Activation

### When to Apply

- Purpose exists but approach is **underspecified**
- Multiple valid analytical frameworks exist
- No single correct answer

### When to Skip

- Deterministic procedure exists
- Clear approach already specified
- Simple implementation task

### Triggers

| Signal | Examples |
|--------|----------|
| Open inquiry | "what do you think about", "analyze this" |
| Strategy request | "how should I approach", "what's the best way" |
| Design question | "how would you design", "what architecture" |
| 한국어 | "여러 관점에서", "어떻게 접근할까", "분석해줘" |

## Perspective Criteria (4 Requirements)

| # | Criterion | Description | Violation Example |
|---|-----------|-------------|-------------------|
| 1 | **Distinct epistemic framework** | Each perspective provides independent frame | Same position variants (A vs B) |
| 2 | **Productive tension** | Meaningful disagreement between perspectives | All reach same conclusion |
| 3 | **Minimal commensurability** | At least one shared reference point | Completely different domains |
| 4 | **Framework naming** | Named as discipline/framework, NOT persona | "Cautious developer" (persona) |

**Good perspectives**:
- "Performance engineering" ✓
- "Domain-driven design" ✓
- "Operational reliability" ✓

**Bad perspectives**:
- "Senior developer view" ✗ (persona)
- "Conservative approach" ✗ (attitude)
- "React vs Vue" ✗ (same framework variants)

## Protocol Phases

### Phase 0: Context Gathering (Silent)

Extract from user's request:
- Subject of analysis
- Implicit constraints
- Stakeholders

### Phase 1: Perspective Presentation

**Call AskUserQuestion** with 3-5 perspectives:

```
AskUserQuestion (multiSelect):
- "[Perspective A]" → [what it reveals]
- "[Perspective B]" → [what it reveals]
- "[Perspective C]" → [what it reveals]
- "[Perspective D]" → [what it reveals]
```

### Phase 2: Parallel Analysis (Isolated Subagents)

**CRITICAL**: Each perspective analyzed in **isolated Task subagent**.

```
중요: Task subagent는 이전 대화 기록 없이 독립적 맥락에서 분석
→ 확인 편향과 앵커링 방지를 위해 "건축학적으로 필수"
```

**Subagent prompt format**:
```markdown
## Analysis Request
[Subject description]

## Perspective
[Selected perspective name]

## Response Format
1. Epistemic contribution (2-3 sentences)
   - Unique insight this perspective provides

2. Framework analysis
   - Core concepts
   - Terminology used
   - Reasoning approach

3. Horizon limits
   - What this perspective cannot see
   - Intentionally excluded elements

4. Assessment
   - Direct answer from this perspective
   - Recommendations
```

**Execution**:
```
For each selected perspective:
1. Task tool creates subagent (isolated context)
2. Request analysis with format above
3. Collect results
```

### Phase 3: Synthesis

Combine perspective outputs:
- **Convergence**: Points where perspectives agree
- **Divergence**: Points of disagreement
- **Trade-offs**: Explicit tensions between approaches
- **Integrated assessment**: Decision support information

**Important**: Synthesis combines only provided outputs; introduces no novel analysis.

### Phase 4: Sufficiency Check

**Call AskUserQuestion** to confirm:

```
AskUserQuestion:
- "충분합니다" → Exit mode
- "다른 관점 추가" → Return to Phase 1
- "특정 관점 심화" → Deeper analysis on selected
```

## Perspective Library (Examples)

| Domain | Example Perspectives |
|--------|---------------------|
| Technical | Performance engineering, Security engineering, System reliability, Scalability design |
| Design | Domain-driven design, Clean architecture, Event sourcing, CQRS |
| Operations | SRE, DevOps, Cost optimization, Observability |
| Business | Product strategy, Technical debt management, Team capability, Market fit |
| User | UX design, Accessibility, Performance perception, Learning curve |

## orderyo 프로젝트 적용 예시

### 캐싱 전략 분석

```
/prothesis 주문 시스템 캐싱 전략

Phase 1 - 관점 제시:
AskUserQuestion (multiSelect):
1. "성능 공학" → 응답 시간, 처리량, 캐시 적중률
2. "데이터 일관성" → 정합성, 무효화 전략, 동기화
3. "운영 신뢰성" → 메모리 관리, 장애 복구, 모니터링
4. "비용 최적화" → 인프라 비용, 개발 공수, 유지보수

Phase 2 - 병렬 분석 (subagent 격리):
Task subagent 1 (성능 공학):
- 격리된 맥락에서 분석
- 캐시 적중률 최적화 방안
- 응답 시간 개선 측정 기준

Task subagent 2 (데이터 일관성):
- 격리된 맥락에서 분석
- 주문 데이터 정합성 요구사항
- 무효화 전략 옵션

Phase 3 - 통합 평가:
수렴: 두 관점 모두 읽기 캐시 필요성 동의
발산: 성능은 적극적 캐싱, 일관성은 보수적 TTL 권장
권장: Write-through + 짧은 TTL로 균형

Phase 4 - 충분성 확인:
"추가 관점이 필요하신가요?"
```

### 아키텍처 결정

```
/lens 외부 연동 로직 분리

Phase 1 - 관점 제시:
AskUserQuestion (multiSelect):
1. "도메인 주도 설계" → 바운디드 컨텍스트, 안티코럽션 레이어
2. "시스템 통합" → API 게이트웨이, 이벤트 버스, 사이드카
3. "테스트 용이성" → 목 객체, 계약 테스트, 통합 테스트
4. "운영 복원력" → 회로 차단기, 재시도, 폴백

Phase 2 - 병렬 분석 (subagent 격리):
Task subagent (도메인 주도 설계):
- logiyo/frontyo를 바운디드 컨텍스트로 모델링
- 안티코럽션 레이어 필요성 평가

Task subagent (운영 복원력):
- 현재 장애 전파 위험 평가
- 회로 차단기 패턴 적용 방안

Phase 3 - 통합 평가:
수렴: 두 관점 모두 외부 연동 추상화 계층 필요
발산: DDD는 도메인 순수성 우선, 복원력은 운영 안정성 우선
권장: Adapter 패턴 + 회로 차단기

Phase 4 - 충분성 확인:
"추가 관점이 필요하신가요?"
→ "비용 관점 추가" → 비용 분석 subagent 실행
```

### 리팩토링 방향

```
/prothesis checkout 모듈 개선 방향

Phase 1 - 관점 제시:
AskUserQuestion (multiSelect):
1. "기술 부채 관리" → 복잡도 감소, 의존성 정리, 테스트 커버리지
2. "비즈니스 민첩성" → 기능 추가 용이성, 변경 영향 범위
3. "팀 역량" → 학습 곡선, 온보딩, 지식 공유
4. "점진적 마이그레이션" → 리스크 분산, 병행 운영, 롤백 가능성
```

## Rules

1. **Text-only presentation forbidden**: Must use AskUserQuestion tool
2. **4 criteria compliance**: Distinct/Tension/Commensurable/Named
3. **No persona perspectives**: Avoid attitude-based viewpoints
4. **Subagent isolation mandatory**: Independent context for bias prevention
5. **Selection before analysis**: Only analyze after user selects
6. **Perspective persistence**: Maintain selected perspectives in follow-ups
7. **Sufficiency confirmation**: Always check if more analysis needed
8. **Trade-off explicit**: Clearly identify convergence/divergence points
9. **Synthesis boundaries**: Combine only; don't introduce novel analysis
