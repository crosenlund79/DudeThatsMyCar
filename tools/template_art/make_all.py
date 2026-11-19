"""Writes every template asset: python3 make_all.py <assets/graphics dir> [preview dir] [only-prefix]"""
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import paint_ground  # noqa: E402

GROUPS = [paint_ground.TILES]
for mod in ("paint_buildings", "paint_props", "paint_vehicles", "paint_people", "paint_interiors", "paint_districts", "paint_grime", "paint_poker", "paint_items", "paint_cafe", "paint_emergency", "paint_gaming", "paint_civic", "paint_menu"):
    try:
        m = __import__(mod)
        GROUPS.append(m.ASSETS)
    except ImportError as e:
        if "No module named" not in str(e):
            raise


def main():
    out = sys.argv[1]
    preview = sys.argv[2] if len(sys.argv) > 2 else None
    only = sys.argv[3] if len(sys.argv) > 3 else ""
    for group in GROUPS:
        for logical, fn in group.items():
            if only and not logical.startswith(only):
                continue
            result = fn()
            items = result if isinstance(result, dict) else {logical: result}
            for name, img in items.items():
                d, f = os.path.split(name)
                path = os.path.join(out, d, "template_" + f + ".png")
                os.makedirs(os.path.dirname(path), exist_ok=True)
                img.save(path, optimize=True)
                import numpy as _np
                amin = int(_np.asarray(img)[..., 3].min())
                must_be_opaque = name.split("/")[0] in ("facades", "roofs") and not name.endswith("_lit") or name in (
                    "city/asphalt", "city/sidewalk", "city/alley", "city/cobbles", "city/lot", "city/water", "city/curb", "city/quay")
                flag = "  <-- NOT OPAQUE" if must_be_opaque and amin < 255 else ""
                print(name, img.size, flag)
                if preview:
                    os.makedirs(preview, exist_ok=True)
                    w, h = img.size
                    sheet = Image.new("RGBA", (w * 2, h * 2), (255, 0, 255, 255))
                    for i in range(2):
                        for j in range(2):
                            sheet.alpha_composite(img, (i * w, j * h))
                    sheet.save(os.path.join(preview, name.replace("/", "__") + ".png"))


if __name__ == "__main__":
    main()
