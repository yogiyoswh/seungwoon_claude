# seungwoon_claude

Claude Code 플러그인 마켓플레이스. 요구사항 분석과 파일 기반 계획 수립 스킬을 제공합니다.

## 포함된 플러그인

| 플러그인 | 유형 | 설명 |
|----------|------|------|
| **analyze-requirements** | Command | 단계별 요구사항 분석 워크플로우. Jira 연동, 조사(subagent), 피드백 루프 포함 |
| **planning-with-files** | Skill | Manus 스타일 파일 기반 계획. task_plan.md, findings.md, progress.md로 working memory 관리 |

## 설치

```bash
claude plugin install yogiyoswh/seungwoon_claude
```

설치 후 활성화된 플러그인 확인:

```bash
claude plugin list
```

## 사용법

### analyze-requirements

슬래시 커맨드로 실행:

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

## 개별 플러그인만 설치

특정 플러그인만 설치하고 싶은 경우:

```bash
# analyze-requirements만 설치
claude plugin install yogiyoswh/seungwoon_claude --plugin analyze-requirements

# planning-with-files만 설치
claude plugin install yogiyoswh/seungwoon_claude --plugin planning-with-files
```

## 제거

```bash
claude plugin remove analyze-requirements@seungwoon_claude
claude plugin remove planning-with-files@seungwoon_claude
```
