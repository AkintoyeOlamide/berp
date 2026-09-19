from PIL import Image

src = r"c:\Users\USER\Documents\vmo_aero\assets\landing_jet_hiend.png"
img = Image.open(src).convert("RGBA")
px = img.load()
w, h = img.size
out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
op = out.load()

for y in range(h):
    for x in range(w):
        r, g, b, a = px[x, y]
        if a < 8:
            continue
        lum = 0.2126 * r + 0.7152 * g + 0.0722 * b
        # Keep only the actual ink strokes (dark lines).
        if lum > 140:
            continue
        strength = 1.0 - (lum / 140.0)
        alpha = int(min(255, strength * 255.0 * (a / 255.0)))
        if alpha < 40:
            continue
        op[x, y] = (255, 255, 255, alpha)

bbox = out.getbbox()
if bbox:
    pad = 32
    out = out.crop((
        max(0, bbox[0] - pad),
        max(0, bbox[1] - pad),
        min(w, bbox[2] + pad),
        min(h, bbox[3] + pad),
    ))

dest = r"c:\Users\USER\Documents\vmo_aero\assets\landing_jet_clipart.png"
out.save(dest, "PNG")
print("saved", dest, out.size)
