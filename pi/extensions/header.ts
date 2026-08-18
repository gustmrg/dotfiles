import { relative, resolve, sep } from "node:path";
import { VERSION, type ExtensionAPI, type ExtensionContext } from "@earendil-works/pi-coding-agent";
import type { Component, TUI } from "@earendil-works/pi-tui";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

function formatCwd(cwd: string): string {
  const home = process.env.HOME ?? process.env.USERPROFILE;
  if (!home) return cwd;
  const rel = relative(resolve(home), resolve(cwd));
  const insideHome = rel === "" || (rel !== ".." && !rel.startsWith(`..${sep}`));
  return insideHome ? (rel ? `~${sep}${rel}` : "~") : cwd;
}

function formatModelLabel(model: { provider?: string; id?: string } | null | undefined): string {
  if (!model?.id) return "no-model";
  return model.provider ? `${model.provider}/${model.id}` : model.id;
}

function fit(text: string, width: number): string {
  const clipped = truncateToWidth(text, Math.max(0, width), "…");
  return clipped + " ".repeat(Math.max(0, width - visibleWidth(clipped)));
}

export class OpenTuiHeader implements Component {
  constructor(
    private readonly pi: ExtensionAPI,
    private readonly ctx: ExtensionContext,
    _tui: TUI,
  ) {}

  render(width: number): string[] {
    const safeWidth = Math.max(0, width);
    const theme = this.ctx.ui.theme;
    const primary = (text: string) => theme.fg("accent", text);
    const dim = (text: string) => theme.fg("dim", text);
    const label = (text: string) => theme.bold(theme.fg("muted", text));
    const model = formatModelLabel(this.ctx.model);
    const effort = this.pi.getThinkingLevel();

    if (safeWidth < 24) {
      return [
        primary(theme.bold("Welcome, Gustavo!")),
        dim(`${model} · ${effort}`),
      ].map((line) => truncateToWidth(line, safeWidth, "…"));
    }

    const innerWidth = safeWidth - 4;
    const pad = "  ";
    const logo = ["▐█▛█▛█▌", "▐█████▌"] as const;
    const logoWidth = Math.max(...logo.map(visibleWidth));
    const gap = "  ";
    const textWidth = Math.max(4, innerWidth - logoWidth - gap.length);
    const sessionName = this.ctx.sessionManager.getSessionName();
    const sessionId = this.ctx.sessionManager.getSessionId();

    const content = [
      primary(logo[0].padEnd(logoWidth)) + gap +
        truncateToWidth(primary(theme.bold("Welcome, Gustavo!")), textWidth, "…"),
      primary(logo[1].padEnd(logoWidth)) + gap +
        truncateToWidth(dim("Type /settings to configure Pi."), textWidth, "…"),
      "",
      label("Directory: ") + formatCwd(this.ctx.cwd),
      label("Session:   ") + (sessionName ?? sessionId),
      label("Model:     ") + model,
      label("Thinking:  ") + effort,
    ];

    const versionLabel = `Pi v${VERSION}`;
    const topBorderDashes = Math.max(0, safeWidth - 2 - 4 - visibleWidth(versionLabel));
    const topBorder =
      primary("╭── ") +
      primary(versionLabel) +
      primary(` ${"─".repeat(topBorderDashes)}╮`);

    const lines = [
      "",
      topBorder,
      primary("│") + " ".repeat(safeWidth - 2) + primary("│"),
    ];
    for (const line of content) {
      lines.push(primary("│") + pad + fit(line, innerWidth) + primary("│"));
    }
    lines.push(primary("│") + " ".repeat(safeWidth - 2) + primary("│"));
    lines.push(primary(`╰${"─".repeat(safeWidth - 2)}╯`));
    lines.push("");
    return lines.map((line) => truncateToWidth(line, safeWidth, "…"));
  }

  invalidate(): void {}
  dispose(): void {}
}

function installHeader(pi: ExtensionAPI, ctx: ExtensionContext): () => void {
  let header: OpenTuiHeader | undefined;
  ctx.ui.setHeader((tui) => {
    header?.dispose();
    header = new OpenTuiHeader(pi, ctx, tui);
    return header;
  });
  return () => {
    header?.dispose();
    header = undefined;
    ctx.ui.setHeader(undefined);
  };
}

export default function headerExtension(pi: ExtensionAPI): void {
  let cleanup: (() => void) | undefined;

  pi.on("session_start", (_event, ctx) => {
    if (ctx.mode !== "tui") return;
    cleanup?.();
    cleanup = installHeader(pi, ctx);
  });

  pi.on("session_shutdown", () => {
    cleanup?.();
    cleanup = undefined;
  });
}
