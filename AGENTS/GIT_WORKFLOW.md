# GIT_WORKFLOW.md

Use these rules only when the task includes branch, commit, or pull request work.

## Branches

- Base branch is `main`, or `master` if the repository uses `master`.
- Prefer working on a feature branch instead of committing directly to the base branch.
- If the project explicitly allows direct commits on `main` or `master`, follow the project rule.
- Branch name format: `<prefix>/<camelCaseName>`.
- Recommended prefixes: `features/`, `bugfix/`, `refactor/`, `docs/`.

Examples:
- `features/addSpinoff`
- `bugfix/fixContactForm`
- `refactor/centralizeRendering`
- `docs/updateArchitecture`

## Commits

- Write commit messages in English unless the project says otherwise.
- Prefer prefixes such as `Feature:`, `Bug-fix:`, `Refactor:`, `Docs:`, or `Chore:`.
- Keep the first line under 72 characters.
- Avoid generic messages such as `fix`, `update`, or `changes`.
- Do not mix unrelated changes in the same commit.

## Pre-commit Checks

- Run the project's relevant lint, test, or validation commands when available and appropriate.
- Do not commit secrets, API keys, `.env` files, private keys, auth headers, cookies, or personal data.
- Review staged files for sensitive data before every commit.
- If any suspicious value is found, stop and ask the user for explicit confirmation before proceeding.

## Mandatory Sensitive-data Gate

- This gate applies to every commit.
- A commit must not proceed until staged changes have been checked for sensitive data leakage.
- If even one suspicious value is found, stop immediately and report the file and path.

## Pull Requests

- Open a PR from the feature branch to the base branch unless the project explicitly allows a direct commit flow.
- Use a clear title and summary.
- Reference the project's issue tracker, TODO file, or related task if one exists.
