---
name: youtube-import
description: Import videos from the @mybonusmultimedia YouTube channel into the myBonus backend (as YouTube links), with posters generated in the style of the existing series art, organized into series/episodes or standalone films. Use when asked to add/populate videos from the YouTube channel.
---

# Import YouTube → myBonus

Videos are stored as **external links** (`video_source=1`, link `https://www.youtube.com/watch?v=<id>`) in `tbl_live_event`; series in `tbl_video_series`; categories in the unified `tbl_category`. Prod writes are **run by the user** — never write to the prod DB yourself.

## Workflow

1. **List the channel** (yt-dlp in a scratchpad venv, flat mode only — per-video pages hit 429/captcha):
   `venv/bin/yt-dlp --flat-playlist --print "%(id)s|%(title)s" https://www.youtube.com/@mybonusmultimedia/videos`
   Output is newest first (so "the N oldest" = the last N lines).
2. **Skip what already exists**: read prod read-only
   (`ssh 89.233.108.165 'cd /home/mbomulti/public_html/admin && php artisan tinker --execute=...'`) for existing series/categories/links.
3. **Check embeddability**: `https://www.youtube.com/oembed?url=...&format=json` must return 200.
4. **Classify** with a single contact sheet of thumbnails (`i.ytimg.com/vi/<id>/maxresdefault.jpg`): same actors/set ⇒ same series. The channel has no playlists. Titles are English with a trailing part number ("X 1"): translate to French and keep it as "(partie N)". **Present the classification to the user and get validation before generating/importing.**
5. **Write a batch** in `batches/<date>_<name>.json` (see existing batch: `categories` existing/create, `series` new or `existing: true`, `videos` with `series`+`episode` or `category`). Continue episode numbers after the existing ones of an existing series.
6. **Generate posters**: `venv/bin/python make_visuals.py batches/<file>.json <out_dir>` (needs Pillow + `opencv-python-headless<5` for face-centred crops). Review only `<out_dir>/contact_sheet.jpg`.
   Output: per video `<yt>_portrait.jpg` 940×1672 + `<yt>_landscape.jpg` 1600×900, `series_<slug>_*` for new series, `category_<slug>.jpg` 512² for new categories.
7. **Test locally**: copy the batch to `<out_dir>/batch.json`, then from `bonusradioadmin`:
   `php <skill>/import_youtube.php . <out_dir> --dry-run`, then without `--dry-run`, then again (must report everything "déjà présentes"). Check `POST /api/get_video` on `php artisan serve --port=8123`.
8. **Prod**: `scp` the script, batch.json and jpgs (not `thumbs/`, not the contact sheet) to `89.233.108.165:~/yt_import/`, then give the user:
   ```
   cd ~/public_html/admin
   php ~/yt_import/import_youtube.php . ~/yt_import --dry-run
   php ~/yt_import/import_youtube.php . ~/yt_import
   ```
   Then verify read-only via the prod API `get_video`.

## Notes
- Category/series matching is by name with MySQL's accent/case-insensitive collation ("Séries" = "SERIES").
- Fonts (OFL/Apache) are in `fonts/`. Style: warm grade + vignette, brush yellow→orange kicker (Permanent Marker), white Anton title, "— ÉPISODE N · PARTIE M —" / "— FILM —" / "— SAISON 1 —" tag; text goes on the side opposite the detected face.
