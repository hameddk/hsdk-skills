# Contributing

Personal repo. PRs welcome but not expected.

## Editing skills

Skill source-of-truth lives in `skills/<name>/SKILL.md`. The install script symlinks
these into Claude Code and Cursor — no need to copy files.

After editing a SKILL.md:
1. Test by invoking the slash command in a real project.
2. Commit with a message describing the behavioral change, not the file change.
3. Restart Claude Code if the change isn't picked up immediately.

## Conventions

- All code in English. Comments in English. Commit messages in English.
- Skills must persist `state.json` after every status transition. No exceptions.
- Keep orchestration output terse. Underlying gstack skills produce their own output.
- New skills: add a SKILL.md under `skills/<name>/`, update `bin/install` and `bin/uninstall`,
  update README.

## Out of scope

- Cherry-picking which gstack skills to install. User installs full gstack pack.
- Cross-platform support beyond macOS/Linux. Windows users are on their own.
- Telemetry, analytics, auto-update. None of this. Ever.
