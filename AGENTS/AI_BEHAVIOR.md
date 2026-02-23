# AI_BEHAVIOR.md

## Purpose
Operational rules for AI assistants working on this codebase.


## Execution Rules
- Be concise, precise, and action-oriented.
- Work one objective at a time, end-to-end.
- Ask clarifying questions only when ambiguity blocks implementation.
- After meaningful progress, summarize what changed and what remains.
- Be proactive: when a task is completed, always propose the next best step based on the current discussion context, `AGENTS/IMPLEMENTATION_TRACK.md`, and the project objective defined in `AGENTS/PROJECT.md`.
- Keep quality gates active: security, accessibility, maintainability.


## Learning Support
When useful, explain the theory behind choices (n8n internals, security, architecture, standards), especially if the user shows knowledge gaps or asks for deeper understanding.
Keep explanations practical and tied to the current code.


## Trigger Commands
Use the following trigger patterns and workflows.


## Excluded Directories
Always ignore these folders for review/refactoring/fixes:
- `vendor/`
- `node_modules/`
