# 월식 용병단 문서 인덱스

이 문서는 프로젝트 기획과 개발 의사결정의 진입점이다. 기능 추가나 변경 전에 관련 문서를 먼저 확인하고, 구현 완료 시 `PROGRESS.md`와 `CHANGELOG.md`를 함께 갱신한다. 출시 여부 판단은 `RELEASE_READINESS_AUDIT.md`를 최우선으로 사용한다.

## 기준 문서

| 문서 | 역할 | 갱신 시점 |
|---|---|---|
| `PROJECT_PLAN.md` | 제품 비전, 핵심 루프, 전체 시스템과 콘텐츠 범위 | 게임 방향이나 범위가 바뀔 때 |
| `GAME_DESIGN.md` | 전투·성장·이벤트 규칙과 밸런스 초안 | 플레이 규칙이 바뀔 때 |
| `NEW_PLAYER_ONBOARDING.md` | 신규 계정 시작값, 임무·계약 해금과 초기 경제 | 온보딩·초기 보상·해금 속도가 바뀔 때 |
| `IMPLEMENTATION_PLAN.md` | 에픽별 구현 작업, 의존성, 완료 조건 | 개발 순서나 기술 범위가 바뀔 때 |
| `ARCHITECTURE.md` | Flutter/Flame 경계, 시스템 구조, 성능 원칙 | 구조나 데이터 흐름이 바뀔 때 |
| `ASSET_STYLE_GUIDE.md` | 캐릭터·픽셀·배경·아이콘·VFX 제작 규격 | 아트 파이프라인이나 스타일이 바뀔 때 |
| `ART_GUIDE.md` | 빠르게 확인하는 핵심 아트 원칙과 현재 자산 | 자산 추가 시 |
| `UI_UX_SPEC.md` | 디자인 토큰, 컴포넌트, 화면별 UI/UX 명세 | 화면이나 조작 방식이 바뀔 때 |
| `ROADMAP.md` | 단계별 목표, 선행 조건, 종료 기준 | 마일스톤 완료 또는 재조정 시 |
| `BETA_IMPLEMENTATION_ROADMAP.md` | 알파 진단부터 모바일 클로즈드 베타까지의 에픽·산출물·검증 기준 | 베타 범위, 우선순위, 종료 조건 변경 시 |
| `ALPHA_PLAYTEST_AUDIT.md` | B0 관찰표, 초기 프로토타입 부채와 레퍼런스 10화면 품질 관문 | 플레이테스트 세션과 부채 우선순위 변경 시 |
| `BALANCE_BASELINE.md` | 콘텐츠 수량, 전투 지수, 성장·보상 기준선과 CI 차단 규칙 | 콘텐츠 버전 또는 핵심 밸런스 변경 시 |
| `RELEASE_GROWTH_FINALIZATION_1_12.md` | F–S 성장, 모집, 16명 직무, Lv.30 계약과 예상 페이스 | 성장·수집·중반 밸런스 변경 시 |
| `TESTING.md` | 자동·수동·성능 테스트 기준 | 기능별 검증 범위가 바뀔 때 |
| `PLAYTEST.md` | 공개 Web 출시 후보 주소, 테스트 흐름과 피드백 접수 | 배포 주소나 테스트 범위가 바뀔 때 |
| `STORE_LISTING.md` | 앱 식별자, 스토어 소개·키워드·자산·데이터 선언 초안 | 버전·콘텐츠·스토어 정책 변경 시 |
| `PRIVACY.md` | 베타 로컬 데이터와 개인정보 처리 공개 방침 | 데이터·SDK·계정·결제 범위 변경 전 |
| `TERMS.md` | 무료 베타 이용·재화·권리·저장 한계 약관 초안 | 배포 주체·과금·서비스 범위 변경 시 |
| `RELEASE_CHECKLIST.md` | B6 자동 검증, 비서명 산출물, 서명 비밀과 제출 전 확인 | 네이티브 빌드·배포 절차 변경 시 |
| `RELEASE_READINESS_AUDIT.md` | 현재 코드 기준 출시 차단(P0), 권장(P1), 출시 후(P2) 항목 | 출시 후보 빌드 또는 제출 조건 변경 시 |
| `PROGRESS.md` | 구현 완료·진행·다음 작업 현황 | 모든 기능 작업 완료 시 |
| `CHANGELOG.md` | 버전별 사용자 관점 변경 사항 | 커밋 또는 릴리스 단위 |

## 문서 상태

- **현재 기준**: README, DOCS_INDEX, PROJECT_PLAN, GAME_DESIGN, NEW_PLAYER_ONBOARDING, ARCHITECTURE, BALANCE_BASELINE, UI_UX_SPEC, ROADMAP, TESTING, STORE_LISTING, PRIVACY, TERMS, RELEASE_CHECKLIST, RELEASE_READINESS_AUDIT.
- **구현 이력/참고**: BETA_IMPLEMENTATION_ROADMAP, ALPHA_PLAYTEST_AUDIT 및 번호가 붙은 과거 polish/finalization 문서. 당시 결정 근거를 보존하지만 현재 수량·버전·출시 판정에는 사용하지 않는다.
- 충돌 시 `코드/자동 감사 → RELEASE_READINESS_AUDIT → 현재 기준 문서 → 이력 문서` 순으로 판단한다.

## 의사결정 우선순위

1. 첨부된 10화면 비주얼 레퍼런스와 어울리는가.
2. 출시용 iOS/Android 가로 화면에서 조작과 정보 확인이 쉽고 Web 크기 변경에도 안전한가.
3. 캠프→계약→출전→보상→성장의 핵심 루프에 기여하는가.
4. Flutter + Flame에서 Web/iOS/Android 공통으로 안정적인가.
5. 500~1,000 유닛과 콘텐츠 확장을 감당할 수 있는가.

충돌이 있으면 상위 우선순위를 따른다. 변경 이유와 영향을 해당 문서와 `CHANGELOG.md`에 기록한다.

## 작업 완료 정의

기능은 다음 조건을 모두 만족해야 완료다.

- 기획 의도와 예외 상태가 문서화되어 있다.
- 기능과 UI가 실제 플레이 흐름에 연결되어 있다.
- 기본 Material UI나 장기 플레이스홀더가 남아 있지 않다.
- `flutter analyze`, 관련 테스트, Web 릴리스 빌드가 통과한다.
- 1280×720 및 모바일 가로 비율에서 시각 검증을 완료한다.
- `PROGRESS.md`, `CHANGELOG.md`를 갱신하고 Git 커밋을 남긴다.
