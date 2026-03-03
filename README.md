# 🌿 GitHub Grass for Rainmeter

Display your GitHub contribution graph on your Windows desktop using Rainmeter.

![GitHub Grass Preview](preview.png)

---

## Requirements

- [Rainmeter](https://www.rainmeter.net/) 4.x or higher
- Windows 10 / 11
- GitHub Personal Access Token

---

## Installation

**1. Copy the skin folder**
```
Documents\Rainmeter\Skins\rainmeter_plugin\
```

**2. Edit `Settings.inc`**
```ini
GitHubUsername=your_github_username
GitHubToken=ghp_xxxxxxxxxxxxxxxxxxxx
```

**3. Run `run.bat`** (double-click)
Wait ~10 seconds for data to load. The widget will appear automatically.

**4. Load `GrassView.ini` in Rainmeter Manager**
Right-click tray icon → Manage → Load `GrassView.ini`

---

## Getting a GitHub Token

1. Go to GitHub → Settings → Developer settings
2. Personal access tokens → Tokens (classic)
3. Generate new token → check `read:user` → Generate
4. Copy the token into `Settings.inc`

---

## Settings

Open `Settings.inc` to customize. After editing, click the **R** button on the widget to apply.

| Setting | Default | Description |
|---------|---------|-------------|
| `GitHubUsername` | — | Your GitHub username |
| `GitHubToken` | — | GitHub Personal Access Token |
| `ColorTheme` | `Green` | Color theme (see below) |
| `CellSize` | `11` | Cell size in pixels |
| `CellGap` | `2` | Gap between cells |
| `Padding` | `14` | Widget outer padding |
| `WeeksToShow` | `52` | Weeks to display (52 = 1 year) |

### Color Themes

| Theme | Description |
|-------|-------------|
| `Green` | GitHub default green |
| `Purple` | Purple tones |
| `Blue` | Blue tones |
| `Red` | Red tones |
| `Orange` | Orange tones |
| `Pink` | Pink tones |
| `Mono` | Grayscale |

---

## Usage

### Period Selector Buttons

Click the period buttons on the widget to change the displayed time range:

| Button | Period |
|--------|--------|
| `1W` | Last 1 week |
| `1M` | Last 4 weeks |
| `3M` | Last 13 weeks |
| `6M` | Last 26 weeks |
| `1Y` | Last 52 weeks (default) |

The widget updates automatically — no manual refresh needed.

### R Button

Click **R** (top-right of widget) to fetch fresh data and apply any `Settings.inc` changes.

---

## Troubleshooting

**Widget not showing / blank cells**
- Make sure `run.bat` has been executed at least once
- Check `debug.log` in the skin folder

**`debug.log` says API failed**
- Verify your `GitHubUsername` and `GitHubToken`
- Token needs `read:user` permission

**PowerShell execution error**
Open PowerShell as administrator and run:
```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

---

## File Structure

```
rainmeter_plugin\
├── Settings.inc         ← Your configuration
├── FetchAndBuild.ps1    ← Data fetcher + INI generator
├── run.bat              ← Run this to generate the widget
├── launcher.vbs         ← Silent background script launcher
├── GrassView.ini        ← Auto-generated (do not edit)
└── debug.log            ← Auto-generated (check on errors)
```

---

## Development Status

### Completed

- [x] Core architecture: PowerShell fetches GitHub API and generates `GrassView.ini` with Shape Meters
- [x] UTF-8 BOM encoding for all INI files
- [x] Shape Meter color rendering (fill color bug fixed)
- [x] Full rewrite of `FetchAndBuild.ps1` (stable, no pipeline pollution)
- [x] 52-week (1 year) contribution graph display
- [x] Weekday labels (Sun ~ Sat)
- [x] Month labels (Jan ~ Dec)
- [x] 7 color themes (Green / Purple / Blue / Red / Orange / Pink / Mono)
- [x] Opacity setting (background transparency)
- [x] Configurable cell size, gap, padding, weeks
- [x] **R** refresh button on widget
- [x] **Period selector buttons (1W / 1M / 3M / 6M / 1Y)** — click to switch time range instantly
- [x] Silent background execution via `wscript.exe` + `launcher.vbs` (no console window flash)
- [x] Auto-refresh after script completes (`Rainmeter.exe !Refresh`)
- [x] L0 cell contrast improvement (empty cells more visible against background)

### Planned / TODO

- [ ] Opacity slider UI on widget
- [ ] GitHub OAuth Device Flow (no manual token setup)
- [ ] Auto-refresh on system startup
- [ ] `.rmskin` package for one-click install

---

## Architecture Notes

Buttons in the widget call `wscript.exe launcher.vbs [weeks]` directly from `LeftMouseUpAction`.
This avoids the Rainmeter RunCommand plugin (which has issues with space-containing paths and arguments).
`FetchAndBuild.ps1` triggers `Rainmeter.exe !Refresh` at the end so the widget reloads automatically.

---

## License

MIT License
