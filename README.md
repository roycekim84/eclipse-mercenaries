# 월식 용병단: Eclipse Mercenaries

최근 레퍼런스 비교 기반 UI/전투 개선 내역은 [VISUAL_POLISH_1_10.md](VISUAL_POLISH_1_10.md)에서 확인할 수 있습니다.

Flutter + Flame 기반 수인 용병단 로그라이트 서바이버입니다. Web을 우선 개발·검증 환경으로 사용하고 iOS와 Android를 최종 타깃으로 합니다.

## 베타 Web 플레이

- 게임 실행: [GitHub Pages에서 플레이](https://roycekim84.github.io/eclipse-mercenaries/)
- 테스트 의견: [플레이테스트 피드백 등록](https://github.com/roycekim84/eclipse-mercenaries/issues/new?template=playtest_feedback.yml)
- 버그 제보: [버그 리포트 등록](https://github.com/roycekim84/eclipse-mercenaries/issues/new?template=bug_report.yml)

iOS/Android 출시 빌드는 양쪽 가로 방향으로 고정됩니다. Web은 방향을 강제하지 않고 반응형 테스트 환경으로 유지합니다. 알파 저장 데이터는 현재 브라우저의 local storage에 보관되므로 브라우저 데이터 삭제 또는 시크릿 모드 종료 시 초기화될 수 있습니다.

## 실행

```bash
flutter pub get
flutter run -d chrome
```

진행 상태는 `shared_preferences`를 통해 Web local storage와 iOS/Android 플랫폼 저장소에 자동 저장됩니다.

첫 실행에서는 4단계 첫 계약 안내가 표시됩니다. 캠프 우상단 설정에서 큰 글자, 섬광 감소, 저사양 전투 모드, 효과음, 진동, 화면 흔들림과 튜토리얼 다시 보기를 변경할 수 있습니다.

현재 플레이 루프는 `캠프 → 전쟁 계약 → Flame 전투 → 레벨업 → 전장 사건 선택 → 승리/후퇴/패배 → 보상 → 용병 훈련/무기 강화 → 모집/상점 → 다음 출전`입니다. 신규 계정은 루나 한 명으로 시작하며, 모집한 용병은 최대 8명의 명부와 5개 상세 탭에서 성장시킬 수 있습니다. 캠프에서는 임무 보상, 대장간, 전리품 도감, 특별 용병 계약과 3종 상점도 확인할 수 있습니다.

## 조작

- 전투 화면 누르기/드래그: 루나 이동
- 공격: 가장 가까운 적 자동 공격
- 레벨업: 세 가지 강화 중 하나 선택
- 전장 사건: 전투가 정지되면 위험과 보상을 비교해 선택
- 결과: 계약·목표·전과·사건 보상과 전리품, MVP를 확인하고 귀환/재출전

## 프로젝트 문서

- 전체 문서 안내: [DOCS_INDEX.md](DOCS_INDEX.md)
- 제품/게임 전체 기획: [PROJECT_PLAN.md](PROJECT_PLAN.md)
- 게임 규칙과 알파 밸런스: [GAME_DESIGN.md](GAME_DESIGN.md)
- 신규 플레이어 시작·초기 경제: [NEW_PLAYER_ONBOARDING.md](NEW_PLAYER_ONBOARDING.md)
- 구현 작업 기획: [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md)
- 기술 구조: [ARCHITECTURE.md](ARCHITECTURE.md)
- 이미지 에셋 스타일: [ASSET_STYLE_GUIDE.md](ASSET_STYLE_GUIDE.md)
- 화면별 UI/UX 명세: [UI_UX_SPEC.md](UI_UX_SPEC.md)
- 단계별 로드맵: [ROADMAP.md](ROADMAP.md)
- 알파 이후 베타 구현 로드맵: [BETA_IMPLEMENTATION_ROADMAP.md](BETA_IMPLEMENTATION_ROADMAP.md)
- B0 알파 플레이테스트 감사표: [ALPHA_PLAYTEST_AUDIT.md](ALPHA_PLAYTEST_AUDIT.md)
- 스토어 등록 정보: [STORE_LISTING.md](STORE_LISTING.md)
- 개인정보처리방침: [PRIVACY.md](PRIVACY.md)
- 베타 이용약관: [TERMS.md](TERMS.md)
- B6 출시 체크리스트: [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md)
- 콘텐츠·밸런스 기준선: [BALANCE_BASELINE.md](BALANCE_BASELINE.md)
- 현재 진행 상황: [PROGRESS.md](PROGRESS.md)
- 테스트 기준: [TESTING.md](TESTING.md)
- 외부 테스트 안내: [PLAYTEST.md](PLAYTEST.md)
