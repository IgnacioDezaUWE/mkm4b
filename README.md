# mkm4b

Convert a folder of audio recordings into a single **M4B audiobook** with chapters, cover art, and embedded metadata.

Designed for lectures, conference talks, student vivas, and anything else you'd rather listen to at 1.5× speed on your phone.

---

## Features

- Merges any number of audio files into one M4B
- Embeds **chapter markers**: one per file, or split automatically at silence gaps
- **Auto-detects** cover art and metadata already embedded in your files
- Caches extracted `cover.jpg` and `meta.txt` in the folder so re-runs are instant
- Natural sort order: `lecture-2` always comes before `lecture-10`
- Works on **macOS and Linux**

---

## Requirements

### macOS

```bash
brew install ffmpeg coreutils
```

### Linux (Debian / Ubuntu)

```bash
sudo apt install ffmpeg coreutils
```

### Linux (Fedora / RHEL)

```bash
sudo dnf install ffmpeg coreutils
```

> **Note:** On Linux, `ffmpeg` may not be in the default repos. If `apt install ffmpeg` fails, enable the `universe` repository first or install from [ffmpeg.org](https://ffmpeg.org/download.html).

---

## Installation

```bash
git clone https://github.com/IgnacioDezaUWE/mkm4b.git
cd mkm4b
./install.sh
```

That's it. The installer copies `mkm4b` to `/usr/local/bin`, checks that it's on your PATH, and tells you if any dependencies are missing.

### Custom install location

```bash
./install.sh ~/bin        # install to ~/bin instead
./install.sh /usr/bin     # system-wide (requires sudo)
```

---

## Quick start

```bash
# Convert a folder of recordings: chapters named after each file
mkm4b lectures/

# Preview what will happen without writing anything
mkm4b lectures/ -n
```

The output file is written to your **current directory**, named after the input folder:

```
lectures/ → ./lectures.m4b
```

---

## Usage

```
mkm4b [DIRECTORY] [OPTIONS]
```

| Option | Description |
|---|---|
| `-o FILE` | Output file (default: `<dirname>.m4b` in current directory) |
| `-m FILE` | Metadata file (key=value). Auto-detected if omitted. |
| `-a IMAGE` | Cover art (jpg or png). Auto-detected if omitted. |
| `-c MODE` | Chapter mode: see below (default: `files`) |
| `-r` | Recurse into subdirectories |
| `-f` | Overwrite existing output file |
| `-s` | Skip silently if output already exists (useful in batch loops) |
| `-n` | Dry run: show exactly what would happen, write nothing |
| `-v` | Verbose: show full ffmpeg output |
| `-h` | Help |
| `--version` | Print version |

**Performance:**

| Option | Description |
|---|---|
| `--jobs=N` | Parallel encode jobs. Each file is encoded to AAC simultaneously; a fast `-c copy` pass then assembles the final M4B. Use `--jobs=-1` to use all CPU cores, or `--jobs=4` for a fixed number. Omit for sequential mode (default). |

**Audio:**

| Option | Description |
|---|---|
| `--mono` | Encode as mono 64k (default: stereo 128k: good for recordings with spatial audio) |

**Metadata overrides**: set individual fields without a `meta.txt`:

| Option | Description |
|---|---|
| `--title=TEXT` | Set title |
| `--author=TEXT` | Set author |
| `--album=TEXT` | Set album |
| `--year=TEXT` | Set year |

These take priority over `-m` and auto-detected values for that run only. The cached `meta.txt` is not modified.

**Silence tuning:**

| Option | Description |
|---|---|
| `--silence-threshold=N` | Level below which audio counts as silence, in dB below full scale (default: `35` → −35 dBFS). Higher = more aggressive. Try `25` for noisy rooms / loud AC. |
| `--trim-ends[=SECS]` | Strip leading/trailing silence from each file before joining. Keeps SECS seconds of buffer on each side (default: `1.0`). |

**Supported input formats:** `mp3`, `m4a`, `aac`, `wav`, `flac`

---

## Chapter modes

### `files` (default)

One chapter per input file. Chapter titles are taken from filenames with leading
numbers stripped: so `03 - Introduction.mp3` becomes chapter `Introduction`.

```bash
mkm4b lectures/ -c files
```

### `none`

No chapter markers: just a single continuous audio stream.

```bash
mkm4b lectures/ -c none
```

### `silence=N`

Splits chapters at silence gaps of **N seconds or more** (floats are fine: `silence=3.5`).
File boundaries always count as chapter boundaries too.
Falls back to `files` mode with a warning if no silence is detected.

```bash
mkm4b lectures/ -c silence=5
```

---

## Auto-detection

When you don't pass `-m` or `-a`, mkm4b looks inside the input folder and the audio files themselves:

### Cover art

1. Looks for `cover.jpg` or `cover.png` in the input folder: uses it if valid
2. If not found, scans the audio files for embedded artwork and extracts it
3. Saves the extracted image to the folder for next time
4. If a file exists but is broken, backs it up to `cover2.jpg` and extracts a fresh copy

### Metadata

1. Looks for `meta.txt` in the input folder: uses it if valid
2. If not found, reads embedded tags (`title`, `artist`, `album`, `date`) from the first file that has them
3. Saves the extracted tags to `meta.txt` for next time
4. If `meta.txt` exists but is empty or malformed, backs it up to `meta2.txt`

This means the first run on any folder does the work; every subsequent run is instant.

---

## Metadata file

A plain text file with one `key=value` per line. Lines starting with `#` are comments.

```
# meta.txt
title=Introduction to Machine Learning
author= My Fav Lecturer
album=Data Science Lectures 2026
year=2026
```

Pass it explicitly with `-m`, or just place it in the input folder as `meta.txt`
and mkm4b will find it automatically.

---

## Examples

```bash
# Basic: chapters from filenames, auto-detect cover and metadata
mkm4b lectures/

# Custom output path
mkm4b lectures/ -o ~/Audiobooks/ml-intro.m4b

# Silence-based chapters, explicit metadata and cover
mkm4b lectures/ -c silence=5 -m meta.txt -a cover.jpg

# No chapters, overwrite if output exists
mkm4b lectures/ -c none -f

# Recurse into subdirectories
mkm4b course/ -r

# Trim leading/trailing silence from each file, mono output
mkm4b lectures/ --trim-ends --mono

# Noisy room: more aggressive silence threshold
mkm4b lectures/ --trim-ends --silence-threshold=25

# Override metadata without editing meta.txt
mkm4b lectures/ --title="Viva: Jane Smith" --year=2026

# Use all CPU cores — ideal for large backlogs
mkm4b lectures/ --jobs=-1

# Parallel encode + trim ends in one shot
mkm4b lectures/ --jobs=-1 --trim-ends

# Preview without writing
mkm4b lectures/ -n

# Verbose output (see full ffmpeg log)
mkm4b lectures/ -v
```

### Processing many folders in parallel

```bash
for folder in */; do
  mkm4b "$folder" -s --jobs=-1
done
```

The `-s` flag skips any folder that already has an output file, so you can
safely re-run the loop after adding new folders. `--jobs=-1` uses all CPU cores
for each folder, so encoding runs as fast as your hardware allows. mkm4b
auto-extracts metadata and cover art from each folder's files on the first run,
then reuses them.

---

## Tips

- **File order** is determined by natural sort: you don't need to pad numbers manually. `lecture-2.mp3` and `lecture-10.mp3` sort correctly as-is.
- **Existing tags are respected**: if your files already have cover art and metadata embedded, mkm4b picks them up automatically with no extra flags.
- **Dry run**: `mkm4b lectures/ -n` shows you the file order, chapter layout, and full metadata block before committing to an encode.
- **Re-encode**: the auto-extracted `meta.txt` and `cover.jpg` in each folder act as a persistent cache. Edit them before re-running to correct any tags.

---

## Compatibility

| Platform | Status |
|---|---|
| macOS (Apple Silicon & Intel) | ✅ |
| Linux (x86\_64, ARM) | ✅ |
| Windows | ❌ (use WSL) |

---

## License

MIT
