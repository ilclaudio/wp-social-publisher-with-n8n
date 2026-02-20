# wp-social-publisher-with-n8n
Publish WordPress Posts on social

Configuration must use environment variables with the `WSP8_` project prefix.

- Development environment (local tooling/API scripts): `WSP8_N8N_BASE_URL`, `WSP8_N8N_API_KEY`.
- n8n runtime (workflow execution): `WSP8_WP_SITE_URL`, `WSP8_APPROVAL_EMAIL`, `WSP8_APPROVAL_NAME`.
