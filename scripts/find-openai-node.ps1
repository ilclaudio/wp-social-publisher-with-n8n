$base = [System.Environment]::GetEnvironmentVariable('WSPAF_N8N_BASE_URL', 'Machine')
$key  = [System.Environment]::GetEnvironmentVariable('WSPAF_N8N_API_KEY',  'Machine')
$headers = @{ 'X-N8N-API-KEY' = $key }

# Get all workflows and scan nodes for OpenAI-related types
$wfList = Invoke-RestMethod -Uri "$base/api/v1/workflows?limit=100" -Headers $headers -Method Get
Write-Host "Total workflows on server: $($wfList.data.Count)"

$allNodeTypes = @{}
foreach ($wf in $wfList.data) {
    $detail = Invoke-RestMethod -Uri "$base/api/v1/workflows/$($wf.id)" -Headers $headers -Method Get
    foreach ($node in $detail.nodes) {
        $allNodeTypes[$node.type] = $true
    }
}

Write-Host ""
Write-Host "All node types found across all workflows:"
$allNodeTypes.Keys | Sort-Object | ForEach-Object { Write-Host "  $_" }

Write-Host ""
Write-Host "OpenAI / AI related:"
$allNodeTypes.Keys | Where-Object { $_ -match 'openai|openAi|langchain|llm|ai|gpt' } | ForEach-Object { Write-Host "  $_" }
