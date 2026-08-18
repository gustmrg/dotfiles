import { execFile } from "node:child_process";
import { existsSync } from "node:fs";
import { basename, join, relative, resolve, sep } from "node:path";
import { promisify } from "node:util";
import type { AssistantMessage } from "@earendil-works/pi-ai";
import type { ExtensionAPI, ExtensionContext, Theme, ThemeColor } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth, wrapTextWithAnsi } from "@earendil-works/pi-tui";

const execFileAsync = promisify(execFile);

function useNerdFont(): boolean {
	if (process.env.PI_FOOTER_NERD_FONT === "1") return true;
	if (process.env.PI_FOOTER_NERD_FONT === "0") return false;
	const terminal = (process.env.TERM_PROGRAM ?? process.env.LC_TERMINAL ?? "").toLowerCase();
	return ["iterm.app", "ghostty", "wezterm", "kitty", "rio", "tabby", "windowsterminal", "vscode"].includes(terminal)
		|| process.env.TERM === "xterm-kitty"
		|| process.env.TERM === "xterm-ghostty"
		|| Boolean(process.env.WT_SESSION);
}

const NERD_FONT_ENABLED = useNerdFont();
const THINKING_GLYPH = NERD_FONT_ENABLED ? "" : "~";
const BOT_GLYPH = NERD_FONT_ENABLED ? "󰚩" : "";

type Runtime = { name: string; command?: string; args?: string[]; pattern?: RegExp; files: string[] };
type RuntimeInfo = { name: string; version?: string };
type UsageTotals = { input: number; output: number; cacheRead: number; cacheWrite: number; cost: number; cacheHit?: number };

const RUNTIMES: Runtime[] = [
	{ name: "node", files: ["package.json", ".nvmrc", ".node-version"], command: "node", args: ["--version"], pattern: /v(\d+(?:\.\d+)+)/ },
	{ name: "bun", files: ["bun.lock", "bun.lockb"], command: "bun", args: ["--version"], pattern: /(\d+(?:\.\d+)+)/ },
	{ name: "deno", files: ["deno.json", "deno.jsonc", "deno.lock"], command: "deno", args: ["--version"], pattern: /deno\s+(\d+(?:\.\d+)+)/ },
	{ name: "rust", files: ["Cargo.toml"], command: "rustc", args: ["--version"], pattern: /rustc\s+(\d+(?:\.\d+)+)/ },
	{ name: "go", files: ["go.mod"], command: "go", args: ["version"], pattern: /go(\d+(?:\.\d+)+)/ },
	{ name: "python", files: ["pyproject.toml", "requirements.txt", "Pipfile", "setup.py"], command: "python3", args: ["--version"], pattern: /Python\s+(\d+(?:\.\d+)+)/ },
	{ name: "ruby", files: ["Gemfile", ".ruby-version"], command: "ruby", args: ["--version"], pattern: /ruby\s+(\d+(?:\.\d+)+)/ },
	{ name: "java", files: ["pom.xml", "build.gradle", "build.gradle.kts"], command: "java", args: ["-version"], pattern: /version\s+"(\d+(?:\.\d+)*)/ },
	{ name: "php", files: ["composer.json"], command: "php", args: ["--version"], pattern: /PHP\s+(\d+(?:\.\d+)+)/ },
	{ name: "dotnet", files: ["global.json", "Directory.Build.props"], command: "dotnet", args: ["--version"], pattern: /(\d+(?:\.\d+)+)/ },
];

function formatCwd(cwd: string): string {
	const home = process.env.HOME ?? process.env.USERPROFILE;
	if (!home) return cwd;
	const rel = relative(resolve(home), resolve(cwd));
	const insideHome = rel === "" || (rel !== ".." && !rel.startsWith(`..${sep}`));
	return insideHome ? (rel ? `~${sep}${rel}` : "~") : cwd;
}

function fmtTokens(value: number): string {
	if (value < 1_000) return String(value);
	if (value < 10_000) return `${(value / 1_000).toFixed(1)}k`;
	if (value < 1_000_000) return `${Math.round(value / 1_000)}k`;
	return value < 10_000_000 ? `${(value / 1_000_000).toFixed(1)}M` : `${Math.round(value / 1_000_000)}M`;
}

function formatDuration(ms: number): string {
	const seconds = Math.max(0, Math.floor(ms / 1_000));
	if (seconds < 60) return `${seconds}s`;
	const minutes = Math.floor(seconds / 60);
	if (minutes < 60) return `${minutes}m ${seconds % 60}s`;
	return `${Math.floor(minutes / 60)}h ${minutes % 60}m`;
}

function stressColor(percent: number): ThemeColor {
	return percent >= 90 ? "error" : percent >= 70 ? "warning" : "accent";
}

function effortColor(effort: string): ThemeColor {
	if (effort === "minimal") return "thinkingMinimal";
	if (effort === "low") return "thinkingLow";
	if (effort === "high") return "thinkingHigh";
	if (effort === "xhigh" || effort === "max") return "thinkingXhigh";
	return "thinkingMedium";
}

function usageTotals(ctx: ExtensionContext): UsageTotals {
	const totals: UsageTotals = { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, cost: 0 };
	for (const entry of ctx.sessionManager.getEntries()) {
		if (entry.type !== "message" || entry.message.role !== "assistant") continue;
		const usage = (entry.message as AssistantMessage).usage;
		if (!usage) continue;
		totals.input += usage.input ?? 0;
		totals.output += usage.output ?? 0;
		totals.cacheRead += usage.cacheRead ?? 0;
		totals.cacheWrite += usage.cacheWrite ?? 0;
		totals.cost += usage.cost?.total ?? 0;
		const prompt = (usage.input ?? 0) + (usage.cacheRead ?? 0) + (usage.cacheWrite ?? 0);
		if (prompt > 0) totals.cacheHit = ((usage.cacheRead ?? 0) / prompt) * 100;
	}
	return totals;
}

async function detectRuntime(cwd: string): Promise<RuntimeInfo | undefined> {
	const runtime = RUNTIMES.find((candidate) => candidate.files.some((file) => existsSync(join(cwd, file))));
	if (!runtime) return undefined;
	if (!runtime.command) return { name: runtime.name };
	try {
		const result = await execFileAsync(runtime.command, runtime.args ?? [], { cwd, timeout: 2_000, maxBuffer: 16_384 });
		const output = `${result.stdout}\n${result.stderr}`;
		return { name: runtime.name, version: runtime.pattern?.exec(output)?.[1] };
	} catch {
		return { name: runtime.name };
	}
}

function align(left: string, right: string, width: number, theme: Theme): string {
	if (!right) return truncateToWidth(left, width, theme.fg("dim", "..."));
	const rightText = truncateToWidth(right, width, theme.fg("dim", "..."));
	const available = width - visibleWidth(rightText) - 1;
	if (available <= 0) return rightText;
	const leftText = truncateToWidth(left, available, theme.fg("dim", "..."));
	return leftText + " ".repeat(Math.max(1, width - visibleWidth(leftText) - visibleWidth(rightText))) + rightText;
}

function contextBlock(ctx: ExtensionContext, theme: Theme, width: number): string {
	const usage = ctx.getContextUsage();
	const contextWindow = usage?.contextWindow ?? ctx.model?.contextWindow ?? 0;
	if (contextWindow <= 0) return "";
	const tokens = usage?.tokens ?? 0;
	const percent = usage?.percent ?? 0;
	const color = stressColor(percent);
	if (width < 80) return `${theme.fg(color, "ctx")} ${theme.fg(color, `${percent.toFixed(1)}%`)}`;
	const size = Math.max(4, Math.min(12, Math.floor(width / 12)));
	const filled = Math.round((Math.max(0, Math.min(100, percent)) / 100) * size);
	const bar = theme.fg(color, "█".repeat(filled)) + theme.fg("dim", "░".repeat(size - filled));
	return `${theme.fg(color, "ctx")} ${theme.fg("dim", "[")}${bar}${theme.fg("dim", "]")} ${theme.fg(color, `${percent.toFixed(1)}%`)} ${theme.fg("dim", "·")} ${fmtTokens(tokens)}/${fmtTokens(contextWindow)}`;
}

export default function footerExtension(pi: ExtensionAPI) {
	let runtime: RuntimeInfo | undefined;
	let workingSince: number | undefined;
	let lastDoneIn: number | undefined;
	let timer: ReturnType<typeof setInterval> | undefined;
	let requestRender: (() => void) | undefined;

	const stopTimer = () => {
		if (timer) clearInterval(timer);
		timer = undefined;
	};

	pi.on("session_start", async (_event, ctx) => {
		if (ctx.mode !== "tui") return;
		runtime = await detectRuntime(ctx.cwd);
		ctx.ui.setFooter((tui, theme, footerData) => {
			requestRender = () => tui.requestRender();
			return {
				dispose() { requestRender = undefined; },
				invalidate() {},
				render(width: number): string[] {
					if (width <= 0) return [""];
					const horizontalPadding = width >= 10 ? "  " : "";
					const contentWidth = Math.max(1, width - visibleWidth(horizontalPadding) * 2);
					const cwd = formatCwd(ctx.sessionManager.getCwd());
					const cwdCompact = basename(cwd) || cwd;
					const location = theme.fg("accent", contentWidth < 70 ? cwdCompact : cwd);
					const sessionName = ctx.sessionManager.getSessionName();
					const session = sessionName && contentWidth >= 100 ? ` ${theme.fg("dim", "·")} ${theme.fg("text", truncateToWidth(sessionName, 24, "..."))}` : "";
					const runtimeText = runtime ? ` ${theme.fg("dim", "·")} ${theme.fg("success", runtime.name)}${runtime.version ? ` ${theme.fg("muted", runtime.version)}` : ""}` : "";
					let activity = "";
					if (workingSince !== undefined) activity = `${theme.fg("accent", "● working")} ${theme.fg("accent", formatDuration(Date.now() - workingSince))}`;
					else if (lastDoneIn !== undefined) activity = `${theme.fg("success", "✓ done")} ${theme.fg("text", formatDuration(lastDoneIn))}`;
					const left1 = `${location}${session}${runtimeText}${activity ? ` ${theme.fg("dim", "·")} ${activity}` : ""}`;
					const line1 = align(left1, contextBlock(ctx, theme, contentWidth), contentWidth, theme);

					const provider = ctx.model?.provider;
					const model = ctx.model?.name ?? ctx.model?.id ?? "no model";
					const providerText = provider ? theme.fg("muted", provider) : "";
					const modelText = [
						BOT_GLYPH ? theme.fg("text", BOT_GLYPH) : "",
						theme.fg("text", model),
					].filter(Boolean).join(" ");
					const modelParts = [providerText, modelText].filter(Boolean);
					const effort = ctx.model?.reasoning ? pi.getThinkingLevel() : "off";
					if (effort !== "off") modelParts.push(theme.fg(effortColor(effort), `${THINKING_GLYPH} ${effort}`));
					const totals = usageTotals(ctx);
					const stats = [theme.fg("accent", `↑ ${fmtTokens(totals.input)}`), theme.fg("success", `↓ ${fmtTokens(totals.output)}`)];
					if ((totals.cacheRead > 0 || totals.cacheWrite > 0) && totals.cacheHit !== undefined) stats.push(theme.fg("muted", `cache ${totals.cacheHit.toFixed(1)}%`));
					stats.push(theme.fg("warning", `$${totals.cost.toFixed(3)}`));
					const separator = theme.fg("dim", " · ");
					const line2 = align(modelParts.join(separator), stats.join(separator), contentWidth, theme);

					const statuses = [...footerData.getExtensionStatuses().entries()]
						.sort(([a], [b]) => a.localeCompare(b))
						.map(([, text]) => text.replace(/[\u0000-\u001f\u007f-\u009f]/g, " ").trim())
						.filter(Boolean);
					const statusLines = statuses.length ? wrapTextWithAnsi(`${theme.fg("mdLink", "ext")} ${statuses.map((text) => theme.fg("muted", text)).join(theme.fg("dim", " | "))}`, contentWidth) : [];
					return [line1, line2, ...statusLines].map((line) => `${horizontalPadding}${line}${horizontalPadding}`);
				},
			};
		});
		requestRender?.();
	});

	pi.on("agent_start", () => {
		workingSince = Date.now();
		lastDoneIn = undefined;
		stopTimer();
		timer = setInterval(() => requestRender?.(), 250);
		timer.unref?.();
		requestRender?.();
	});

	pi.on("agent_end", () => {
		stopTimer();
		if (workingSince !== undefined) lastDoneIn = Date.now() - workingSince;
		workingSince = undefined;
		requestRender?.();
	});

	for (const event of ["message_end", "model_select", "thinking_level_select", "session_compact", "session_tree", "tool_execution_end"] as const) {
		pi.on(event, () => requestRender?.());
	}

	pi.on("session_shutdown", (_event, ctx) => {
		stopTimer();
		requestRender = undefined;
		if (ctx.mode === "tui") ctx.ui.setFooter(undefined);
	});
}
