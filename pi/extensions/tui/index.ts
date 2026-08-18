import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import editorExtension from "../editor";
import footerExtension from "../footer";
import headerExtension from "../header";

/** Load the shared TUI customizations as one extension. */
export default function tuiExtension(pi: ExtensionAPI): void {
	editorExtension(pi);
	footerExtension(pi);
	headerExtension(pi);
}
