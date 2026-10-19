CLAUDE.md

I'm a mid-level software engineer working in fintech (backend-heavy,
C#/.NET; frontend in TypeScript). I understand fundamentals well and want
architecture decisions discussed with me, not just decided for me — but I
don't need basic concepts over-explained.

You are my agent.

Work style

* For non-trivial changes, explain your reasoning before implementing. For trivial fixes (typos, one-liners), just make the change.
* When a task is ambiguous, stop and ask before proceeding — don't guess at intent.
* Don't write tests automatically. Create tests only when I explicitly ask.
* Prefer lean, direct solutions over verbose scaffolding or excessive configuration (e.g. avoid unnecessary DTOs, premature abstraction layers, or config for options I'm not using).

Coding preferences - general

* Keep things simple.
* Comments should be used sparingly. Do not comment every change or function. Only make comments that add context to code that have some difficult logic for other developers.
* Keep comments up to date when making changes.

Working with existing codebases

* When working in an existing repo, follow the architecture and patterns already established there (even if they differ from my stated preferences below), unless I explicitly ask for a refactor or migration.
* My stated preferences (Result pattern, no MediatR/AutoMapper, default TS stack, etc.) apply to new projects or new modules where no existing convention exists yet.
* If you think the existing pattern conflicts badly with a new feature, flag it and ask — don't silently mix patterns in the same codebase.

Coding preferences (C# / .NET — backend)

* I prefer the Result pattern over exceptions for controlling expected error flow.
* Avoid adding MediatR, AutoMapper, or other "industry-standard" libraries by default. I prefer native .NET idioms unless I explicitly ask for them.

Coding preferences (TypeScript — frontend, React/Angular)

* For new projects, my default stack is Vite + React + Zod + Shadcn UI (adjust if I specify otherwise, e.g. Angular for a given repo).
* Prefer native language/framework features over adding utility libraries by default (e.g. lodash, moment) unless I explicitly ask for them.
* Keep component and state logic simple — avoid premature abstraction (e.g. generic wrapper components, extra context layers) for things used once.
* Type things explicitly where it aids clarity; avoid `any` unless there's no reasonable alternative.

Pull Requests

* Make sure titles follow conventions from the repo. Rebase onto latest main before opening. Stale branches conflict and waste a review round.
