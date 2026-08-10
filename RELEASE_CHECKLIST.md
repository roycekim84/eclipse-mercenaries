# B6 베타 출시 체크리스트

## 자동 완료

- [x] 버전 `0.9.0+9`, 표시명, Android/iOS 식별자 고정
- [x] Android `sensorLandscape`, iOS/iPad 두 가로 방향 정적 검사
- [x] SafeArea 및 1280×720·844×390·세로 Web 비차단 안내 회귀
- [x] 앱 아이콘, Android adaptive icon, iOS AppIcon, 다크 스플래시 적용
- [x] 캠프·계약·결과 2208×1242 스토어 스크린샷 초안
- [x] 개인정보·약관·스토어 메타데이터 초안
- [x] analyze, 전체 테스트, 콘텐츠 감사, Web release
- [x] Android release APK 및 iOS `--no-codesign` 빌드 절차
- [x] GitHub Pages 자동 배포와 모바일 비서명 빌드 CI

검증 산출물: Android release APK 89.1MB, iOS unsigned Runner.app 59.9MB. iOS는 저장소 경로의 Finder 확장 속성 때문에 직접 빌드가 거절될 경우 `/tmp`의 확장 속성 없는 복제본에서 성공하는 절차를 사용한다.

## 사용자 지시에 따라 제외

- 실제 저·중·고사양 기기 측정
- 외부 10명 또는 별도 사용자 테스트 요청
- TestFlight/Play Console 설치·심사·서명 배포
- 블루투스 오디오, 실제 전화/알림, 발열의 실기기 측정

## 스토어 제출 직전 소유자 확인 필요

- [ ] Apple/Google 개발자 계정의 법적 판매자명·지원 이메일 확정
- [ ] 배포 인증서·키스토어·프로비저닝을 CI 비밀에 주입
- [ ] 개인정보처리방침을 독립 공개 URL에 게시하고 Data safety/App Privacy 답변과 대조
- [ ] 연령 등급·콘텐츠 설문·국가별 법률/현지화 검토
- [ ] 실제 기기 검사를 재개하기로 결정한 경우 별도 B7 체크리스트에서 수행

## 서명 비밀 경계

저장소에는 인증서, 프로비저닝 프로필, 키스토어 또는 비밀번호를 커밋하지 않는다. Android는 `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`, `ANDROID_STORE_PASSWORD`, iOS는 배포 인증서·프로필·App Store Connect API key를 저장소 환경 비밀에서 주입한다.
