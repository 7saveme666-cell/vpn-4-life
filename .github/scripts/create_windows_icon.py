from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
ICON_PATH = ROOT / "flutter_app" / "windows" / "runner" / "resources" / "app_icon.ico"
SIZE = 512

# Тёмная скруглённая плитка и фиолетовый паук по мотивам присланного изображения.
tile = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
ImageDraw.Draw(tile).rounded_rectangle(
    (14, 14, SIZE - 14, SIZE - 14),
    radius=92,
    fill=(9, 7, 15, 255),
)

mask = Image.new("L", (SIZE, SIZE), 0)
draw = ImageDraw.Draw(mask)

legs = [
    [(212, 219), (190, 171), (123, 82), (158, 168), (160, 202), (218, 234)],
    [(300, 234), (356, 202), (354, 168), (389, 82), (322, 171), (300, 219)],
    [(217, 238), (190, 227), (152, 276), (184, 318), (174, 277)],
    [(295, 238), (322, 227), (360, 276), (328, 318), (338, 277)],
    [(215, 247), (177, 251), (112, 302), (168, 417), (139, 305), (178, 271)],
    [(297, 247), (335, 251), (400, 302), (344, 417), (373, 305), (334, 271)],
    [(222, 248), (199, 282), (224, 355), (210, 301)],
    [(290, 248), (313, 282), (288, 355), (302, 301)],
]
for points in legs:
    draw.polygon(points, fill=255)

draw.ellipse((216, 193, 296, 277), fill=255)
draw.polygon([(222, 245), (290, 245), (294, 305), (256, 344), (218, 305)], fill=255)

gradient = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
pixels = gradient.load()
for y in range(SIZE):
    t = y / (SIZE - 1)
    color = (153 - int(32 * t), 57 + int(12 * t), 255, 255)
    for x in range(SIZE):
        if mask.getpixel((x, y)):
            pixels[x, y] = color

tile.alpha_composite(gradient)
ICON_PATH.parent.mkdir(parents=True, exist_ok=True)
tile.save(
    ICON_PATH,
    format="ICO",
    sizes=[(256, 256), (128, 128), (64, 64), (48, 48), (32, 32), (16, 16)],
)
print(f"Generated {ICON_PATH}")
