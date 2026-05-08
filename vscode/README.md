# VS Code Configurations & Themes

This document saves my personal VS Code configurations and themes for backup and reuse across machines.

## Contents

- `anysphere.cursor-themes-0.0.2/` — Cursor themes extension (Dark, Dark Midnight, Dark High Contrast, Light)

---

## Installing Themes Manually

Follow these steps to install the Cursor themes into your local VS Code:

### Step 1 — Locate the VS Code extensions folder

Open a terminal and navigate to your VS Code extensions directory:

```
~/.vscode/extensions/
```

### Step 2 — Copy the theme extension folder

Copy the theme folder from this repo into the extensions directory:

```bash
cp -r anysphere.cursor-themes-0.0.2 ~/.vscode/extensions/
```

### Step 3 — Restart VS Code

Close and reopen VS Code so it picks up the newly installed extension.

### Step 4 — Apply the theme

1. Open the Command Palette (`Cmd+Shift+P` on Mac / `Ctrl+Shift+P` on Windows/Linux)
2. Type **Preferences: Color Theme** and select it
3. Choose one of the Cursor themes from the list:
   - Cursor Dark
   - Cursor Dark Midnight
   - Cursor Dark High Contrast
   - Cursor Light
