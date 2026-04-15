$base = [System.Environment]::GetEnvironmentVariable('WSPAF_N8N_BASE_URL', 'Machine')
$key  = [System.Environment]::GetEnvironmentVariable('WSPAF_N8N_API_KEY',  'Machine')
$headers = @{ 'X-N8N-API-KEY' = $key }

$endpoints = @(
    "/types/nodes.json",
    "/rest/node-types",
    "/rest/node-types?includeExcluded=true"
)

foreach ($ep in $endpoints) {
    Write-Host "--- Trying $ep ---"
    try {
        $resp = Invoke-RestMethod -Uri ($base + $ep) -Headers $headers -Method Get
        $nodes = if ($resp.data) { $resp.data } elseif ($resp -is [Array]) { $resp } else { $null }
        if ($nodes) {
            Write-Host "SUCCESS. Total nodes: $($nodes.Count)"
            $nodes | Where-Object { $_.name -match 'openai|openAi|langchain|llm|gpt|telegram|twitter|smtp|email' } |
                ForEach-Object { Write-Host "  $($_.name) :: $($_.displayName)" }
        } else {
            Write-Host "Response type: $($resp.GetType().Name)"
            Write-Host ($resp | ConvertTo-Json -Depth 2 | Select-Object -First 5)
        }
    } catch {
        Write-Host "Error: $_"
    }
    Write-Host ""
}
