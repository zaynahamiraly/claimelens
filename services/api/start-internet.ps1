param(
    [string]$PythonPath = (Join-Path $PSScriptRoot '.venv-paddle\Scripts\python.exe')
)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

if (-not (Test-Path -LiteralPath $PythonPath)) {
    throw 'Install API dependencies first, or pass -PythonPath with the full path to the configured Python executable.'
}
$runtimeHome = Join-Path $env:LOCALAPPDATA 'claimelens'
$toolHome = Join-Path $runtimeHome 'tools'
New-Item -ItemType Directory -Path $toolHome -Force | Out-Null
$connector = Join-Path $toolHome 'cloudflared.exe'
if (-not (Test-Path -LiteralPath $connector)) {
    Invoke-WebRequest -Uri 'https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe' -OutFile $connector
}
$tunnelPidFile = Join-Path $runtimeHome 'tunnel.pid'
$endpointFile = Join-Path $runtimeHome 'internet-endpoint.txt'
$runningTunnel = $null
if (Test-Path -LiteralPath $tunnelPidFile) {
    $savedTunnelPid = [int](Get-Content -LiteralPath $tunnelPidFile -Raw)
    $runningTunnel = Get-CimInstance Win32_Process -Filter "ProcessId = $savedTunnelPid"
    if ($runningTunnel.ExecutablePath -ne $connector) { $runningTunnel = $null }
}
if ($runningTunnel -and (Test-Path -LiteralPath $endpointFile)) {
    $endpoint = (Get-Content -LiteralPath $endpointFile -Raw).Trim()
} else {
    $tunnelLog = Join-Path $runtimeHome 'tunnel.stderr.log'
    $tunnelProcess = Start-Process -FilePath $connector -ArgumentList @('tunnel', '--url', 'http://127.0.0.1:8000', '--no-autoupdate', '--protocol', 'http2') -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $runtimeHome 'tunnel.stdout.log') -RedirectStandardError $tunnelLog
    $tunnelProcess.Id | Set-Content -LiteralPath $tunnelPidFile
    $deadline = (Get-Date).AddSeconds(60)
    $endpoint = ''
    while ((Get-Date) -lt $deadline -and -not $endpoint) {
        Start-Sleep -Seconds 1
        if (Test-Path -LiteralPath $tunnelLog) {
            $endpoint = [regex]::Match((Get-Content -LiteralPath $tunnelLog -Raw), 'https://[a-z0-9-]+\.trycloudflare\.com').Value
        }
    }
    if (-not $endpoint) { throw "The HTTPS connection did not start. Inspect $tunnelLog." }
    $endpoint | Set-Content -LiteralPath $endpointFile
}
if ($endpoint -notmatch '^https://[a-z0-9-]+\.trycloudflare\.com$') { throw 'Unexpected internet endpoint.' }

$listener = Get-NetTCPConnection -LocalPort 8000 -State Listen -ErrorAction SilentlyContinue
if ($listener) {
    $health = Invoke-RestMethod -Uri 'http://127.0.0.1:8000/api/v1/health'
    $existingApi = Get-CimInstance Win32_Process -Filter "ProcessId = $($listener[0].OwningProcess)"
    if ($health.service -notin @('claimelens API', 'ClaimLens API') -or $existingApi.CommandLine -notlike '*app.main:app*') {
        throw 'Port 8000 belongs to another service. Stop it before starting this API.'
    }
    Stop-Process -Id $existingApi.ProcessId
}

# Only the public endpoint is saved here. Existing credentials are retained.
$envFile = Join-Path $PSScriptRoot '.env'
$envText = if (Test-Path -LiteralPath $envFile) { Get-Content -LiteralPath $envFile -Raw } else { '' }
if ($envText -match '(?m)^PUBLIC_API_URL=') {
    $envText = [regex]::Replace($envText, '(?m)^PUBLIC_API_URL=.*$', "PUBLIC_API_URL=$endpoint")
} else { $envText += "`nPUBLIC_API_URL=$endpoint`n" }
[IO.File]::WriteAllText($envFile, $envText, [Text.UTF8Encoding]::new($false))
$env:PUBLIC_API_URL = $endpoint
$env:PADDLE_PDX_DISABLE_MODEL_SOURCE_CHECK = 'True'
$api = Start-Process -FilePath $PythonPath -ArgumentList @('-m', 'uvicorn', 'app.main:app', '--host', '127.0.0.1', '--port', '8000') -WorkingDirectory $PSScriptRoot -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $runtimeHome 'api.stdout.log') -RedirectStandardError (Join-Path $runtimeHome 'api.stderr.log')
$api.Id | Set-Content -LiteralPath (Join-Path $runtimeHome 'api.pid')
$ready = $false
$deadline = (Get-Date).AddSeconds(45)
while ((Get-Date) -lt $deadline -and -not $ready) {
    Start-Sleep -Seconds 1
    try { $ready = (Invoke-RestMethod -Uri ($endpoint + '/api/v1/health') -TimeoutSec 5).service -eq 'ClaimLens API' } catch { }
}
if (-not $ready) { throw 'The API did not become reachable. Check the logs in the private runtime folder.' }
@{ API_BASE_URL = "$endpoint/api/v1" } | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $runtimeHome 'internet-build.json')
Write-Output "Internet API: $endpoint"
Write-Output "Flutter build configuration: $(Join-Path $runtimeHome 'internet-build.json')"
Write-Output 'Keep this computer and its internet connection on. This temporary address changes when a new tunnel is created.'
