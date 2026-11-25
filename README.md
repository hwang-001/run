# 무랑 런 · MURANG RUN

**v0.2** · 계산기와 하트를 단 무랑이와 함께 세 레인을 달리는 3D 아케이드 게임입니다. 시티 파크에서 출발해 1,500m의 산호빛 항구까지 달려 보세요.

[Windows x64 다운로드](https://github.com/hwang-001/run/releases/download/v0.2.0/MurangRun-v0.2-Windows-x64.zip) · [웹 빌드 다운로드](https://github.com/hwang-001/run/releases/download/v0.2.0/MurangRun-v0.2-Web.zip) · [v0.2 릴리스](https://github.com/hwang-001/run/releases/tag/v0.2.0)

Windows에서는 ZIP을 풀고 **MurangRun.exe**를 실행하세요. 게임 데이터가 실행 파일에 포함되어 있어 Godot 설치나 인터넷 연결 없이 플레이할 수 있습니다. 실행 파일에는 배포자 코드 서명이 없습니다.

웹 ZIP을 푼 폴더를 HTTP 서버로 제공하면 PC 및 모바일의 WebGL 2 브라우저에서 플레이할 수 있습니다. GitHub Pages를 운영할 경우 저장소 **Settings → Pages → Source**에서 **GitHub Actions**를 선택하고 **Web build and release validation** 워크플로를 실행하세요.

## v0.2 변경점

- **시티 파크**에는 새 아스팔트 표면, 활엽수, 안내판, 새로운 상자와 금화 모델을 적용했습니다.
- **산호빛 항구**에서는 목재 부두, 모래 해안, 야자수, 낮은 상점, 전망탑, 돛배를 배치했습니다. 물결·포말, 별도의 하늘과 석양 조명, 항구 테마 음악과 파도 소리가 이어집니다.
- **1,476m**부터 해안이 보이기 시작합니다. **1,500m**에서 지면 높이가 이어지는 부두로 진입하며, 카메라와 입력 및 주행 상태가 유지됩니다. 배경과 음악은 진입 전에 섞여 전환됩니다.
- 항구에서는 통, 화물 상자, 로프 가로막이, 짐을 실은 작은 배가 등장합니다. 일반 장애물 줄 간격은 12m, 본격적인 항구의 간격은 9m입니다. 달리기 속도는 항구에서도 계속 올라 최대 28m/s에 도달합니다. 모든 줄에는 열린 레인이 있으며 연속 줄의 열린 레인까지 한 번의 레인 이동으로 닿을 수 있습니다.
- 무랑이의 원래 얼굴, 계산기, 하트와 꼬리를 유지했습니다. 털 색에 명암을 입히고 발바닥 패드, 속도별 보폭, 착지 압축, 슬라이딩 자세, 후방 추적 카메라를 개선했습니다.
- 반응형 시작·일시정지·결과 화면과 HUD를 정리했습니다. 구간 진입 배너, 코인 아이콘 펄스, 점수 보간, 신기록 글린트 효과가 포함됩니다.

## 플레이와 기록

| 동작 | PC | 모바일 웹 |
|---|---|---|
| 레인 이동 | A / D 또는 ← / → | 좌우 스와이프 |
| 점프 | W, Space 또는 ↑ | 위쪽 스와이프 |
| 슬라이드 | S 또는 ↓ | 아래쪽 스와이프 |
| 일시정지 | Esc 또는 화면 버튼 | 화면 버튼 |
| 게임 시작 / 재도전 | Enter 또는 화면 버튼 | 화면 버튼 |

**게임 시작**은 0m부터, **신규 맵 테스트**는 1,500m부터 시작합니다. 테스트에도 같은 거리 기준의 속도와 장애물 규칙을 사용합니다. 시작 체력은 하트 3개이며 점수와 코인은 0입니다. 테스트에서 얻은 점수, 최대 거리, 코인은 기존 기록과 누적 코인에 반영되지 않습니다. 테스트 기능은 `scripts/tuning.gd`의 `ENABLE_DISTRICT_TEST`로 끌 수 있습니다.

일반 주행 점수는 1m당 2점, 코인당 25점입니다. 최고 점수, 최대 이동 거리, 누적 코인은 v0.1과 동일한 `user://records.cfg`에 저장됩니다. 웹 데이터는 같은 사이트 주소와 같은 브라우저 프로필에서 이어집니다.

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

Windows는 게임 데이터가 내장된 단일 x64 실행 파일입니다. Web Export는 Compatibility 렌더러와 단일 스레드 템플릿을 사용합니다. GitHub Actions는 버전 태그를 기준으로 두 플랫폼을 빌드하고 릴리스 ZIP으로 묶습니다.

## 구조와 테스트

- `scripts/tuning.gd`의 거리별 속도, 장애물 밀도와 지역 설정을 일반 주행과 테스트 시작에서 공유합니다.
- `scripts/track.gd`는 36m 청크 7개와 장애물·코인 슬롯을 재사용합니다. 두 테마의 지형을 준비하고 필요한 타일만 표시하며, 반복 장식은 일부를 MultiMesh로 묶습니다.
- `scripts/coast_scenery.gd`는 항구 지형과 오브젝트 배치를, `scripts/runner_audio.gd`는 지역 전환 때의 음량 혼합을 담당합니다.
- `tools/model_murang.py`로 Blender에서 무랑이 GLB를 다시 생성할 수 있습니다. 교체 모델은 `Body`, `Head`, `Tail`, `Heart`, `ArmL/R`, `LegL/R` 피벗과 Godot의 −Z 전방을 맞춥니다.

~~~sh
godot --headless --editor --import --path .
XDG_DATA_HOME="$(mktemp -d)" godot --headless --path . --script tests/smoke.gd
~~~

자동 테스트는 조작, 충돌, 점프와 슬라이드, 코인, 구버전 기록 읽기, 게임 오버와 재시작, 1,500m 통과, 테스트 기록 격리를 확인합니다. 12개 시드에서 열린 레인 경로와 최소 이동 시간을 검사하고, 12분 분량의 시뮬레이션에서 노드 수를 유지한 채 519회 청크를 재사용하는 것을 확인했습니다. Chromium에서 데스크톱 및 모바일 터치 화면을 확인했습니다. 실물 저사양 모바일의 장시간 FPS와 Safari/iOS 호환성은 별도 검증이 필요합니다.

## 에셋 및 라이선스

| 리소스 | 출처 |
|---|---|
| 도로, 보도, 가로등, 근린 상가, 광장, 일부 효과음 | [Kenney Starter Kit City Builder](https://github.com/KenneyNL/Starter-Kit-City-Builder), [MIT](assets/city/LICENSE.md). |
| 상업 건물, 자연물, 시티 장애물, 금화, 항구 시설과 배·화물 | [Kenney City Kit Commercial, City Kit Roads, Nature Kit, Platformer Kit, Pirate Kit](https://github.com/Hidencod/tge-assets), [CC0 1.0](assets/props/LICENSE). Tiny Game Engine 모델 라이브러리 변환본을 사용했습니다. |
| 트럭과 충돌음, 점프·착지·코인 등 효과음 | [Kenney Starter Kit Racing](https://github.com/KenneyNL/Starter-Kit-Racing), [Kenney Starter Kit 3D Platformer](https://github.com/KenneyNL/Starter-Kit-3D-Platformer), 각각 MIT. |
| 아스팔트, 목재, 모래, 두 하늘 파노라마 | [Poly Haven 출처 목록](assets/surfaces/LICENSE.txt), CC0 1.0. 디퓨즈 텍스처를 소형화하고 파노라마를 톤 매핑했습니다. |
| HUD와 버튼 아이콘 | [Lucide](https://lucide.dev), [ISC 및 MIT 고지](assets/ui/lucide/LICENSE.txt). 공식 아이콘을 투명 PNG로 변환했습니다. |
| 글꼴 | [Gowun Dodum](assets/ui/OFL-GowunDodum.txt), [Outfit](assets/ui/OFL-Outfit.txt), SIL OFL 1.1. |
| 무랑이 GLB, 타이틀 일러스트, 음악과 파도 효과음 | 무랑 런 전용 제작. 음악은 `tools/compose_music.py`로 생성했습니다. |
