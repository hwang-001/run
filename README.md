# 무랑 런 · MURANG RUN

**v0.4** · 계산기와 하트를 단 무랑이가 세 레인을 달리는 3D 아케이드 게임입니다. 시티 파크에서 출발해 산호빛 항구와 솔바람 계곡을 지나 네온 시티까지 이어집니다.

[Windows x64 다운로드](https://github.com/hwang-001/run/releases/download/v0.4.1/MurangRun-v0.4-Windows-x64.zip) · [웹 빌드 다운로드](https://github.com/hwang-001/run/releases/download/v0.4.1/MurangRun-v0.4-Web.zip) · [v0.4 릴리스](https://github.com/hwang-001/run/releases/tag/v0.4.1)

Windows에서는 ZIP을 풀고 **MurangRun.exe**를 실행하세요. 게임 데이터가 실행 파일에 포함되어 있어 Godot 설치나 인터넷 연결 없이 플레이할 수 있습니다. 배포 실행 파일에는 코드 서명이 없습니다.

웹 ZIP을 푼 폴더를 HTTP 서버로 제공하면 WebGL 2 브라우저에서 실행할 수 있습니다. 기본 제공된 웹 빌드는 서버에 올릴 파일 묶음입니다.

## v0.4에서 달라진 점

- **시작 화면**은 항구의 실제 3D 씬에서 무랑이가 대기하는 모습을 보여줍니다. 캐릭터 대기 동작, 카메라 이동, 야자수와 바다 움직임이 이어집니다. 시작 버튼, 최고 기록과 누적 코인을 바로 확인할 수 있습니다.
- **장애물 가시성**은 전 구간에서 황색 지면 표식과 회피 기호로 보완했습니다. ▲는 점프, ▼는 슬라이드, ‹ ›는 레인 변경입니다. 솔바람 계곡은 길가 식생과 바위의 색을 차분하게 조정하고 장애물에 황토색과 주황색을 사용합니다.
- **네온 시티**는 4,440m부터 가로등과 고층 건물이 보이고, 4,476m부터 젖은 아스팔트가 이어집니다. 4,500m부터 상점, 전광판, 드론, 셔틀, 모노레일, 홀로그램이 있는 도심과 전용 장애물이 나옵니다. 하늘과 조명, 음악, 도시 환경음이 전환되며 체력, 주행 기록과 진행 중인 감속 시간이 이어집니다.
- **속도와 시야**에 따라 카메라 시야각, 무랑이 동작, 바람, 빛의 궤적, 잔상의 강도가 바뀝니다. 네온 궤적은 도로 경계와 화면 가장자리에 집중됩니다. 그래픽 낮음은 3D 해상도, 실시간 그림자, 잔상, 입자 수, 전광판 움직임과 노면 반사를 줄입니다.
- 결과 화면은 최종 점수, 거리, 획득 코인과 최고 기록을 보여줍니다. 최고 점수를 경신하면 결과에 표시됩니다.

[시작 화면과 숲 비교](docs/v04-comparison.webp) · [네온 시티와 슬로우 타임 실제 플레이](docs/v04-neon.webp)

## 스테이지와 밸런스

| 거리 | 지역 | 기본 주행 속도 |
|---|---|---|
| 0~1,499m | 시티 파크 | 8.5m/s부터 기존 속도로 가속 |
| 1,500~2,999m | 산호빛 항구 | 약 21.5m/s부터 기존 속도로 가속 |
| 3,000~4,499m | 솔바람 계곡 | 약 29.2m/s부터 가속 폭 완화 |
| 4,500m 이상 | 네온 시티 | 약 30.1m/s에서 30.6m/s로 수렴 |

숲부터 장애물 줄을 12m 간격으로 배치해 최고 속도에서도 줄 사이가 약 0.39초입니다. 연속 두 줄에 두 개씩 장애물이 나오지 않고, 열린 레인 사이를 한 번의 레인 이동으로 오갈 수 있습니다.

| 아이템 | 처음 등장 | 등장 판정 | 최소 재등장 거리 | 효과 |
|---|---:|---|---:|---|
| 회복 하트 | 500m | 100m마다 10% | 800m | 빈 체력 한 칸 회복 |
| 슬로우 타임 | 3,000m | 100m마다 20% | 300m | 6초간 전진 속도 20% 감소, 1.5초간 부드럽게 복귀 |

슬로우 타임은 파란 모래시계를 주우면 곧바로 시작됩니다. 감속과 복귀 중에는 추가로 발동하지 않습니다. 거리와 점수는 실제 전진 속도로 계산되며 점프, 슬라이드, 레인 이동은 정상 시간으로 동작합니다. 자연 생성은 하트가 먼저 결정되므로 같은 거리 표식에 두 아이템이 생기지 않습니다. 픽업은 근처 장애물 줄의 열린 레인에 배치합니다.

## 조작과 저장

| 동작 | PC | 모바일 웹 |
|---|---|---|
| 레인 이동 | A / D 또는 ← / → | 좌우 스와이프 |
| 점프 | W, Space 또는 ↑ | 위쪽 스와이프 |
| 슬라이드 | S 또는 ↓ | 아래쪽 스와이프 |
| 일시정지 | Esc 또는 화면 버튼 | 화면 버튼 |
| 게임 시작 / 재도전 | Enter 또는 화면 버튼 | 화면 버튼 |
| 회복 하트 배치 | 테스트 중 H | 테스트 중 **하트** |
| 슬로우 타임 배치 | 테스트 중 T | 테스트 중 **감속** |

**개발자 테스트**에서 각 스테이지의 첫 거리인 0m, 1,500m, 3,000m, 4,500m로 바로 이동할 수 있습니다. 개발자 HUD는 기본 속도, 실제 속도, 감속 시간을 표시하며 **장애물 윤곽**으로 충돌 영역을 확인할 수 있습니다. 테스트 점수, 누적 코인과 최대 거리는 일반 저장에 반영되지 않습니다. 테스트 메뉴와 주행 중 디버그 기능은 `scripts/tuning.gd`의 `ENABLE_DISTRICT_TEST`로 끌 수 있습니다.

일반 주행 점수는 1m당 2점과 코인당 25점입니다. 최고 점수, 최대 거리, 누적 코인은 기존 `user://records.cfg`에서 이어집니다. 웹에서는 같은 사이트 주소와 같은 브라우저 프로필이 필요합니다. 그래픽과 소리 설정은 `user://display.cfg`에 저장됩니다.

## 실행, 내보내기와 검증

[Godot 4.7.2 표준 버전](https://godotengine.org/download/archive/4.7.2-stable/)으로 `project.godot`을 열고 **F5**로 실행합니다. 내보내기에는 엔진과 같은 버전의 공식 Export Templates가 필요합니다.

~~~sh
mkdir -p build/windows build/web
touch build/.gdignore
godot --headless --editor --import --path .
XDG_DATA_HOME="$(mktemp -d)" godot --headless --path . --script tests/smoke.gd
godot --headless --export-release "Windows Desktop" build/windows/MurangRun.exe
godot --headless --export-release Web build/web/index.html
python -m http.server 8080 --directory build/web
~~~

Godot Compatibility 렌더러와 웹 단일 스레드 템플릿을 사용합니다. 버전 태그를 푸시하면 GitHub Actions가 Windows x64와 Web ZIP, SHA-256 목록을 만들고 Windows에서 배포된 실행 파일을 시작해 확인합니다. 트랙은 36m 청크 7개, 장애물, 픽업을 재사용합니다. 반복되는 정적 모델은 일부를 MultiMesh로 묶고, 네온 반사는 노면 셰이더로 표현합니다.

자동 검증에서 키보드·스와이프, 점프와 슬라이딩, 충돌과 저장, 12개 코스 시드의 열린 레인, 1,500m·3,000m·4,500m 전환과 아이템 유지, 테스트 기록 격리와 감속 복귀를 확인했습니다. 100개 시드에서 적격 하트 11,013회 중 1,102회(10.01%), 적격 슬로우 타임 10,987회 중 2,252회(20.50%)가 생성됐습니다. 12분 시뮬레이션 동안 노드 수가 유지됐고 청크가 558회 재사용됐습니다.

실제 게임 프레임은 Linux의 Compatibility 렌더러에서 캡처했습니다. Chromium에서 데스크톱 키보드와 390×844 터치 화면으로 숲 및 네온 시티 주행을 확인했습니다. 실물 저사양 모바일의 FPS와 Safari/iOS, Windows GPU별 렌더링 성능은 측정하지 않았습니다.

## 에셋 및 라이선스

| 리소스 | 출처와 적용 |
|---|---|
| 네온 시티 3D 모델 27종 | Kenney [City Kit Commercial](https://kenney.nl/assets/city-kit-commercial), [City Kit Roads](https://kenney.nl/assets/city-kit-roads), [Space Kit](https://kenney.nl/assets/space-kit), [Car Kit](https://kenney.nl/assets/car-kit), [Blaster Kit](https://kenney.nl/assets/blaster-kit). [Tiny Game Engine GLB 변환본](https://github.com/Hidencod/tge-assets)의 [CC0 1.0 모델](assets/props/LICENSE)을 고층 건물, 상점의 차양, 신호등, 차량, 홀로그램, 교통시설과 충돌 장애물에 적용했습니다. 외벽 팔레트, 유리창 발광과 전광판은 무랑 런에 맞춰 조정했습니다. |
| 시티 파크, 항구와 계곡 시설 | [Kenney Starter Kit City Builder](https://github.com/KenneyNL/Starter-Kit-City-Builder), [MIT](assets/city/LICENSE.md), Kenney Nature, Platformer, Castle, Pirate Kit의 [CC0 1.0 GLB 변환본](https://github.com/Hidencod/tge-assets). 산호빛 항구 야자수와 계곡 식생에 바람 재질을 적용했습니다. |
| 트럭과 충돌음, 점프·착지·코인 효과음 | [Kenney Starter Kit Racing](https://github.com/KenneyNL/Starter-Kit-Racing)과 [Kenney Starter Kit 3D Platformer](https://github.com/KenneyNL/Starter-Kit-3D-Platformer), 각각 MIT. |
| 아스팔트, 목재, 모래, 숲 흙길과 하늘 | [Poly Haven, CC0 1.0](assets/surfaces/LICENSE.txt). 네온 시티에는 [Qwantani Night Pure Sky](https://polyhaven.com/a/qwantani_night_puresky) HDR을 톤 매핑해 적용했습니다. |
| UI 아이콘과 글꼴 | [Lucide](https://lucide.dev), [ISC 및 MIT 고지](assets/ui/lucide/LICENSE.txt). [Black Han Sans](assets/ui/OFL-BlackHanSans.txt), [Gowun Dodum](assets/ui/OFL-GowunDodum.txt), [Outfit](assets/ui/OFL-Outfit.txt)은 SIL OFL 1.1입니다. |
| 무랑이, 파란 모래시계, VFX, 배경음악과 환경음 | 무랑이 모델은 사용자가 제공한 원화에 기반합니다. 스타일과 배포 조건이 맞는 외부 모래시계를 확보하지 못해 `tools/model_slow_time.py`로 제작했습니다. 지역 음악과 바람, 마찰, 회복음, 감속음, 미래 차량 소리는 `tools/compose_music.py`와 `tools/compose_effects.py`에서 생성합니다. |
