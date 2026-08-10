# 월식 용병단

Flutter + Flame 기반 수인 용병단 로그라이트 서바이버입니다. Web을 우선 개발·검증 환경으로 사용하고 iOS와 Android를 최종 타깃으로 합니다.

## 실행

```bash
flutter pub get
flutter run -d chrome
```

진행 상태는 `shared_preferences`를 통해 Web local storage와 iOS/Android 플랫폼 저장소에 자동 저장됩니다.

첫 실행에서는 4단계 첫 계약 안내가 표시됩니다. 캠프 우상단 설정에서 큰 글자, 섬광 감소, 효과음, 진동, 화면 흔들림과 튜토리얼 다시 보기를 변경할 수 있습니다.

현재 플레이 루프는 `캠프 → 전쟁 계약 → Flame 전투 → 레벨업 → 전장 사건 선택 → 승리/후퇴/패배 → 보상 → 용병 훈련/무기 강화 → 모집/상점 → 다음 출전`입니다. 캠프에서는 3인 용병의 5개 상세 탭, 임무 보상, 대장간, 전리품 도감, 특별 용병 계약과 3종 상점을 확인할 수 있습니다.

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
- 구현 작업 기획: [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md)
- 기술 구조: [ARCHITECTURE.md](ARCHITECTURE.md)
- 이미지 에셋 스타일: [ASSET_STYLE_GUIDE.md](ASSET_STYLE_GUIDE.md)
- 화면별 UI/UX 명세: [UI_UX_SPEC.md](UI_UX_SPEC.md)
- 단계별 로드맵: [ROADMAP.md](ROADMAP.md)
- 현재 진행 상황: [PROGRESS.md](PROGRESS.md)
- 테스트 기준: [TESTING.md](TESTING.md)
