$base = [System.Environment]::GetEnvironmentVariable('WSPAF_N8N_BASE_URL', 'Machine')
$key  = [System.Environment]::GetEnvironmentVariable('WSPAF_N8N_API_KEY',  'Machine')
$headers = @{ 'X-N8N-API-KEY' = $key }

# n8n version
$ver = Invoke-RestMethod -Uri "$base/api/v1/workflows" -Headers $headers -Method Get
Write-Host "API reachable. Checking workflow nodes..."

# Get remote workflow and inspect the OpenAI node
$wf = Invoke-RestMethod -Uri "$base/api/v1/workflows/8dmMHygvn3MozUxu" -Headers $headers -Method Get
$aiNode = $wf.nodes | Where-Object { $_.id -eq 'generate-ai-message' }
Write-Host "--- generate-ai-message node on server ---"
$aiNode | ConvertTo-Json -Depth 5

# Also check n8n version via healthz or version endpoint
try {
    $versionResp = Invoke-RestMethod -Uri "$base/healthz" -Method Get
    Write-Host "healthz: $($versionResp | ConvertTo-Json)"
} catch {
    Write-Host "healthz not available"
}

try {
    $versionResp2 = Invoke-RestMethod -Uri "$base/api/v1/debug/global-config" -Headers $headers -Method Get
    Write-Host "global-config: $($versionResp2 | ConvertTo-Json -Depth 3)"
} catch {
    Write-Host "global-config not available"
}
