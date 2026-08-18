import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const EFFORT_LEVELS = ["off", "minimal", "low", "medium", "high", "xhigh", "max"] as const;
type EffortLevel = (typeof EFFORT_LEVELS)[number];

function isEffortLevel(value: string): value is EffortLevel {
	return (EFFORT_LEVELS as readonly string[]).includes(value);
}

export default function effortExtension(pi: ExtensionAPI) {
	pi.registerCommand("effort", {
		description: "Show or set the current reasoning effort",
		getArgumentCompletions: (prefix) => {
			const normalizedPrefix = prefix.trim().toLowerCase();
			const matches = EFFORT_LEVELS.filter((level) => level.startsWith(normalizedPrefix));
			return matches.length > 0 ? matches.map((level) => ({ value: level, label: level })) : null;
		},
		handler: async (args, ctx) => {
			const requested = args.trim().toLowerCase();

			if (!requested) {
				ctx.ui.notify(`Reasoning effort: ${pi.getThinkingLevel()}`, "info");
				return;
			}

			if (!isEffortLevel(requested)) {
				ctx.ui.notify(`Invalid effort "${requested}". Use: ${EFFORT_LEVELS.join(", ")}`, "error");
				return;
			}

			pi.setThinkingLevel(requested);
			const effective = pi.getThinkingLevel();

			if (effective !== requested) {
				ctx.ui.notify(
					`Requested ${requested}; current model clamped reasoning effort to ${effective}`,
					"warning",
				);
				return;
			}

			ctx.ui.notify(`Reasoning effort set to ${effective}`, "info");
		},
	});
}
