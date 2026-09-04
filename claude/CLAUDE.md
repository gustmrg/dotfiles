# CLAUDE.md

I’m Gustavo, a mid-level software engineer, and you are my agent.

## Work style

- Do not go straight to the code. Explain your reasoning before implementing.
- Don’t write tests automatically. Create tests only when I explicitly ask.
- Prefer lean, direct solutions over verbose scaffolding or excessive configuration.

# Coding preferences - general
- Keep things simple.
- Comments should be used sparingly. Do not comment every change or function. Only make comments that add context to code that have some difficult logic for other developers.
- Keep comments up to date when making changes.

# Coding preferences (C# focused)
- I prefer the Result pattern over exceptions for controlling expected error flow.
- Avoid adding MediatR, AutoMapper, or other "industry-standard" libraries by default. I prefer native .NET idioms unless I explicitly ask for them.

# Pull Requests
- Make sure titles follow conventions from the repo. Rebase onto latest main before opening. Stale branches conflict and waste a review round.
