# GIT_WORKFLOW.md

Use these rules only when the task includes branch/commit/PR work.


## Branches

- Base branch: `main`.
- Never commit directly to `main`.
- Branch name format: `<prefix>/<camelCaseName>`.
- Prefixes: `features/`, `bugfix/`, `refactor/`, `docs/`.
- Examples:
  - `features/addSpinoff`
  - `bugfix/fixContactForm`
  - `refactor/centralizeRendering`
  - `docs/updateArchitecture`


## Commits

- Commit messages in English.
- Prefer prefixes: `Bug-fix:`, `Refactor:`, `Feature:`, `Docs:`.
- For maintenance/snapshot activities, use `Chore:` as prefix.
- First line under 72 characters.
- Avoid generic messages like `fix` or `update`.

Examples:
- `Feature: Add spinoff content type and archive page`
- `Bug-fix: Fix XSS vulnerability in contact form submission`
- `Refactor: Centralize event date rendering logic`
- `Docs: Update ARCHITECTURE.md after menu refactor`
- `Chore: Pull latest workflows from server (snapshot)`


## Pre-commit checks

- Run `composer run lint:php` when possible.
- Do not commit secrets, API keys, or `.env` files.
- Before every commit, scan staged files for sensitive data (for example: API keys, tokens, passwords, private keys, auth headers, cookies, personal data).
- If potential sensitive data is found, stop the commit flow, report exactly what was found and where (file/path), and ask the user for explicit confirmation before proceeding.
- Do not include unrelated changes in the same commit.

### MANDATORY SENSITIVE DATA GATE (VERY IMPORTANT)

- This check is mandatory for every commit, without exceptions.
- A commit must not proceed until staged files have been reviewed for sensitive data leakage.
- If even one suspicious value is found, stop immediately and ask for explicit user confirmation before any commit action.


## Pull Requests

- Open PR from feature branch to `main`.
- Write clear title and summary.
- Reference related issues from `ISSUES_TODO.md` when applicable.
