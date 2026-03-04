# seungwoon_claude

Claude Code 플러그인 마켓플레이스. 요구사항 분석, 파일 기반 계획 수립, 사고 프로토콜 스킬을 제공합니다.

## 포함된 스킬

### 핵심 스킬

| 스킬 | 설명 |
|------|------|
| **analyze-requirements** | 단계별 요구사항 분석 워크플로우. Jira 연동, 조사(subagent), 피드백 루프 포함 |
| **planning-with-files** | Manus 스타일 파일 기반 계획. task_plan.md, findings.md, progress.md로 working memory 관리 |

### 프로토콜 스킬 (analyze-requirements 연계)

| 스킬 | 별칭 | 설명 |
|------|------|------|
| **hermeneia** | `/clarify`, `/hmn` | 의도-표현 불일치 명확화. 응답이 모호할 때 사용 |
| **prothesis** | `/lens` | 다중 관점 분석. 설계 방향이 여러 개일 때 사용 |
| **syneidesis** | `/gap` | 결정 전 Gap 표면화. 결정 전 확인이 필요할 때 사용 |
| **katalepsis** | `/grasp` | 이해도 검증. AI 작업 결과 이해가 필요할 때 사용 |

## 설치

> Private 레포이므로 GitHub 접근 권한(collaborator)이 필요합니다.

```bash
# 1. GitHub 레포를 플러그인 소스로 등록
claude plugin marketplace add yogiyoswh/seungwoon_claude

# 2. 플러그인 설치
claude plugin install seungwoon-skills@seungwoon_claude
```

### 특정 프로젝트에만 설치

`--scope` 옵션으로 설치 범위를 지정할 수 있습니다.

```bash
# 프로젝트 단위 설치 (해당 프로젝트에서만 활성화)
claude plugin install --scope project seungwoon-skills@seungwoon_claude
```

| Scope | 설명 | 적용 범위 |
|-------|------|-----------|
| `user` (기본값) | 전역 설치 | 모든 프로젝트에서 사용 가능 |
| `project` | 프로젝트 설치 | 해당 프로젝트에서만 사용 가능 |

설치 후 확인:

```bash
claude plugin list
```

## 사용법

### analyze-requirements

슬래시 커맨드로 실행하거나, 요구사항 분석이 필요한 상황에서 자동 활성화됩니다.

```
/analyze-requirements
```

실행하면 현재 git 브랜치 기반으로 `docs/{브랜치명}/` 폴더에 분석 문서를 생성합니다.

**워크플로우:**
1. Phase 1 - 초기화 및 Jira 컨텍스트 수집
2. Phase 2 - Subagent를 활용한 코드/영향 범위 조사
3. Phase 3 - 사용자 상호작용으로 요구사항 구체화
4. Phase 4 - 솔루션 도출 및 옵션 비교
5. Phase 5 - 피드백 루프로 결과물 개선

**생성되는 파일:**
```
docs/{브랜치명}/
├── progress.md        # 체크리스트 및 진행상황
├── context.md         # Jira 티켓 정보
├── investigation/     # 조사 결과
├── decisions.md       # 결정사항
├── requirements.md    # 구체화된 요구사항
└── solution.md        # 최종 제안 솔루션
```

### planning-with-files

복잡한 작업 시작 시 자동으로 활성화되거나, 슬래시 커맨드로 직접 실행:

```
/planning-with-files
```

프로젝트 루트에 계획 파일을 생성하고 작업 진행 상황을 추적합니다.

**생성되는 파일:**
```
{프로젝트 루트}/
├── task_plan.md    # 단계별 계획, 결정 사항, 에러 로그
├── findings.md     # 조사 결과, 기술 결정
└── progress.md     # 세션 로그, 테스트 결과
```

**핵심 규칙:**
- 복잡한 작업 전 반드시 `task_plan.md` 생성
- 2번 조회 후 즉시 findings.md에 기록 (2-Action Rule)
- 주요 결정 전 plan 파일 재읽기 (attention refresh)
- 실패한 작업은 반복하지 않고 접근법 변경 (3-Strike Protocol)

### 프로토콜 스킬

analyze-requirements 워크플로우의 각 Phase에서 자동 연계되며, 독립적으로도 사용 가능합니다.

```
/hermeneia    # 요구사항이 모호할 때 — 의도-표현 Gap 분석
/prothesis    # 설계 방향이 여러 개일 때 — 다중 관점 비교
/syneidesis   # 결정 전 빠진 부분이 없는지 — Gap 체크리스트
/katalepsis   # AI 결과물을 제대로 이해했는지 — 이해도 검증
```

**Phase별 적용 가이드:**
| Phase | 프로토콜 | 목적 |
|-------|----------|------|
| Phase 1 (컨텍스트 수집) | hermeneia | 요구사항 명확화 |
| Phase 3 (요구사항 구체화) | hermeneia, prothesis | 방향 결정 |
| Phase 4 (솔루션 도출) | prothesis, syneidesis | 설계 검토 |
| Phase 5 (피드백) | katalepsis | 결과물 이해 확인 |

## 제거

```bash
claude plugin remove seungwoon-skills@seungwoon_claude
```
