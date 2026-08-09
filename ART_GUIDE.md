# 아트 가이드

이 문서는 빠르게 확인하는 핵심 요약이다. 제작 규격, ImageGen 워크플로, 파일명, 캐릭터/픽셀/배경/VFX QA는 `ASSET_STYLE_GUIDE.md`를 기준으로 한다.

## 최우선 기준

사용자가 제공한 10화면 합성 이미지를 UI/UX와 분위기의 최우선 기준으로 한다.

## 방향

- 전투: 32~48px 가독성을 기준으로 한 탑다운 픽셀 아트
- 메뉴: 검정·짙은 갈색 기반, 절제된 금색 금속 테두리, 남색/보라색 강조
- 캐릭터: 인간형 체형과 얼굴, 동물 귀와 꼬리를 지닌 일본 JRPG풍 수인
- 조명: 따뜻한 불빛과 차가운 달빛의 대비
- 재질: 낡은 가죽, 흑철, 어두운 목재, 천막, 유황과 재

## 루나 식별 요소

긴 검은 머리, 검은 고양이 귀와 한 개의 꼬리, 보라·검정 의상, 쌍검, 달빛 모티프를 일러스트·초상·픽셀 스프라이트에 일관되게 유지한다.

## 생성 자산

- `assets/images/mercenary_camp.png`: 내비게이션 영역을 고려한 야전 캠프 배경
- `assets/images/luna_belhardt.png`: 캐릭터 상세용 루나 전신 일러스트
- `assets/images/kael_rozenfang.png`: 늑대족 검투사 카일 전신 일러스트
- `assets/images/sera_inarion.png`: 여우족 환술사 세라 전신 일러스트
- `assets/images/characters/luna_battle_sheet.png`: 루나 8×5 전투 애니메이션 시트
- `assets/images/characters/kael_battle_sheet.png`: 카일 8×5 전투 애니메이션 시트
- `assets/images/characters/sera_battle_sheet.png`: 세라 8×5 전투 애니메이션 시트

생성 이미지에 글자를 굽지 않고 Flutter 레이어에서 접근성과 현지화를 처리한다.

전투 시트 행 순서는 `Idle → Walk → Attack → Hit → Dead`, 각 행은 8프레임이다. 런타임은 nearest-neighbor 필터를 사용하며, 현재 방향은 첨부 레퍼런스의 전투 시점에 맞춘 down-right 3/4 방향이다.
