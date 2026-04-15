# image-upscale

Upscale any image — or a whole folder of images — straight from the terminal using [Real-ESRGAN](https://github.com/xinntao/Real-ESRGAN). Results land in an `upscale/` subfolder next to your originals, always as lossless PNG.

---

## Step 1 — Install

### Arch Linux

```bash
sudo pacman -S python-pipx git
git clone https://github.com/ChrisTitusTech/image-upscale
cd image-upscale
pipx install .
```

### Other Linux / macOS

```bash
git clone https://github.com/ChrisTitusTech/image-upscale
cd image-upscale
python -m venv .venv
source .venv/bin/activate
pip install .
```

Verify the install worked:

```bash
upscale --help
```

---

## Step 2 — Pick your images

You can point `upscale` at a **single file** or an entire **folder**.

```bash
# Single image
upscale /path/to/photo.jpg

# Whole folder
upscale /path/to/photos/
```

Output is always written to an `upscale/` subfolder inside the same directory:

```
/path/to/photos/
├── photo.jpg
├── scan.png
└── upscale/          ← created automatically
    ├── photo.jpg.png
    └── scan.png
```

> **Note:** `.jpg`, `.jpeg`, `.png`, `.webp`, `.bmp`, `.tiff` are all supported.

---

## Step 3 — Run

The first run downloads the model weights (~67 MB) to `~/.cache/image-upscale/weights/`. Subsequent runs are instant.

```bash
upscale photo.jpg
```

You will see output like:

```
Model   : x4plus — General images, 4x upscale (default, best quality)
Scale   : 4.0x
Images  : 1
Output  : /path/to/upscale

[1/1] photo.jpg  done

Finished: 1 upscaled, 0 skipped.
Output folder: /path/to/upscale
```

---

## Step 4 — Common options

### Use a different model

```bash
# Best quality (default)
upscale photo.jpg --model x4plus

# 2x upscale instead of 4x
upscale photo.jpg --model x2plus

# Anime / illustrations
upscale drawing.png --model x4plus-anime

# Fastest model, good for general scenes
upscale photo.jpg --model general-x4v3
```

### Run on CPU (no GPU, or GPU with limited VRAM)

```bash
# CPU mode — slower but works everywhere
upscale photo.jpg --fp32

# GPU with limited VRAM — process in 512px tiles
upscale photo.jpg --tile 512
```

### Custom output scale

```bash
# Output at 2x even though the x4 model is used internally
upscale photo.jpg --scale 2
```

---

## Models

| Model | Best for | Scale |
|---|---|---|
| `x4plus` *(default)* | Photos, general images | 4x |
| `x2plus` | Photos when you only need 2x | 2x |
| `x4plus-anime` | Anime, illustrations, line art | 4x |
| `animevideo` | Anime video frames | 4x |
| `general-x4v3` | General scenes, fast results | 4x |

Model weights are downloaded automatically on first use to `~/.cache/image-upscale/weights/`.

---

## Full usage reference

```
upscale <input> [--model MODEL] [--scale N] [--tile SIZE] [--fp32]

positional arguments:
  input           Path to an image file or a directory of images

options:
  --model MODEL   Model to use (default: x4plus)
  --scale N       Output scale factor, e.g. 2.0 or 3.5 (default: model's native scale)
  --tile SIZE     Tile size in pixels for VRAM-limited GPUs, e.g. 512 (default: 0 = full image)
  --fp32          Use float32 — required for CPU or very old GPUs
```
