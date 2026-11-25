"""Package the Godot Web and Windows exports with redistribution notices."""
import argparse
import hashlib
from pathlib import Path
import re
from zipfile import ZIP_DEFLATED, ZipFile

ROOT = Path(__file__).resolve().parents[1]
NOTICES = {
    "Kenney-City-Builder.txt": ROOT / "assets/city/LICENSE.md",
    "Kenney-Platformer.txt": ROOT / "assets/park/LICENSE.md",
    "Kenney-Racing.txt": ROOT / "assets/vehicles/LICENSE",
    "Kenney-Model-Packs.txt": ROOT / "assets/props/LICENSE",
    "Lucide-LICENSE.txt": ROOT / "assets/ui/lucide/LICENSE.txt",
    "Poly-Haven.txt": ROOT / "assets/surfaces/LICENSE.txt",
    "OFL-GowunDodum.txt": ROOT / "assets/ui/OFL-GowunDodum.txt",
    "OFL-Outfit.txt": ROOT / "assets/ui/OFL-Outfit.txt",
}
WINDOWS_HELP = """무랑 런 {version} · Windows x64

ZIP을 모두 푼 다음 MurangRun.exe를 실행하세요. Godot 설치는 필요 없습니다.
이동 A / D 또는 ← / →, 점프 W / Space / ↑, 슬라이드 S / ↓,
일시정지 Esc, 시작과 재도전 Enter 또는 화면 버튼

신규 맵 테스트를 선택하면 1,500m 산호빛 항구에서 출발합니다.
일반 주행에서 얻은 최고 점수, 최대 이동 거리, 누적 코인은 이 PC에 저장됩니다.
소스 코드와 에셋 정보는 https://github.com/hwang-001/run 에서 확인할 수 있습니다.
"""
WEB_HELP = """무랑 런 {version} · 웹

압축을 푼 폴더에서 python -m http.server 8080 을 실행한 다음
http://localhost:8080 에서 플레이하세요. 브라우저에 WebGL 2가 필요합니다.
"""

def archive(path, files, notices, help_text):
    with ZipFile(path, "w", ZIP_DEFLATED, compresslevel=6) as output:
        output.writestr("시작하기.txt", help_text)
        for name, notice in notices.items():
            output.write(notice, f"licenses/{name}")
        for file in files:
            output.write(file, file.name)
    with ZipFile(path) as output:
        if output.testzip() is not None:
            raise ValueError(f"Invalid release archive: {path}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("destination", type=Path)
    parser.add_argument("godot_notices", type=Path)
    args = parser.parse_args()
    args.destination.mkdir(parents=True, exist_ok=True)
    notices = NOTICES | {
        "Godot-LICENSE.txt": args.godot_notices / "Godot-LICENSE.txt",
        "Godot-COPYRIGHT.txt": args.godot_notices / "Godot-COPYRIGHT.txt",
    }
    build = ROOT / "build"
    exe = build / "windows/MurangRun.exe"
    with exe.open("rb") as binary:
        if binary.read(2) != b"MZ":
            raise ValueError("The Windows export is missing its PE header.")
        binary.seek(-4, 2)
        if binary.read(4) != b"GDPC":
            raise ValueError("The Windows export does not contain its embedded Godot pack.")
    web = build / "web"
    for file in ("index.html", "index.js", "index.wasm", "index.pck"):
        if not (web / file).is_file():
            raise ValueError(f"Missing Web export: {file}")
    version_match = re.search(r'^config/version="([0-9]+\.[0-9]+)"$', (ROOT / "project.godot").read_text(), re.MULTILINE)
    if version_match is None:
        raise ValueError("Missing major.minor version in project.godot.")
    version = "v" + version_match.group(1)
    windows_zip = args.destination / f"MurangRun-{version}-Windows-x64.zip"
    web_zip = args.destination / f"MurangRun-{version}-Web.zip"
    archive(windows_zip, [exe], notices, WINDOWS_HELP.format(version=version))
    archive(web_zip, sorted(f for f in web.glob("index.*") if f.suffix != ".import"), notices, WEB_HELP.format(version=version))
    with (args.destination / "SHA256SUMS.txt").open("w") as output:
        for release in (windows_zip, web_zip):
            with release.open("rb") as binary:
                digest = hashlib.file_digest(binary, "sha256").hexdigest()
            output.write(f"{digest}  {release.name}\n")


if __name__ == "__main__":
    main()
