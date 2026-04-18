param(
    [string]$WorkflowFile = "$PSScriptRoot\..\workflows\active\wp-social-publisher-approval-flow.json"
)

$base = [System.Environment]::GetEnvironmentVariable('WSPAF_N8N_BASE_URL', 'Machine')
$key  = [System.Environment]::GetEnvironmentVariable('WSPAF_N8N_API_KEY',  'Machine')

if (-not $base) { Write-Error "WSPAF_N8N_BASE_URL not set"; exit 1 }
if (-not $key)  { Write-Error "WSPAF_N8N_API_KEY not set";  exit 1 }

$headers = @{ 'X-N8N-API-KEY' = $key; 'Content-Type' = 'application/json' }

# --- 1. Resolve credential IDs ---
Write-Host "[1] Resolving credential IDs..."
$credsResp = Invoke-RestMethod -Uri "$base/api/v1/credentials" -Headers $headers -Method Get
$openAiCred = $credsResp.data | Where-Object { $_.name -eq 'OpenAI account' } | Select-Object -First 1
if (-not $openAiCred) { Write-Error "Credential 'OpenAI account' not found on server"; exit 1 }
Write-Host "  Found: id=$($openAiCred.id) name=$($openAiCred.name)"
$smtpCred = $credsResp.data | Where-Object { $_.name -eq 'SMTP Account' } | Select-Object -First 1
if (-not $smtpCred) { Write-Error "Credential 'SMTP Account' not found on server"; exit 1 }
Write-Host "  Found: id=$($smtpCred.id) name=$($smtpCred.name)"
$twitterCred = $credsResp.data | Where-Object { $_.name -eq 'X OAuth account' } | Select-Object -First 1
if (-not $twitterCred) { Write-Error "Credential 'X OAuth account' not found on server"; exit 1 }
Write-Host "  Found: id=$($twitterCred.id) name=$($twitterCred.name)"
$twitterOAuth2Cred = $credsResp.data | Where-Object { $_.name -eq 'X OAuth2 account' } | Select-Object -First 1
if (-not $twitterOAuth2Cred) { Write-Error "Credential 'X OAuth2 account' not found on server"; exit 1 }
Write-Host "  Found: id=$($twitterOAuth2Cred.id) name=$($twitterOAuth2Cred.name)"

# --- 2. Find remote workflow by name ---
Write-Host "[2] Finding remote workflow..."
$wfResp = Invoke-RestMethod -Uri "$base/api/v1/workflows" -Headers $headers -Method Get
$remoteWf = $wfResp.data | Where-Object { $_.name -eq 'WP Social Publisher Approval Flow' } | Select-Object -First 1
if (-not $remoteWf) { Write-Error "Workflow 'WP Social Publisher Approval Flow' not found on server"; exit 1 }
Write-Host "  Found: id=$($remoteWf.id) name=$($remoteWf.name) active=$($remoteWf.active)"

# --- 3. Load local workflow and inject credential ID ---
Write-Host "[3] Loading local workflow file..."
$localJson = Get-Content -Path $WorkflowFile -Raw -Encoding UTF8
$payload = $localJson | ConvertFrom-Json

# Inject credential IDs
$openAiNode = $payload.nodes | Where-Object { $_.id -eq 'generate-ai-message' }
if (-not $openAiNode) { Write-Error "Node 'generate-ai-message' not found in local JSON"; exit 1 }
$openAiNode.credentials.openAiApi.id = $openAiCred.id
Write-Host "  OpenAI credential ID injected: $($openAiCred.id)"

$smtpNode = $payload.nodes | Where-Object { $_.id -eq 'approval-gate-email' }
if (-not $smtpNode) { Write-Error "Node 'approval-gate-email' not found in local JSON"; exit 1 }
$smtpNode.credentials.smtp.id = $smtpCred.id
Write-Host "  SMTP credential ID injected (approval gate): $($smtpCred.id)"

foreach ($notifyId in @('notify-published-with-image', 'notify-published-no-image', 'notify-not-approved')) {
    $notifyNode = $payload.nodes | Where-Object { $_.id -eq $notifyId }
    if ($notifyNode) { $notifyNode.credentials.smtp.id = $smtpCred.id; Write-Host "  SMTP credential ID injected ($notifyId): $($smtpCred.id)" }
}

$uploadNode = $payload.nodes | Where-Object { $_.id -eq 'upload-media-twitter' }
if ($uploadNode) { $uploadNode.credentials.twitterOAuth1Api.id = $twitterCred.id; Write-Host "  Twitter OAuth1 credential ID injected (upload): $($twitterCred.id)" }

$tweetWithImageNode = $payload.nodes | Where-Object { $_.id -eq 'post-tweet-with-image' }
if ($tweetWithImageNode) { $tweetWithImageNode.credentials.twitterOAuth2Api.id = $twitterOAuth2Cred.id; Write-Host "  Twitter OAuth2 credential ID injected (tweet with image): $($twitterOAuth2Cred.id)" }

$tweetNode = $payload.nodes | Where-Object { $_.id -eq 'post-tweet' }
if ($tweetNode) { $tweetNode.credentials.twitterOAuth2Api.id = $twitterOAuth2Cred.id; Write-Host "  Twitter OAuth2 credential ID injected (tweet): $($twitterOAuth2Cred.id)" }

# Remove read-only fields
$payload.PSObject.Properties.Remove('id')
$payload.PSObject.Properties.Remove('tags')

# --- 4. PUT workflow to server ---
Write-Host "[4] Deploying workflow (PUT /api/v1/workflows/$($remoteWf.id))..."
$body = $payload | ConvertTo-Json -Depth 20 -Compress
$putResp = Invoke-RestMethod -Uri "$base/api/v1/workflows/$($remoteWf.id)" -Headers $headers -Method Put -Body $body
Write-Host "  Deploy response: id=$($putResp.id) name=$($putResp.name)"

# --- 5. Verify ---
Write-Host "[5] Verifying remote workflow..."
$verifyResp = Invoke-RestMethod -Uri "$base/api/v1/workflows/$($remoteWf.id)" -Headers $headers -Method Get
$aiNode = $verifyResp.nodes | Where-Object { $_.id -eq 'generate-ai-message' }
$validateNode = $verifyResp.nodes | Where-Object { $_.id -eq 'validate-ai-message' }
$debugNode    = $verifyResp.nodes | Where-Object { $_.id -eq 'debug-ai-message' }
Write-Host "  generate-ai-message node present: $($null -ne $aiNode)"
Write-Host "  validate-ai-message node present: $($null -ne $validateNode)"
Write-Host "  debug-ai-message node present:    $($null -ne $debugNode)"
Write-Host ""
Write-Host "Deploy completed. Workflow ID: $($putResp.id)"
