# 무랑 런 · MURANG RUN

**v0.3** · 계산기와 하트를 단 무랑이가 세 레인을 달리는 3D 아케이드 게임입니다. 시티 파크에서 출발해 1,500m의 산호빛 항구와 3,000m의 솔바람 계곡까지 달려 보세요.

[Windows x64 다운로드](https://github.com/hwang-001/run/releases/download/v0.3.0/MurangRun-v0.3-Windows-x64.zip) · [웹 빌드 다운로드](https://github.com/hwang-001/run/releases/download/v0.3.0/MurangRun-v0.3-Web.zip) · [v0.3 릴리스](https://github.com/hwang-001/run/releases/tag/v0.3.0)

Windows에서는 ZIP을 풀고 **MurangRun.exe**를 실행하세요. 게임 데이터가 실행 파일에 포함되어 있어 Godot 설치나 인터넷 연결 없이 플레이할 수 있습니다. 배포 실행 파일에는 코드 서명이 없습니다.

웹 ZIP을 푼 폴더를 HTTP 서버로 제공하면 PC와 모바일의 WebGL 2 브라우저에서 실행할 수 있습니다. GitHub Pages를 운영할 경우 저장소 **Settings → Pages → Source**에서 **GitHub Actions**를 선택하고 **Web build and release validation** 워크플로를 실행하세요.

## v0.3 변경점

- **관절 슬라이딩**은 `AnimationPlayer` 클립으로 허리, 상체, 엉덩이, 무릎, 팔을 움직입니다. 몸을 낮추고 다리를 앞으로 뻗은 뒤 다시 일어나며, 이 과정에서 모델 스케일은 그대로입니다. 자세에 맞춰 충돌 높이와 카메라 높이가 바뀌고 마찰음, 먼지, 스키드 자국이 따라옵니다.
- **가속 연출**은 실제 속도 8.5, 14, 22, 29m/s 구간을 기준으로 보간합니다. 세계 공간의 바람, 화면 가장자리 속도선, 잔상, 먼지와 지역 입자, 바람 소리, 달리기 자세와 카메라 시야각이 함께 바뀝니다. 속도는 32m/s에서 제한합니다.
- **솔바람 계곡**에는 소나무, 숲길, 이끼색 절벽, 시냇물, 폭포와 목재 다리를 배치했습니다. 바람에 움직이는 잎과 흩날리는 잎사귀, 나무 사이 햇빛, 계곡 테마 음악과 새소리가 적용됩니다. 2,940m부터 부두 옆에 소나무와 수풀이 늘어나고, 3,000m에서 속도와 기록을 유지하며 새 구간에 진입합니다.
- 계곡 전용 장애물은 통나무, 바위, 울타리, 낮은 가지, 나무 상자와 통나무 벽입니다. 정상 주행과 테스트는 같은 장애물 간격과 속도 규칙을 사용합니다. 각 줄의 열린 레인은 다음 줄까지 한 번의 레인 이동으로 닿을 수 있습니다.
- **희귀 하트**는 500m부터 100m 간격의 지점에서 10% 확률로 판정합니다. 한 번 나오면 800m 동안 다음 하트가 나오지 않습니다. 주행 시드와 거리로 판정하며 현재 체력의 영향을 받지 않습니다. 체력이 비었을 때 한 칸을 회복하고 `HP +1`과 HUD 애니메이션을 표시합니다. 최대 체력에서 주운 하트는 점수, 코인, 추가 체력을 주지 않습니다.
- 시작과 일시정지 화면의 **그래픽 표준 / 그래픽 낮음** 버튼으로 품질을 바꿀 수 있습니다. 낮음은 3D 해상도와 입자 수를 줄이고 방향광 실시간 그림자와 고속 잔상을 끕니다. 설정은 `user://display.cfg`에 저장됩니다.

## 조작, 테스트 주행, 기록

| 동작 | PC | 모바일 웹 |
|---|---|---|
| 레인 이동 | A / D 또는 ← / → | 좌우 스와이프 |
| 점프 | W, Space 또는 ↑ | 위쪽 스와이프 |
| 슬라이드 | S 또는 ↓ | 아래쪽 스와이프 |
| 일시정지 | Esc 또는 화면 버튼 | 화면 버튼 |
| 게임 시작 / 재도전 | Enter 또는 화면 버튼 | 화면 버튼 |
| 하트 강제 배치 | 테스트 중 H 또는 **하트 생성** | 테스트 중 **하트 생성** |

**게임 시작**은 0m, **해변 맵 테스트**는 1,500m, **신규 숲 맵 테스트**는 3,000m에서 출발합니다. 테스트의 시작 체력은 3칸이고 점수와 코인은 0입니다. 해당 거리의 속도, 난이도 및 시각 효과가 즉시 적용됩니다. 테스트 점수와 최대 거리, 코인은 일반 기록에 합산되지 않습니다. `scripts/tuning.gd`의 `ENABLE_DISTRICT_TEST`로 테스트 시작과 강제 하트를 끌 수 있습니다.

일반 주행 점수는 1m당 2점과 코인당 25점입니다. 최고 점수, 최대 이동 거리, 누적 코인은 v0.2와 같은 `user://records.cfg`를 사용합니다. 웹 데이터는 같은 사이트 주소와 같은 브라우저 프로필에서 이어집니다.

## 실행 및 빌드

[Godot 4.7.2 표준 버전](https://godotengine.org/download/archive/4.7.2-stable/)으로 `project.godot`을 열고 **F5**를 누르세요. 내보내기에는 같은 버전의 공식 Export Templates가 필요합니다.

~~~sh
mkdir -p build/windows build/web
touch build/.gdignore
godot --headless --editor --import --path .
godot --headless --export-release "Windows Desktop" build/windows/MurangRun.exe
godot --headless --export-release Web build/web/index.html
python -m http.server 8080 --directory build/web
~~~

Compatibility 렌더러를 사용합니다. Web Export는 단일 스레드 템플릿을, Windows Export는 게임 데이터를 내장한 x64 실행 파일을 사용합니다. GitHub Actions의 버전 태그 빌드는 두 ZIP과 SHA-256 목록을 만듭니다.

## 구조와 검증

- `scripts/slide_pose.gd`는 재생 시점별 관절 포즈를 정의합니다. `scripts/player.gd`가 이를 달리기 자세에 섞고, 같은 포즈로 충돌 높이를 계산합니다.
- `scripts/runner_motion_fx.gd`는 바람, 잔상, 지면 자국과 지역 입자 풀을 관리합니다. 속도 단계, 하트 판정 거리, 난이도 변수는 `scripts/tuning.gd`에 있습니다.
- `scripts/track.gd`는 36m 청크 7개와 코인, 장애물, 하트 노드를 재사용합니다. 각 구간에 맞는 타일만 표시하고, 반복 장식은 일부를 MultiMesh로 묶습니다. `scripts/forest_scenery.gd`는 계곡 배치를, `scripts/heart_schedule.gd`는 거리 기반 하트 판정을 관리합니다.
- Blender에서 `tools/model_murang.py`로 무랑이 GLB를 다시 생성할 수 있습니다. 교체 모델은 `Body`, `Head`, `Tail`, `Heart`, `ArmL/R`, `LegL/R`, `KneeL/R` 피벗과 Godot의 −Z 전방을 맞춥니다.

~~~sh
godot --headless --editor --import --path .
XDG_DATA_HOME="$(mktemp -d)" godot --headless --path . --script tests/smoke.gd
~~~

자동 테스트에서 캐릭터 비율과 관절 자세, 슬라이딩 중 레인 이동, 키보드·스와이프, 1,500m·3,000m 전환, 고속 충돌과 회복, 구버전 기록 및 테스트 기록 격리를 확인했습니다. 100개 시드의 적격 하트 판정 11,013회 중 1,102회가 등장했습니다. 12분 분량을 시뮬레이션해 노드 수를 유지하며 청크를 580회 재사용하는 것을 확인했습니다. 실물 저사양 모바일의 장시간 FPS와 Safari/iOS 호환성은 별도 검증이 필요합니다.

## 에셋 및 라이선스

| 리소스 | 출처 |
|---|---|
| 시티 도로, 보도, 가로등, 상가, 광장, 일부 효과음 | [Kenney Starter Kit City Builder](https://github.com/KenneyNL/Starter-Kit-City-Builder), [MIT](assets/city/LICENSE.md). |
| 시티 상업 건물, 항구 시설과 선박, 산림과 절벽, 다리, 새 장애물, 금화와 하트 | [Kenney City, Nature, Platformer, Castle, Pirate Kit](https://github.com/Hidencod/tge-assets), [CC0 1.0](assets/props/LICENSE). Tiny Game Engine의 GLB 변환본에 계곡용 재질과 바람을 적용했습니다. |
| 트럭과 충돌음, 점프·착지·코인 효과음 | [Kenney Starter Kit Racing](https://github.com/KenneyNL/Starter-Kit-Racing), [Kenney Starter Kit 3D Platformer](https://github.com/KenneyNL/Starter-Kit-3D-Platformer), 각각 MIT. |
| 아스팔트, 목재, 모래, 숲 흙길과 세 하늘 파노라마 | [Poly Haven 출처 목록](assets/surfaces/LICENSE.txt), CC0 1.0. 텍스처를 소형화하고 파노라마를 톤 매핑했습니다. |
| 버튼, HUD와 지역 아이콘 | [Lucide](https://lucide.dev), [ISC 및 MIT 고지](assets/ui/lucide/LICENSE.txt). |
| 글꼴 | [Gowun Dodum](assets/ui/OFL-GowunDodum.txt), [Outfit](assets/ui/OFL-Outfit.txt), SIL OFL 1.1. |
| 무랑이 GLB, 타이틀 일러스트, 음악, 바람·마찰·회복·환경음 | 무랑 런 전용 제작. 음악과 효과음은 `tools/compose_music.py`, `tools/compose_effects.py`에서 생성합니다. |
