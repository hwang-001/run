"""Recolor the original center marking of Kenney's two paved road tiles."""
import json
import math
from pathlib import Path
import struct

root = Path(__file__).resolve().parents[1] / "assets" / "city"
for name in ("road-straight", "road-straight-lightposts"):
    asset = root / f"{name}.glb"
    data = bytearray(asset.read_bytes())
    json_size = struct.unpack_from("<I", data, 12)[0]
    metadata = json.loads(data[20:20 + json_size])
    bin_start = 28 + json_size
    for primitive in metadata["meshes"][0]["primitives"]:
        uv = metadata["accessors"][primitive["attributes"]["TEXCOORD_0"]]
        view = metadata["bufferViews"][uv["bufferView"]]
        offset = bin_start + view.get("byteOffset", 0) + uv.get("byteOffset", 0)
        for vertex in range(uv["count"]):
            pos = offset + vertex * view.get("byteStride", 8)
            u, v = struct.unpack_from("<ff", data, pos)
            if math.isclose(u, 0.15625) and math.isclose(v, 0.875):
                struct.pack_into("<ff", data, pos, 0.09375, 0.975)
    asset.write_bytes(data)
