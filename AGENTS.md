## Response Style

- This project is often used through the Discord connector.
- Do not use clickable local file links in responses.
- When referring to local files, mention plain filenames or repository-relative paths only.
- Example: use `Packages/BaseballLiveKRCore/Package.swift`, not markdown file links.

## Discord Completion Notification

- When finishing a task for this project through the Discord connector, start the final response with `<@&1511599995021824020>`.
- Keep the mention at the very beginning of the final response so Discord can send a role notification.
- Do not add the mention to intermediate progress updates.

## Discord Response Splitting

- When responding through the Discord connector, split long answers into multiple messages.
- Keep each message short enough to avoid Discord truncation.
- Start split responses with `(1/N)`, `(2/N)`, and so on.
- Do not split code blocks across messages.
- Split long lists by section or into groups of about five items.

## Recommended Codex Launch

- For future sessions that need to commit, install project-local skills, or write `.git`/`.agents`, launch Codex from the project root with:

```bash
codex --sandbox danger-full-access --ask-for-approval never --search
```

- The same launch is available via:

```bash
./scripts/codex-full-access.sh
```
