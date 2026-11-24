# 무랑 런 · MURANG RUN

**v0.1** · 무랑이와 함께 시티 파크를 누비는 3D 무한 달리기 게임입니다. 세 개 레인 사이를 오가며 코인을 모으고, 상자는 뛰어넘고, 머리 위 바리케이드는 슬라이드로 통과하세요.

## Windows에서 실행

[Windows x64 버전 다운로드](https://github.com/hwang-001/run/releases/download/v0.1.0/MurangRun-v0.1-Windows-x64.zip)

ZIP을 풀고 **MurangRun.exe**를 실행하세요. Godot 설치나 네트워크 연결 없이 플레이할 수 있습니다. 실행 파일에 게임 데이터가 포함되어 있습니다. 이 배포본은 배포자 코드 서명이 없습니다.

## 조작

| 동작 | PC | 모바일 웹 |
|---|---|---|
| 레인 이동 | A / D 또는 ← / → | 좌우 스와이프 |
| 점프 | W, Space 또는 ↑ | 위쪽 스와이프 |
| 슬라이드 | S 또는 ↓ | 아래쪽 스와이프 |
| 일시정지 | Esc 또는 화면 버튼 | 화면 오른쪽 위 버튼 |
| 시작 / 재도전 | Enter 또는 화면 버튼 | 화면 버튼 |

하트는 3개입니다. 피격 직후에는 짧은 무적 시간이 생깁니다. 점수는 주행 거리 1m당 2점과 코인당 25점으로 계산합니다. 최고 점수, 최대 이동 거리, 누적 코인은 `user://records.cfg`에 저장합니다. 웹에서는 같은 사이트와 동일한 브라우저 프로필에서 기록이 이어집니다. 사이트 데이터 삭제 및 비공개 탐색에 따라 저장 기록이 초기화될 수 있습니다.

## Godot에서 열기

1. [Godot 4.7.2 표준 버전](https://godotengine.org/download/archive/4.7.2-stable/)에서 이 저장소의 `project.godot`을 엽니다.
2. 에셋 가져오기가 끝나면 **F5**로 메인 씬을 실행합니다.
3. 빌드하려면 **Editor → Manage Export Templates**에서 같은 버전의 공식 템플릿을 설치합니다.

터미널에서 다음 명령으로 빌드할 수 있습니다.

~~~sh
mkdir -p build/windows build/web
touch build/.gdignore
godot --headless --editor --import --path .
godot --headless --export-release "Windows Desktop" build/windows/MurangRun.exe
godot --headless --export-release Web build/web/index.html
python -m http.server 8080 --directory build/web
~~~

웹 빌드는 WebGL 2가 필요합니다. 서버에서 제공한 `index.html`로 접속하세요. Web Export는 GitHub Pages의 정적 호스팅과 호환되는 단일 스레드 템플릿을 사용합니다. 저장소 설정의 **Pages → Build and deployment → Source**를 **GitHub Actions**로 지정하면 포함된 워크플로가 `main`의 웹 빌드를 배포합니다.

## 구성

- `scripts/run.gd`는 게임 상태, 키보드와 터치 입력, 카메라 및 연출을 관리합니다.
- `scripts/player.gd`는 부드러운 레인 이동과 3D 캐릭터의 자세 및 애니메이션을 관리합니다.
- `scripts/track.gd`는 36m 맵 청크 7개를 재사용합니다. 모든 장애물 줄에 열린 레인이 남고, 다음 열린 레인까지 한 번의 레인 이동으로 닿을 수 있습니다. 열린 경로를 따라 코인 열이 이어지며 일부 코인은 점프 높이에 배치됩니다.
- `scripts/tuning.gd`에서 시작 속도, 가속도, 레인 이동 속도, 최대 속도와 장애물 간격을 조정할 수 있습니다.
- `scripts/save_game.gd`는 로컬 기록을 관리합니다.

정면 레퍼런스의 크림색 털, 분홍색 볼, 계산기와 하트를 보존하고 꼬리와 뒷모습은 새로 조형했습니다. 타이틀에 전용 일러스트를 사용하고, 주행에는 Blender로 제작한 파츠 기반 3D 모델을 사용합니다. 모델을 수정하려면 `blender -b --python tools/model_murang.py`로 GLB를 재생성하세요. 새 모델로 교체할 때는 `assets/character/murang.glb`의 경로 및 `Body`, `Head`, `Tail`, `Heart`, `ArmL/R`, `LegL/R` 피벗 이름을 유지하고, 전방을 Godot의 −Z축에 맞춥니다. 대기, 달리기, 좌우 이동 기울기, 점프, 슬라이딩, 피격과 종료는 이 피벗을 구동합니다.

## 에셋 및 라이선스

| 리소스 | 출처 및 라이선스 |
|---|---|
| 도로, 보도, 가로등, 근린 상가, 광장, 나무 | [Kenney Starter Kit City Builder](https://github.com/KenneyNL/Starter-Kit-City-Builder), [MIT](assets/city/LICENSE.md). 도로 타일의 중앙선만 색상 팔레트에서 조정했습니다. |
| 상업 건물, 수풀과 꽃, 울타리, 상자, 콘, 바리케이드 | [Kenney City Kit Commercial, City Kit Roads, Nature Kit, Platformer Kit](https://github.com/Hidencod/tge-assets), [CC0 1.0](assets/props/LICENSE). GLB 변환본은 Tiny Game Engine 모델 라이브러리에서 가져왔습니다. |
| 코인 모델 및 효과음 | [Kenney Starter Kit 3D Platformer](https://github.com/KenneyNL/Starter-Kit-3D-Platformer), [MIT](assets/park/LICENSE.md). |
| 트럭 및 충돌음 | [Kenney Starter Kit Racing](https://github.com/KenneyNL/Starter-Kit-Racing), [MIT](assets/vehicles/LICENSE). 버튼음은 City Builder 효과음을 사용했습니다. |
| 하늘 파노라마 | [Poly Haven · Kloofendal 48d Partly Cloudy Pure Sky](https://polyhaven.com/a/kloofendal_48d_partly_cloudy_puresky), [CC0](https://polyhaven.com/license). 밝기와 색을 조정한 WebP입니다. |
| 글꼴 | [Gowun Dodum](assets/ui/OFL-GowunDodum.txt), [Outfit](assets/ui/OFL-Outfit.txt), SIL OFL 1.1. Outfit은 두 개의 고정 굵기로 추출했습니다. |
| 게임 음악, 3D 무랑이, 타이틀 일러스트 | 게임 전용 제작. 음악은 `tools/compose_music.py`에 생성 스크립트가 있습니다. 일러스트는 첨부 레퍼런스를 바탕으로 제작했습니다. |

## 테스트

기록을 분리한 상태에서 시작, 시점, 입력, 충돌, 점프/슬라이드 판정, 코인, 게임 오버, 기록과 리플레이를 검사합니다. 12개 시드의 장애물 패턴과 12분을 시뮬레이션한 청크 재사용 검사도 포함합니다.

~~~sh
godot --headless --editor --import --path .
XDG_DATA_HOME="$(mktemp -d)" godot --headless --path . --script tests/smoke.gd
~~~

실물 Windows 및 Safari/iOS 기기별 호환성, 실제 기기의 장시간 프레임률과 평균 플레이 시간은 별도 검증이 필요합니다.
