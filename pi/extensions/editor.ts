import {
	CustomEditor,
	type ExtensionAPI,
	type ExtensionContext,
	type KeybindingsManager,
} from "@earendil-works/pi-coding-agent";
import type { EditorTheme, TUI } from "@earendil-works/pi-tui";
import { CURSOR_MARKER, truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

type CursorStyle = "block" | "bar" | "underline";

function stripAnsi(text: string): string {
	return text
		.replace(/\x1b\[[0-9;]*m/g, "")
		.replace(/\x1b\][^\x07]*(?:\x07|\x1b\\)/g, "")
		.replace(/\x1b_[^\x07]*\x07/g, "");
}

function isEditorBorderLine(line: string): boolean {
	const plain = stripAnsi(line);
	return /^─+$/.test(plain) || /^─*\s*[↑↓]\s+\d+\s+more\s*─*$/.test(plain);
}

function findBottomBorderIndex(lines: string[]): number {
	for (let i = lines.length - 1; i >= 1; i--) {
		if (isEditorBorderLine(lines[i]!)) return i;
	}
	return Math.max(0, lines.length - 1);
}

function fillLine(content: string, width: number): string {
	const truncated = truncateToWidth(content, Math.max(0, width), "");
	const pad = " ".repeat(Math.max(0, width - visibleWidth(truncated)));
	return `${truncated}${pad}`;
}

const CURSOR_STYLE_SEQUENCES: Partial<Record<CursorStyle, string>> = {
	bar: "\x1b[6 q",
	underline: "\x1b[4 q",
};
const DEFAULT_CURSOR_STYLE_SEQUENCE = "\x1b[0 q";

function removeSoftwareCursor(line: string, cursorMarker = ""): string {
	return line.replace(/\x1b\[7m([\s\S]*?)\x1b\[0m/g, (_match, cursor: string) => {
		const replacement = `${cursorMarker}${cursor}`;
		cursorMarker = "";
		return replacement;
	});
}

function configureCursor(tui: TUI, cursorStyle: CursorStyle): void {
	if (cursorStyle === "block") return;
	tui.setShowHardwareCursor(true);
	const sequence = CURSOR_STYLE_SEQUENCES[cursorStyle];
	if (sequence) tui.terminal.write(sequence);
}

function horizontalBorder(
	width: number,
	_sourceKind: "top" | "bottom",
	paint: (s: string) => string,
	sourceLine?: string,
	label?: string,
): string {
	if (width < 1) return "";

	if (sourceLine) {
		const plain = stripAnsi(sourceLine);
		const scrollMatch = plain.match(/([↑↓]\s+\d+\s+more)/);
		if (scrollMatch) {
			const shown = `─── ${scrollMatch[1]} `;
			const fill = Math.max(0, width - visibleWidth(shown));
			return paint(`${shown}${"─".repeat(fill)}`);
		}
	}

	if (label) {
		const shown = ` ${label} `;
		const fill = Math.max(0, width - visibleWidth(shown));
		return paint(`${shown}${"─".repeat(fill)}`);
	}
	return paint("─".repeat(width));
}

export class OpenTuiEditor extends CustomEditor {
	private readonly getBorder: (s: string) => string;
	private cursorStyle: CursorStyle;
	private previewHardwareCursor = false;

	constructor(
		tui: TUI,
		editorTheme: EditorTheme,
		keybindings: KeybindingsManager,
		cursorStyle: CursorStyle = "block",
	) {
		super(tui, editorTheme, keybindings, { paddingX: 0 });
		this.cursorStyle = cursorStyle;
		configureCursor(tui, cursorStyle);
		// ponytail: route the frame through this.borderColor so Pi can recolor it
		// via updateEditorBorderColor() — bash mode ("! " prefix → green) and
		// thinking-level borders both flow through this one property.
		this.getBorder = (s: string) => this.borderColor(s);
	}

	override setPaddingX(_padding: number): void {
		// Keep the editor's horizontal padding disabled; the prompt supplies the only inset.
		super.setPaddingX(0);
	}

	setCursorStyle(cursorStyle: CursorStyle, blockHardwareCursor = false): void {
		const styleChanged = cursorStyle !== this.cursorStyle;
		this.previewHardwareCursor = cursorStyle !== "block";
		this.cursorStyle = cursorStyle;
		if (styleChanged) {
			if (cursorStyle === "block") {
				this.tui.terminal.write(DEFAULT_CURSOR_STYLE_SEQUENCE);
				this.tui.setShowHardwareCursor(blockHardwareCursor);
			} else {
				configureCursor(this.tui, cursorStyle);
			}
		}
		this.tui.requestRender();
	}

	private renderBase(width: number): string[] {
		const renderedLines = super.render(width);
		if (this.cursorStyle === "block") return renderedLines;

		// A focused overlay suppresses the editor's cursor marker. Preserve its
		// position only for the live settings preview, then clear it on refocus.
		let cursorMarker = this.previewHardwareCursor && !this.focused ? CURSOR_MARKER : "";
		if (this.focused) this.previewHardwareCursor = false;
		return renderedLines.map((line) => {
			const rendered = removeSoftwareCursor(line, cursorMarker);
			if (rendered !== line) cursorMarker = "";
			return rendered;
		});
	}

	render(width: number): string[] {
		if (width < 4) return this.renderBase(width);

		const borderPaint = this.getBorder;
		const isBash = this.getText().trimStart().startsWith("!");
		// Leave room for the prompt and its following space; the input has no side borders.
		const innerWidth = Math.max(0, width - 2);
		const baseLines = this.renderBase(innerWidth);
		const bottomIdx = findBottomBorderIndex(baseLines);

		const result: string[] = [];
		result.push(horizontalBorder(width, "top", borderPaint, baseLines[0], isBash ? "! shell mode" : undefined));

		for (let i = 1; i < bottomIdx; i++) {
			let line = baseLines[i] ?? "";
			if (isEditorBorderLine(line)) line = "";
			if (i === 1 && isBash) {
				const bang = line.indexOf("!");
				if (bang !== -1) line = line.slice(0, bang) + line.slice(bang + 1);
			}
			const prompt = i === 1 ? (isBash ? borderPaint("!") : ">") : " ";
			result.push(`${prompt} ${fillLine(line, innerWidth)}`);
		}

		result.push(horizontalBorder(width, "bottom", borderPaint, baseLines[bottomIdx]));

		for (let i = bottomIdx + 1; i < baseLines.length; i++) {
			result.push(baseLines[i]!);
		}

		return result.map((line) => truncateToWidth(line, width, ""));
	}
}

function installEditor(
	_pi: ExtensionAPI,
	ctx: ExtensionContext,
	cursorStyle: CursorStyle = "block",
) {
	let activeTui: TUI | undefined;
	let activeEditor: OpenTuiEditor | undefined;
	let previousHardwareCursor: boolean | undefined;
	let currentCursorStyle = cursorStyle;

	ctx.ui.setEditorComponent((tui, editorTheme, keybindings) => {
		activeTui = tui;
		previousHardwareCursor = tui.getShowHardwareCursor();
		activeEditor = new OpenTuiEditor(tui, editorTheme, keybindings, currentCursorStyle);
		return activeEditor;
	});
	return {
		setCursorStyle(nextCursorStyle: CursorStyle): void {
			currentCursorStyle = nextCursorStyle;
			activeEditor?.setCursorStyle(nextCursorStyle, previousHardwareCursor);
		},
		cleanup(): void {
			ctx.ui.setEditorComponent(undefined);
			if (activeTui) {
				if (currentCursorStyle !== "block") activeTui.terminal.write(DEFAULT_CURSOR_STYLE_SEQUENCE);
				if (previousHardwareCursor !== undefined) activeTui.setShowHardwareCursor(previousHardwareCursor);
			}
		},
	};
}

export default function editorExtension(pi: ExtensionAPI): void {
	let cleanup: (() => void) | undefined;

	pi.on("session_start", (_event, ctx) => {
		if (ctx.mode !== "tui") return;
		cleanup?.();
		cleanup = installEditor(pi, ctx, "block").cleanup;
	});

	pi.on("session_shutdown", () => {
		cleanup?.();
		cleanup = undefined;
	});
}
