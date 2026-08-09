# 월식 용병단

Flutter + Flame 기반 수인 용병단 로그라이트 서바이버입니다. Web을 우선 개발·검증 환경으로 사용하고 iOS와 Android를 최종 타깃으로 합니다.

## 실행

```bash
flutter pub get
flutter run -d chrome
```

현재 플레이 루프는 `캠프 → 전쟁 계약 → Flame 전투 → 레벨업/전장 사건 → 승리 보상`입니다. 캠프의 `용병` 메뉴에서 루나의 상세 화면도 확인할 수 있습니다.

## 조작

- 전투 화면 누르기/드래그: 루나 이동
- 공격: 가장 가까운 적 자동 공격
- 레벨업: 세 가지 강화 중 하나 선택

상세 설계는 `GAME_DESIGN.md`, 구조는 `ARCHITECTURE.md`, 현재 상태는 `PROGRESS.md`를 참고하십시오.
