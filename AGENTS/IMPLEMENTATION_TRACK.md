# Implementation Track

## 1) Project Objective
Describe in 5-10 lines what the project must achieve when complete.

- Problem solved:
- Target users:
- Expected final outcome:
- Success metrics (e.g., time saved, reduced errors, completed automations):

## 2) Context and Constraints
List the technical and organizational constraints that must be respected.

- Required stack/tools:
- Infrastructure constraints (server, network, on-prem, etc.):
- Security/compliance constraints:
- Operational constraints (deployment windows, backup, rollback):

## 3) Features (Text Backlog)
List features in logical order, each using this format.

### Feature 1 - <Name>
- Description:
- User value:
- Expected inputs:
- Expected outputs:
- Dependencies:
- Priority: MVP | v1 | v2
- Status: todo | in-progress | done
- Acceptance criteria:
  1. 
  2. 
  3. 
- Minimum manual test:
  1. 
  2. 
  3. 

### Feature 2 - <Name>
- Description:
- User value:
- Expected inputs:
- Expected outputs:
- Dependencies:
- Priority: MVP | v1 | v2
- Status: todo | in-progress | done
- Acceptance criteria:
  1. 
  2. 
  3. 
- Minimum manual test:
  1. 
  2. 
  3. 

## 4) Priorities and Releases
Group features by milestone.

### MVP
- [ ] Feature <id>
- [ ] Feature <id>

### v1
- [ ] Feature <id>
- [ ] Feature <id>

### v2
- [ ] Feature <id>
- [ ] Feature <id>

## 5) Step-by-Step Implementation Plan
Break work into small, sequential, and verifiable tasks.

Status legend:
- `todo`: not started
- `in-progress`: currently being worked on
- `done`: completed and verified
- `blocked`: waiting on dependency/decision

Use both markers for each step:
- Checkbox: `- [ ]` (to do) or `- [x]` (done)
- Status field: `todo | in-progress | done | blocked`

### Step 1 - <Title>
- [ ] Step completion
- Objective:
- Activities:
  1. 
  2. 
  3. 
- Definition of done:
- Expected output:
- Status: todo | in-progress | done | blocked
- Started on: YYYY-MM-DD
- Completed on: YYYY-MM-DD

### Step 2 - <Title>
- [ ] Step completion
- Objective:
- Activities:
  1. 
  2. 
  3. 
- Definition of done:
- Expected output:
- Status: todo | in-progress | done | blocked
- Started on: YYYY-MM-DD
- Completed on: YYYY-MM-DD

## 6) Risks and Dependencies

### Risks
- Risk:
  - Impact:
  - Probability:
  - Mitigation:

### External dependencies
- Dependency:
  - Type (technical/organizational/vendor):
  - Potential blocker:
  - Backup plan:

## 7) Operational Rules for Implementation
Use these rules to keep this file as the single development track.

- Every new development request must reference one Feature and one specific Step.
- Before starting any change, set the Step status to in-progress.
- After implementation and testing, set the Step status to done.
- If new scope appears, add it here before implementing it.
- Do not place secrets in the repository or in workflow JSON files.

## 8) Decision Log
Track relevant technical decisions.

- Date:
- Decision:
- Rationale:
- Alternatives considered:
- Impact:

## 9) Recommended Prompt Commands
Use these prompts to work consistently with this track.

1. "Implement Feature <id>, Step <id> in `AGENTS/IMPLEMENTATION_TRACK.md`."
2. "Update status and acceptance criteria of Feature <id> after the changes."
3. "Review Step <id> against the defined acceptance criteria."
4. "Propose the next minimum Step to progress toward MVP."
