# 출시 제출 체크리스트

기준일: 2026-08-20

현재 버전: `0.14.1+25`

상세 위험과 개선 근거: `RELEASE_READINESS_AUDIT.md`

## A. 코드·콘텐츠 자동 검증

- [x] 앱 표시명과 Android/iOS 식별자 `com.roycekim.eclipsemercenaries` 고정
- [x] Android `sensorLandscape`, iPhone/iPad 두 가로 방향 선언
- [x] SafeArea, 컴팩트 가로, Web 세로 비차단 안내 회귀
- [x] 저장 schema 15 및 구버전 마이그레이션·백업·완전 초기화
- [x] 16명 용병, 16무기, 27적, 24사건, 10계약, 24임무 콘텐츠 연결 검사
- [x] Golden 5화면과 Pages Web 자동 배포
- [x] 모바일 비서명 Android/iOS 빌드 CI
- [x] 2026-08-20 문서 감사 커밋에서 analyze·126 tests·content audit·Web release 재실행
- [ ] 제출 버전/빌드 번호와 Git tag 동결

## B. 화면·에셋

- [x] 앱 아이콘, adaptive icon, iOS AppIcon, 가로 스플래시
- [x] 용병·무기·적·사건·상점·VFX 최종 자산 및 누락 경로 검사
- [x] Noto Sans KR/Cinzel 내장 폰트와 Golden 글꼴 메트릭
- [ ] 모든 콘텐츠 문자열을 포함하는 한글 글리프/tofu 자동 검사
- [ ] 현재 release 빌드에서 스토어 스크린샷 6–8장 재촬영
- [ ] 캡처에 디버그 정보, overflow, 시스템 포인터, 잘못된 크롭이 없는지 승인
- [ ] AAB/IPA 실제 다운로드·설치 크기 기록 및 자산 예산 승인

현재 Pages release 산출물은 약 173MB다. 모바일 배포 크기와 동일하지 않지만 최적화 필요성을 보여주는 기준값으로 기록한다.

현재 3개 스토어 스크린샷은 과거 빌드 초안이다. 누락 글리프와 구버전 UI가 확인됐으므로 제출 자산으로 사용할 수 없다.

## C. 배포·서명

- [ ] Android production keystore를 CI secret에 주입
- [ ] 서명된 Android App Bundle 생성 및 Play App Signing 연결
- [ ] Apple 배포 인증서·프로비저닝·App Store Connect API key 연결
- [ ] iOS Archive/IPA 생성 및 내부 트랙 업로드
- [ ] 태그 기반 release workflow, checksum, release note, rollback 절차 확인

저장소에는 인증서, 프로비저닝 프로필, 키스토어 또는 비밀번호를 커밋하지 않는다.

## D. 스토어·법적 정보

- [ ] 법적 판매자명, 지원 이메일, 개인정보 문의 이메일 확정
- [ ] Privacy Policy와 Terms를 독립 공개 URL에 게시
- [ ] App Privacy/Data safety 답변을 현재 코드와 대조
- [ ] 연령 등급, 판타지 전투, 확률형 모집 설문 확정
- [ ] 첫 출시 언어를 한국어 전용 또는 한국어/영어로 명시
- [ ] LICENSE와 `THIRD_PARTY_NOTICES.md` 작성 및 앱 내 고지 연결
- [ ] 딥링크 내부 라우팅을 구현하거나 스토어 등록 정보에서 제거

## E. 제품 승인

- [x] 실제 결제·광고·회원가입·외부 분석 SDK 없음
- [x] 로컬 저장 한계와 삭제 방법 문서화
- [x] 5개 사운드 버스와 접근성/저사양 설정 저장·복원
- [ ] Lv.1→30 성장·보상·난이도 최종 수치 승인
- [ ] crash/ANR 관측을 스토어 콘솔만 사용할지 외부 SDK를 사용할지 결정

## F. 사용자 지시에 따라 수행하지 않는 검사

- 실제 저·중·고사양 기기 성능·발열 측정
- 외부 10명 사용자 테스트
- 블루투스 오디오, 실제 전화/알림 복귀, 노치별 실기기 검사

위 항목은 실행 범위에서 제외하지만 출시 위험으로는 남는다. 제출자는 이 위험을 수용하거나 제출 전에 별도로 재개해야 한다.

## 제출 판정

`RELEASE_READINESS_AUDIT.md`의 P0가 모두 닫히고, 이 문서의 B/C/D 미완료 항목이 해결돼야 `제출 가능`으로 판정한다. 현재 판정은 **출시 후보 / 제출 불가**다.
