# Implementation Track

## 1) Project Objective
Build an n8n automation that publishes notifications for new posts from a WordPress site to social channels with explicit approval gating by email before publishing. The workflow must check for new posts every hour, process each new post, generate a social message with AI (max 280 characters), include hashtag `#n8n`, and publish only after approval.

- Problem solved: manual and repetitive social publishing after WordPress post publication.
- Target users: site owner/editor managing social publication from a single workflow.
- Expected final outcome: reliable pipeline from WordPress post detection to approved social publication.
- Success metrics:
  - New posts detected within 60 minutes.
  - Zero secrets in source files/repository.
  - Approval flow works per channel (approve/reject).
  - Published message always includes URL, featured image, and `#n8n`.

## 2) Context and Constraints
- Required stack/tools:
  - n8n (workflow orchestration)
  - WordPress REST API (source)
  - OpenAI (AI text generation)
  - SMTP authenticated server (approval emails)
  - Social platform nodes/APIs (Twitter/X, Telegram, Instagram, Facebook)
- Infrastructure constraints:
  - Project env vars must use the `WSP8_` prefix.
  - Development environment vars: `WSP8_N8N_BASE_URL`, `WSP8_N8N_API_KEY`.
  - n8n runtime vars: `WSP8_WP_SITE_URL`, `WSP8_APPROVAL_EMAIL`, `WSP8_APPROVAL_NAME`.
  - WordPress base URL must come from `WSP8_WP_SITE_URL`.
  - Approval recipient email must come from `WSP8_APPROVAL_EMAIL`.
  - Approval recipient display name must come from `WSP8_APPROVAL_NAME`.
  - Polling schedule: every hour.
- Security/compliance constraints:
  - No username/password/token/API key in repository, Markdown, workflow JSON, or source files.
  - All secrets and account credentials must be stored only in n8n Credentials.
  - `N8N_ENCRYPTION_KEY` must be configured on n8n server.
  - Workflow JSON may reference credentials by name/id only.
- Operational constraints:
  - If no new posts are found, the workflow exits without side effects.
  - If approval is rejected, action is `skip` (no publish).
  - Build and release incrementally by channel priority: Twitter/X, Telegram, Instagram, Facebook.

## 3) Features (Text Backlog)
### Feature 1 - Hourly WordPress New Post Detection
- Description: every hour, query WordPress and detect posts not yet processed.
- User value: automatic discovery of new content with no manual checks.
- Expected inputs: `WSP8_WP_SITE_URL`, last processed marker/state.
- Expected outputs: list of new posts to process or empty list.
- Dependencies: WordPress API availability; n8n scheduler.
- Priority: MVP
- Status: todo
- Acceptance criteria:
  1. Scheduler runs every hour.
  2. If no new posts, workflow stops cleanly.
  3. If new posts exist, each post enters processing loop.
- Minimum manual test:
  1. Publish a new post and wait one run.
  2. Verify post is detected once.
  3. Run again without new posts and confirm no-op.

### Feature 2 - Post Data Extraction (content, featured image, URL)
- Description: for each detected post, extract topic/content summary, featured image URL, and post URL.
- User value: complete payload for social publishing.
- Expected inputs: post ID/object from Feature 1.
- Expected outputs: normalized object `{title/topic, excerpt/content, imageUrl, postUrl}`.
- Dependencies: WordPress REST fields/media endpoints.
- Priority: MVP
- Status: todo
- Acceptance criteria:
  1. Post URL is always present.
  2. Featured image is resolved when available.
  3. Missing image is handled without workflow failure.
- Minimum manual test:
  1. Test a post with featured image.
  2. Test a post without featured image.
  3. Validate normalized payload.

### Feature 3 - AI Message Generation (max 280 chars, hashtag)
- Description: generate one short announcement text via AI for each channel context, max 280 chars, must include `#n8n`.
- User value: faster copywriting with consistent style.
- Expected inputs: normalized post payload.
- Expected outputs: channel-ready message text.
- Dependencies: OpenAI credential in n8n.
- Priority: MVP
- Status: todo
- Acceptance criteria:
  1. Message length is <= 280 characters.
  2. Message includes `#n8n`.
  3. Message includes or accompanies post URL and is coherent with post topic.
- Minimum manual test:
  1. Generate message for a sample post.
  2. Validate char count and hashtag.
  3. Validate topic relevance.

### Feature 4 - Approval Email Workflow per Channel
- Description: send approval request emails (Twitter/X, Telegram, Instagram, Facebook) to one recipient from env vars.
- User value: editorial control before publishing.
- Expected inputs: generated message + post media/link + `WSP8_APPROVAL_EMAIL` + `WSP8_APPROVAL_NAME`.
- Expected outputs: approval decision per channel (approve/reject).
- Dependencies: authenticated SMTP credential in n8n.
- Priority: MVP
- Status: todo
- Acceptance criteria:
  1. One approval request is sent per channel.
  2. Recipient is read from env vars.
  3. Decision result is captured in workflow state.
- Minimum manual test:
  1. Trigger approval email generation.
  2. Confirm recipient and content are correct.
  3. Return approve and reject decisions for validation.

### Feature 5 - Conditional Publishing to Twitter/X
- Description: publish to Twitter/X only when approved.
- User value: first production channel, highest priority.
- Expected inputs: approved decision + message + URL + image.
- Expected outputs: published post/tweet or skipped action.
- Dependencies: Twitter/X credential in n8n.
- Priority: MVP
- Status: todo
- Acceptance criteria:
  1. Approve => publishes once.
  2. Reject => skip with no publication.
  3. Publication contains URL and message with `#n8n`.
- Minimum manual test:
  1. Approve case.
  2. Reject case.
  3. Validate published payload.

### Feature 6 - Conditional Publishing to Telegram
- Description: publish to Telegram only when approved.
- User value: second priority channel.
- Expected inputs: approved decision + message + URL + image.
- Expected outputs: Telegram message sent or skipped.
- Dependencies: Telegram credential in n8n.
- Priority: v1
- Status: todo
- Acceptance criteria:
  1. Approve => message sent once.
  2. Reject => skip.
  3. Message includes URL and `#n8n`.
- Minimum manual test:
  1. Approve case.
  2. Reject case.
  3. Validate final message structure.

### Feature 7 - Conditional Publishing to Instagram
- Description: publish to Instagram only when approved.
- User value: third priority channel.
- Expected inputs: approved decision + message + image/link.
- Expected outputs: Instagram publication or skipped action.
- Dependencies: Instagram/Facebook Meta credential in n8n.
- Priority: v2
- Status: todo
- Acceptance criteria:
  1. Approve => publish.
  2. Reject => skip.
  3. Channel format constraints are handled.
- Minimum manual test:
  1. Approve case.
  2. Reject case.
  3. Validate visible result on target account.

### Feature 8 - Conditional Publishing to Facebook
- Description: publish to Facebook only when approved.
- User value: fourth priority channel.
- Expected inputs: approved decision + message + image/link.
- Expected outputs: Facebook publication or skipped action.
- Dependencies: Facebook/Meta credential in n8n.
- Priority: v2
- Status: todo
- Acceptance criteria:
  1. Approve => publish.
  2. Reject => skip.
  3. Message includes URL and `#n8n`.
- Minimum manual test:
  1. Approve case.
  2. Reject case.
  3. Validate post payload.

## 4) Priorities and Releases
Group features by milestone.

### MVP
- [ ] Feature 1 - Hourly WordPress New Post Detection
- [ ] Feature 2 - Post Data Extraction
- [ ] Feature 3 - AI Message Generation
- [ ] Feature 4 - Approval Email Workflow
- [ ] Feature 5 - Conditional Publishing to Twitter/X

### v1
- [ ] Feature 6 - Conditional Publishing to Telegram

### v2
- [ ] Feature 7 - Conditional Publishing to Instagram
- [ ] Feature 8 - Conditional Publishing to Facebook

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

### Step 1 - Environment and Security Baseline
- [ ] Step completion
- Objective: define env vars and secure credentials management in n8n before building business logic.
- Activities:
  1. Define and document env vars by scope:
     - development: `WSP8_N8N_BASE_URL`, `WSP8_N8N_API_KEY`
     - n8n runtime: `WSP8_WP_SITE_URL`, `WSP8_APPROVAL_EMAIL`, `WSP8_APPROVAL_NAME`
  2. Configure n8n Credentials for WordPress, OpenAI, SMTP, and social platforms.
  3. Verify no secrets are present in repository and workflow JSON files.
- Progress:
  - [x] Activity 1 verified on 2026-02-20 (env vars documented by scope in project docs)
  - [ ] Activity 2 pending (scheduled next session)
  - [x] Activity 3 verified on 2026-02-20 (repository/workflow JSON secret scan clean)
- Definition of done: scoped env vars are documented/configured and credentials are available in n8n.
- Expected output: security baseline checklist completed.
- Status: in-progress
- Started on: 2026-02-20
- Completed on: YYYY-MM-DD

### Step 2 - MVP Skeleton (Detection + Extraction + AI + Approval + Twitter/X)
- [ ] Step completion
- Objective: deliver first end-to-end publish flow for Twitter/X with approval gate.
- Activities:
  1. Implement Features 1-4 (hourly check, extraction, AI generation, email approval).
  2. Implement Feature 5 with approve/reject branching.
  3. Validate no-op, reject-skip, approve-publish scenarios.
- Definition of done: one approved WordPress post is published on Twitter/X.
- Expected output: stable MVP workflow in n8n and JSON aligned to repository standards.
- Status: todo | in-progress | done | blocked
- Started on: YYYY-MM-DD
- Completed on: YYYY-MM-DD

### Step 3 - Add Telegram Channel
- [ ] Step completion
- Objective: extend approved publication to Telegram.
- Activities:
  1. Implement Feature 6.
  2. Reuse existing approval pattern.
  3. Run approve/reject tests.
- Definition of done: approved posts are published to Telegram.
- Expected output: v1 channel extension validated.
- Status: todo | in-progress | done | blocked
- Started on: YYYY-MM-DD
- Completed on: YYYY-MM-DD

### Step 4 - Add Instagram and Facebook Channels
- [ ] Step completion
- Objective: complete all planned social destinations.
- Activities:
  1. Implement Feature 7 (Instagram).
  2. Implement Feature 8 (Facebook).
  3. Validate platform-specific payload constraints.
- Definition of done: approved posts can be published across all target channels.
- Expected output: v2 multi-channel completion.
- Status: todo | in-progress | done | blocked
- Started on: YYYY-MM-DD
- Completed on: YYYY-MM-DD

## 6) Risks and Dependencies

### Risks
- Risk: platform API limits or policy changes.
  - Impact: failed or delayed publication.
  - Probability: medium.
  - Mitigation: retries, logging, and per-channel fallback handling.
- Risk: approval email delivery issues.
  - Impact: publication blocked.
  - Probability: medium.
  - Mitigation: authenticated SMTP monitoring and alerting.
- Risk: AI output quality or length violations.
  - Impact: rejected or non-compliant social content.
  - Probability: medium.
  - Mitigation: enforce hard 280-char validation and hashtag checks.
- Risk: duplicate publication of same post.
  - Impact: spam/duplicate content.
  - Probability: medium.
  - Mitigation: persisted processed-post marker and idempotency checks.

### External dependencies
- Dependency: WordPress REST API reachability and schema.
  - Type (technical/vendor).
  - Potential blocker: API unavailable or incompatible fields.
  - Backup plan: defensive parsing and monitoring alerts.
- Dependency: OpenAI API availability.
  - Type (technical/vendor).
  - Potential blocker: generation failures/rate limits.
  - Backup plan: fallback deterministic template from post title/excerpt.
- Dependency: SMTP provider reliability.
  - Type (technical/vendor).
  - Potential blocker: email delivery latency/failures.
  - Backup plan: retry queue and operational alert.
- Dependency: social APIs (X, Telegram, Meta).
  - Type (technical/vendor).
  - Potential blocker: auth/policy/rate changes.
  - Backup plan: isolate per-channel failures and continue others.

## 7) Operational Rules for Implementation
Use these rules to keep this file as the single development track.

- Every new development request must reference one Feature and one specific Step.
- Before starting any change, set the Step status to in-progress.
- After implementation and testing, set the Step status to done.
- If new scope appears, add it here before implementing it.
- Do not place secrets in the repository or in workflow JSON files.
- Keep all account credentials only in n8n Credentials, never in source-controlled files.

## 8) Decision Log
Track relevant technical decisions.

- Date: 2026-02-20
- Decision: use n8n Credentials as the only storage for WordPress/social/OpenAI/SMTP secrets.
- Rationale: prevent secret leakage in repository and JSON exports.
- Alternatives considered: env vars for all secrets, secrets in local files.
- Impact: stronger security posture; operational setup required in n8n UI.

- Date: 2026-02-20
- Decision: use authenticated SMTP (not Gmail-only) for approval emails.
- Rationale: provider flexibility and easier integration with existing mail infrastructure.
- Alternatives considered: Gmail SMTP/API only.
- Impact: SMTP credential setup required in n8n.

- Date: 2026-02-20
- Decision: message generation must use AI and include `#n8n`, max 280 chars.
- Rationale: better editorial quality while respecting social constraints.
- Alternatives considered: static template-only generation.
- Impact: OpenAI dependency and validation guardrail in workflow.

## 9) Recommended Prompt Commands
Use these prompts to work consistently with this track.

1. "Implement Feature <id>, Step <id> in `AGENTS/IMPLEMENTATION_TRACK.md`."
2. "Update status and acceptance criteria of Feature <id> after the changes."
3. "Review Step <id> against the defined acceptance criteria."
4. "Propose the next minimum Step to progress toward MVP."
