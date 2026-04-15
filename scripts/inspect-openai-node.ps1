$base = [System.Environment]::GetEnvironmentVariable('WSPAF_N8N_BASE_URL', 'Machine')
$key  = [System.Environment]::GetEnvironmentVariable('WSPAF_N8N_API_KEY',  'Machine')
$headers = @{ 'X-N8N-API-KEY' = $key }

$wfList = Invoke-RestMethod -Uri "$base/api/v1/workflows?limit=100" -Headers $headers -Method Get

foreach ($wf in $wfList.data) {
    $detail = Invoke-RestMethod -Uri "$base/api/v1/workflows/$($wf.id)" -Headers $headers -Method Get
    $openAiNode = $detail.nodes | Where-Object { $_.type -eq '@n8n/n8n-nodes-langchain.openAi' } | Select-Object -First 1
    if ($openAiNode) {
        Write-Host "Found in workflow: $($wf.name) (id=$($wf.id))"
        $openAiNode | ConvertTo-Json -Depth 10
        break
    }
}
