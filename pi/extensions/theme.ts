/**
 * Theme Switcher — /theme slash command with live preview.
 *
 * Press /theme to open a scrollable list of available themes. As the cursor
 * moves over each theme, a debounced async load kicks in: a loading indicator
 * appears, then the TUI previews the theme in real time. Press Enter to
 * commit, Escape to revert to the previous theme.
 *
 * Usage: place in ~/.pi/agent/extensions/theme-switcher/index.ts
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import {
  DynamicBorder,
  getSelectListTheme,
} from "@earendil-works/pi-coding-agent";
import { Container, SelectList, Text } from "@earendil-works/pi-tui";

/** Debounce window: delay theme load to avoid thrashing during rapid navigation */
const LOAD_DEBOUNCE_MS = 50;

export default function themeSwitcher(pi: ExtensionAPI) {
  pi.registerCommand("theme", {
    description: "Switch theme with live preview",
    handler: async (_args, ctx) => {
      if (ctx.mode !== "tui") {
        ctx.ui.notify("/theme requires TUI mode", "error");
        return;
      }

      const availableThemes = ctx.ui.getAllThemes();
      if (availableThemes.length === 0) {
        ctx.ui.notify("No themes found", "error");
        return;
      }

      const originalThemeName = ctx.ui.theme.name ?? "dark";

      const items = availableThemes.map((t) => ({
        value: t.name,
        label: t.name,
        description:
          t.name === originalThemeName
            ? "(current)"
            : t.path
              ? `File: ${t.path}`
              : "Built-in",
      }));

      await ctx.ui.custom((tui, theme, _kb, done) => {
        // Mutable state for async loading
        let loadingThemeName: string | null = null;
        let loadTimer: ReturnType<typeof setTimeout> | null = null;
        let committed = false;

        const cancelPendingLoad = () => {
          if (loadTimer !== null) {
            clearTimeout(loadTimer);
            loadTimer = null;
          }
        };

        // Build the UI tree
        const container = new Container();
        const statusLine = new Text("", 1, 0);

        container.addChild(new DynamicBorder());

        const selectList = new SelectList(
          items,
          Math.min(items.length, 15),
          getSelectListTheme(),
        );

        const currentIndex = availableThemes.findIndex(
          (t) => t.name === originalThemeName,
        );
        if (currentIndex !== -1) {
          selectList.setSelectedIndex(currentIndex);
        }

        // Update the status line and invalidate container so the next
        // render picks up the new text. Call this whenever loading state changes.
        const syncStatusLine = () => {
          statusLine.setText(
            loadingThemeName
              ? theme.fg("warning", ` ◌ Loading "${loadingThemeName}"…`)
              : theme.fg(
                  "dim",
                  " ↑↓ navigate   enter select   esc cancel",
                ),
          );
          container.invalidate();
        };

        const applyThemeNow = (name: string) => {
          cancelPendingLoad();
          loadingThemeName = null;
          syncStatusLine();
          const result = ctx.ui.setTheme(name);
          if (!result.success) {
            ctx.ui.notify(
              `Failed to apply theme "${name}": ${result.error ?? "unknown error"}`,
              "error",
            );
          }
          tui.requestRender();
        };

        selectList.onSelectionChange = (item) => {
          if (committed) return;
          if (loadingThemeName === item.value) return;

          cancelPendingLoad();
          loadingThemeName = item.value;
          syncStatusLine();

          // Debounce: delay actual theme load to avoid thrashing
          loadTimer = setTimeout(() => {
            if (committed) return;
            applyThemeNow(item.value);
          }, LOAD_DEBOUNCE_MS);
        };

        selectList.onSelect = () => {
          committed = true;
          // Ensure the highlighted theme is applied (debounce may not have fired yet)
          if (loadingThemeName) {
            applyThemeNow(loadingThemeName);
          }
          done(undefined);
        };

        selectList.onCancel = () => {
          committed = true;
          cancelPendingLoad();
          loadingThemeName = null;
          const result = ctx.ui.setTheme(originalThemeName);
          if (!result.success) {
            ctx.ui.notify(
              `Failed to revert to "${originalThemeName}": ${result.error ?? "unknown error"}`,
              "error",
            );
          }
          done(undefined);
        };

        container.addChild(selectList);
        container.addChild(new Text("", 1, 0));
        container.addChild(statusLine);
        container.addChild(new DynamicBorder());

        return {
          render: (w: number) => container.render(w),
          invalidate: () => container.invalidate(),
          handleInput: (data: string) => {
            if (committed) return;
            selectList.handleInput(data);
            tui.requestRender();
          },
        };
      });
    },
  });
}
