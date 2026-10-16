# SSHD2382 Design Fundamentals — Course Website

PolyU CPCE / HKCC · Semester One 2026/2027 · Combined Group A01, A02  
Subject Leader & Lecturer: CHAN, Long-fung Lazarus

Static site ready for **GitHub Pages**. Lecture HTML (weeks 1–11) is **self-contained** (images embedded as base64). Weeks 12–13 are final presentations — no lecture deck is published.

## Password gate

The whole site (home + slides) asks for a password before content is shown.

- **Password:** `20262382`
- Unlock lasts for the browser tab session (`sessionStorage`).
- This is **client-side only** (suitable for casual course access, not strong security).

To change the password, edit `PASSWORD_HASH` in [`auth.js`](auth.js):

```bash
python3 -c "import hashlib; print(hashlib.sha256(b'YOUR_PASSWORD').hexdigest())"
```

## Publish with script

Windows:

```bat
cd Github\SSHD2382
publish.bat
```

Mac / Git Bash:

```bash
cd Github/SSHD2382
./publish.sh
```

Pushes to [2026-1-SSHD2382-DESIGN-FUNDAMENTALS-Combined-Group-A01-A02-](https://github.com/Lazaruschan/2026-1-SSHD2382-DESIGN-FUNDAMENTALS-Combined-Group-A01-A02-). Sign in if Git prompts you. Then enable Pages once: **Settings → Pages → main / (root)**.

Site URL: `https://lazaruschan.github.io/2026-1-SSHD2382-DESIGN-FUNDAMENTALS-Combined-Group-A01-A02-/`

## Publish on GitHub Pages (simplest)

1. Create a new empty GitHub repository named `2026-1-SSHD2382-DESIGN-FUNDAMENTALS-Combined-Group-A01-A02-`.
2. Upload **the contents of this folder** as the repo root (not the parent `Github/` folder).
   - Include: `index.html`, `auth.js`, `.nojekyll`, `assets/`, `slides/`, `README.md`
   - Do **not** upload `node_modules/`
3. In the repo: **Settings → Pages → Build and deployment**
   - Source: **Deploy from a branch**
   - Branch: `main` (or `master`), folder: **/ (root)**
4. Wait a minute, then open the site URL above.

`.nojekyll` is included so GitHub Pages serves files as-is (no Jekyll processing).

## Open locally

Open [`index.html`](index.html) in a browser, or:

```bash
cd Github/SSHD2382
python3 -m http.server 8080
```

Visit `http://localhost:8080`.

- Lecture decks: [`slides/week-01.html`](slides/week-01.html) … [`slides/week-11.html`](slides/week-11.html) (weeks 6–7 and 8–9 are combined: `week-06-07.html`, `week-08-09.html`)
- Briefs: [`assets/briefs/`](assets/briefs/)

## Online tutorials

The **Online Tutorials** tab plays the YouTube playlist set in `COURSE_CONFIG.tutorials.playlistId` (`PLdmLs421QDxU`). The list is read live from YouTube every time the page loads, so new videos added to the playlist show up on the site without republishing. Keep the playlist **Public** or **Unlisted**; private playlists cannot be embedded.

## Rebuild slides from Marp sources (maintainers)

Requires Node, Python 3, and source files under `Notes/Design_Fundamentals/Design_Fundamentals/`.

```bash
cd Github/SSHD2382
npm install
python export-slides.py      # or ./export-slides.sh on Mac
```

This regenerates every `week_NN` / `week_NN_MM` deck (weeks 1–11), embeds local images into the HTML, removes decks whose source no longer exists, and deletes the temporary stage folder.

## Rebuild workshop worksheets (maintainers)

The **Workshop** tab lists the Group Activity worksheets as PDFs that students can preview and download. Sources are the Marp files in `Group Activity/` (`WeekNN_Worksheet.md` or `WeekNN-MM_Worksheet.md`).

```bash
cd Github/SSHD2382
npm install
python export-worksheets.py
```

This writes `assets/worksheets/week-NN.pdf` (or `week-NN-MM.pdf`) and removes PDFs whose source no longer exists. Marp needs Chrome or Edge installed to print PDFs. If you add or rename a worksheet, update `COURSE_CONFIG.workshop.weeks` in `index.html`.

Note: the password gate only covers HTML pages; anyone with a direct PDF link can open it.

## Site structure (publish)

```
SSHD2382/
  index.html
  auth.js                 Password gate (required)
  .nojekyll
  .gitignore
  README.md
  assets/briefs/          Assessment briefs
  assets/worksheets/      Workshop (Group Activity) worksheet PDFs
  slides/
    week-01.html … week-11.html   (self-contained; week-06-07, week-08-09 combined)
```

The reusable blank template for other courses is [`../template.html`](../template.html).
