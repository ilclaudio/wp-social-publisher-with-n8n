# WP Social Publisher Approval Flow
Publish WordPress posts on social channels with approval gating.

Configuration must use environment variables with the `WSPAF_` project prefix.

- Development environment (local tooling/API scripts): `WSPAF_N8N_BASE_URL`, `WSPAF_N8N_API_KEY`.
- n8n runtime environment variables (workflow execution): `WSPAF_WP_SITE_URL`, `WSPAF_APPROVAL_EMAIL`, `WSPAF_APPROVAL_NAME`.
- n8n Credentials: OpenAI, SMTP, and social platform secrets/tokens.
- Workflow code should target the n8n Code node JavaScript runtime (server-side Node.js) unless the server is explicitly configured with a working Python runner.

## Current workflow nodes

### Implemented nodes

- `Manual Trigger`: starts the workflow manually for tests and ad hoc runs.
- `Schedule Trigger (Hourly)`: starts the workflow automatically every hour.
- `Start (Manual or Hourly)`: merges the two start paths into a single execution path.
- `Fetch WP Posts`: reads recent published posts from the WordPress REST API using `$env.WSPAF_WP_SITE_URL`.
- `Debug - Count fetched posts`: logs how many posts were fetched and prints a short preview of the first items.
- `Detect New Posts (date_gmt)`: keeps only posts whose `date_gmt` falls within the recent detection window and adds `detectedAtUtc`.
- `Initial Block Notes`: sticky note that documents the purpose of the opening block and the required runtime variables.
- `Deduplicate via Data Store`: uses the `Remove Duplicates` node to skip posts whose WordPress `id` was already processed in previous executions.
- `Debug - Deduplicate summary`: logs how many recent posts were detected, how many remain after deduplication, and which post IDs were skipped as duplicates.
- `Extract URL and Featured Image`: normalizes title, excerpt, post URL, and featured image data from the WordPress response.

### Placeholder nodes not implemented yet

- `Generate AI Message (max 280, #n8n)`: not implemented yet; it should generate the final social copy.
- `Approval Gate (Email)`: not implemented yet; it should handle the approval request and decision flow.
- `Publish to Twitter/X`: not implemented yet; it should publish only approved content to Twitter/X.

## Remote deploy procedure

When the workflow is updated on the n8n server, the deploy process updates the existing remote workflow in place instead of deleting and recreating it.

Steps:

- Read the remote workflow list from the n8n API.
- Identify the target workflow by its canonical workflow name.
- Read the local source file from `workflows/active/`.
- Send a `PUT` request to the remote workflow endpoint using the remote workflow identifier returned by the API.
- Exclude read-only fields from the request body.
- Run a final verification request to confirm that the remote workflow reflects the expected changes.
