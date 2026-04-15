$base = [System.Environment]::GetEnvironmentVariable('WSPAF_N8N_BASE_URL', 'Machine')
$key  = [System.Environment]::GetEnvironmentVariable('WSPAF_N8N_API_KEY',  'Machine')
$headers = @{ 'X-N8N-API-KEY' = $key }

# Try to get node types
try {
    $resp = Invoke-RestMethod -Uri "$base/api/v1/node-types" -Headers $headers -Method Get
    $openAiNodes = $resp.data | Where-Object { $_.name -match 'openai|openAi|langchain' }
    if ($openAiNodes) {
        Write-Host "OpenAI-related nodes found:"
        $openAiNodes | ForEach-Object { Write-Host "  name=$($_.name) version=$($_.version)" }
    } else {
        Write-Host "No OpenAI-related nodes found in node-types list"
        Write-Host "Total nodes available: $($resp.data.Count)"
    }
} catch {
    Write-Host "node-types endpoint error: $_"
}

# Check n8n version from any available endpoint
try {
    $resp2 = Invoke-RestMethod -Uri "$base/rest/settings" -Method Get
    Write-Host "n8n version: $($resp2.data.versionCli)"
} catch {
    Write-Host "rest/settings not available"
}
