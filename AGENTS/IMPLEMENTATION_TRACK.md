# Implementation Track — WP Social Publisher Approval Flow

## 1) Project Objective
Build an n8n automation that publishes notifications for new posts from a WordPress site to X (Twitter) with explicit approval gating by email before publishing. The workflow must check for new posts once per day at 06:00 (and on manual test trigger), identify new posts by publication date (`date_gmt`) with deduplication in n8n Data Store, process each new post, generate a social message with AI (max 280 characters), include hashtag `#n8n`, and publish only after approval.

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
  - Social platform nodes/APIs (Twitter/X)
- Infrastructure constraints:
  - Project env vars must use the `WSPAF_` prefix.
  - Development environment vars: `WSPAF_N8N_BASE_URL`, `WSPAF_N8N_API_KEY`.
  - n8n runtime environment vars: `WSPAF_WP_SITE_URL`, `WSPAF_APPROVAL_EMAIL`, `WSPAF_APPROVAL_NAME`, `WSPAF_SENDER_EMAIL`.
  - WordPress base URL must come from environment variable `WSPAF_WP_SITE_URL`.
- Approval recipient email must come from environment variable `WSPAF_APPROVAL_EMAIL`.
- Approval recipient display name must come from environment variable `WSPAF_APPROVAL_NAME`.
- Approval sender email must come from environment variable `WSPAF_SENDER_EMAIL`.
  - Polling schedule: once per day at 06:00.
  - Trigger strategy: dual trigger in n8n (`Schedule Trigger` + `Manual Trigger` for tests).
- Security/compliance constraints:
  - No username/password/token/API key in repository, Markdown, workflow JSON, or source files.
  - All secrets and account credentials must be stored only in n8n Credentials.
  - `N8N_ENCRYPTION_KEY` must be configured on n8n server.
  - Workflow JSON may reference credentials by name/id only.
- Operational constraints:
  - If no new posts are found, the workflow exits without side effects.
  - If approval is rejected, action is `skip` (no publish).
  - New post detection must use WordPress publication date (`date_gmt`).
  - Processed posts must be deduplicated with persistent n8n Data Store state keyed by WordPress post ID.
  - Current release scope: Twitter/X only. Future channels can be tracked outside the active scope.

## 3) Features (Text Backlog)
### Feature 1 - Daily + Manual WordPress New Post Detection
- Description: on daily schedule at 06:00 and manual test trigger, query WordPress using environment variable `WSPAF_WP_SITE_URL` and detect newly published posts using `date_gmt`, then filter already-processed items via n8n Data Store.
- User value: automatic discovery of new content with no manual checks.
- Expected inputs: environment variable `WSPAF_WP_SITE_URL`, last processed publication marker, n8n Data Store processed-IDs set.
- Expected outputs: list of new posts to process or empty list.
- Dependencies: WordPress API availability; n8n scheduler; n8n manual trigger; n8n Data Store.
- Priority: MVP
- Status: done
- Acceptance criteria:
  1. Scheduler runs once per day at 06:00 and manual trigger can run on-demand for tests.
  2. Detection uses WordPress `date_gmt` as the primary new-post criterion.
  3. If no new posts, workflow stops cleanly.
  4. If new posts exist, each post enters processing loop only once (Data Store dedup).
- Minimum manual test:
  1. Publish a new post and wait one scheduled run.
  2. Verify post is detected once and stored as processed in Data Store.
  3. Run manual trigger without new posts and confirm no-op.
  4. Re-run schedule/manual and confirm no duplicate processing of same post ID.

### Feature 2 - Post Data Extraction (content, featured image, URL)
- Description: for each detected post, extract topic/content summary, featured image URL, and post URL.
- User value: complete payload for social publishing.
- Expected inputs: post ID/object from Feature 1.
- Expected outputs: normalized object `{title/topic, excerpt/content, imageUrl, postUrl}`.
- Dependencies: WordPress REST fields/media endpoints.
- Priority: MVP
- Status: done
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
- Status: done
- Acceptance criteria:
  1. Message length is <= 280 characters.
  2. Message includes `#n8n`.
  3. Message includes or accompanies post URL and is coherent with post topic.
- Minimum manual test:
  1. Generate message for a sample post.
  2. Validate char count and hashtag.
  3. Validate topic relevance.

### Feature 4 - Approval Email Workflow for X
- Description: send approval request emails for Twitter/X to one recipient from environment variables.
- User value: editorial control before publishing.
- Expected inputs: generated message + post media/link + `WSPAF_APPROVAL_EMAIL` + `WSPAF_APPROVAL_NAME` + `WSPAF_SENDER_EMAIL`.
- Expected outputs: approval decision per channel (approve/reject).
- Dependencies: authenticated SMTP credential in n8n.
- Priority: MVP
- Status: done
- Acceptance criteria:
  1. One approval request is sent for the X publication path.
  2. Recipient is read from environment variables.
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
- Status: done
- Acceptance criteria:
  1. Approve => publishes once.
  2. Reject => skip with no publication.
  3. Publication contains URL and message with `#n8n`.
- Minimum manual test:
  1. Approve case.
  2. Reject case.
  3. Validate published payload.

## 4) Priorities and Releases
Group features by milestone.

### MVP
- [ ] Feature 1 - Daily + Manual WordPress New Post Detection
- [ ] Feature 2 - Post Data Extraction
- [ ] Feature 3 - AI Message Generation
- [ ] Feature 4 - Approval Email Workflow
- [x] Feature 5 - Conditional Publishing to Twitter/X

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
- [x] Step completion
- Objective: define env vars and secure credentials management in n8n before building business logic.
- Activities:
  1. Define and document env vars by scope:
     - development: `WSPAF_N8N_BASE_URL`, `WSPAF_N8N_API_KEY`
     - n8n runtime environment: `WSPAF_WP_SITE_URL`, `WSPAF_APPROVAL_EMAIL`, `WSPAF_APPROVAL_NAME`, `WSPAF_SENDER_EMAIL`
  2. Configure n8n Credentials for WordPress, OpenAI, SMTP, and social platforms.
  3. Verify no secrets are present in repository and workflow JSON files.
- Progress:
  - [x] Activity 1 verified on 2026-02-20 (env vars documented by scope in project docs)
  - [x] Activity 2 verified on 2026-02-23 (credentials creation strategy confirmed: create n8n credentials incrementally as each node/channel is implemented)
  - [x] Activity 3 verified on 2026-02-20 (repository/workflow JSON secret scan clean)
- Definition of done: scoped env vars are documented/configured and credentials are available in n8n.
- Expected output: security baseline checklist completed.
- Status: done
- Started on: 2026-02-20
- Completed on: 2026-02-23

### Step 2 - MVP Skeleton (Detection + Extraction + AI + Approval + Twitter/X)
- [x] Step completion
- Objective: deliver first end-to-end publish flow for Twitter/X with approval gate.
- Activities:
  1. Implement Features 1-4 (dual trigger check, `date_gmt` detection, Data Store dedup, extraction, AI generation, email approval).
  2. Implement Feature 5 with approve/reject branching.
  3. Validate no-op, reject-skip, approve-publish scenarios.
- Progress:
  - [x] Task 1 completed on 2026-02-23 (created MVP draft workflow skeleton in `workflows/draft/wp-social-publisher-approval-flow-mvp.json`)
  - [x] Task 2 completed on 2026-02-23 and later aligned to current scope on 2026-04-19 (configured dual trigger: `Manual Trigger` + daily `Schedule Trigger` at 06:00)
  - [x] Task 3 completed on 2026-02-23 (implemented `Detect New Posts (date_gmt)` with WordPress REST fetch + UTC `date_gmt` filter window in workflow JSON and deployed to n8n)
  - [x] Task 4 completed on 2026-04-13 (aligned workflow runtime configuration to environment variables and prepared server-side `WSPAF_*` usage)
  - [x] Task 5 completed on 2026-04-13 (implemented `Extract URL and Featured Image` using WordPress `_embedded` featured media data and normalized payload fields)
  - [x] Task 6 completed on 2026-04-15 (implemented `Generate AI Message (max 280, #n8n)` using OpenAI node with `gpt-4o-mini` and `OpenAI account` credential; added `Validate AI Message` Code node to enforce 280-char limit and `#n8n` presence; credential `id` left empty in source JSON — resolved at deploy time via `GET /api/v1/credentials`)
  - [x] Task 7 completed on 2026-04-15 (added `Debug - AI message` Code node after `Validate AI Message`; logs `socialMessage` text, length, and validity per item; output visible in node Logs tab in n8n execution detail view)
  - [x] Task 8 completed on 2026-04-18 (implemented `Approval Gate (Email)` using `n8n-nodes-base.emailSend` v2.1 with `sendAndWait` operation; sends HTML approval email from `$env.WSPAF_SENDER_EMAIL` to `$env.WSPAF_APPROVAL_EMAIL` with post title, URL, image link, and social message preview; approval type `double` with labels "Pubblica"/"Non pubblicare"; timeout 24h with automatic reject; credential `SMTP account` with empty `id`; `Approved?` If node v2.3 branches directly on `$json.data.approved`, matching the real response payload returned by the waiting webhook on this server; added `Skip - Not Approved` NoOp for rejected/timeout path)
  - [x] Task 9 completed on 2026-04-19 (implemented Feature 5: added `Has Image? (Twitter)` If node, `Fetch Image Binary` HTTP Request, `Upload Media to Twitter` HTTP Request to `upload.twitter.com/1.1/media/upload.json` with OAuth1, `Post Tweet with Image` and `Post Tweet` HTTP Request nodes to `https://api.twitter.com/2/tweets` with JSON body; all Twitter nodes use `twitterOAuth1Api` / `X OAuth account`; native Twitter node avoided because its UI picker requires `twitterOAuth2Api`; v1.1 `statuses/update` deprecated — using v2 for tweet creation; routing fix: `Has Image?` reads `hasFeaturedImage` from `$('Validate AI Message').item.json` because `sendAndWait` replaces `$json` with approval data)
- Definition of done: one approved WordPress post is published on Twitter/X.
- Expected output: stable MVP workflow in n8n and JSON aligned to repository standards.
- Status: done
- Started on: 2026-02-23
- Completed on: 2026-04-19

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
  - Mitigation: n8n Data Store persisted post-ID dedup and idempotency checks on every trigger path.

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
- Dependency: social APIs (X).
  - Type (technical/vendor).
  - Potential blocker: auth/policy/rate changes.
  - Backup plan: isolate X publication failures and notify by email.

## 7) Operational Rules for Implementation
Use these rules to keep this file as the single development track.

- Every new development request must reference one Feature and one specific Step.
- Feature status should be updated whenever a step materially changes delivery state.
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
