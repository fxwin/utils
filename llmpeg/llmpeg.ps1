param(
    [Parameter(Mandatory=$true)][string]$Instruction,
    [Parameter(Mandatory=$true)][string]$Path,
    [switch]$DryRun,
    [switch]$Smart
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# ---------------- CONFIG ----------------

$Model = "gpt-4.1"
if ($Smart) { $Model = "gpt-5-mini" }

$ApiUrl = "https://api.openai.com/v1/responses"
$ApiKey = $env:OPENAI_API_KEY
if ([string]::IsNullOrWhiteSpace($ApiKey)) {
    throw "OPENAI_API_KEY is not set."
}

# ---------------- INPUT VALIDATION ----------------

if (!(Test-Path -LiteralPath $Path)) {
    throw "Input not found: $Path"
}

$ext = [IO.Path]::GetExtension($Path)
$defaultOut = "llmpeg_out$ext"

# ---------------- PROMPT ----------------

$system = @"
You write safe, correct ffmpeg commands.

Return ONLY JSON with this schema:
{
  "args": ["ffmpeg", "..."],
  "output": "filename.mp4"
}

Rules:
- Single ffmpeg invocation only.
- Include "-y".
- Do not reduce quality unless explicitly asked.
- Prefer stream copy when possible.
- If re-encoding is required, use H.264 video + AAC audio.
- Use the input path provided verbatim.
- Do not expand to absolute paths.
- Output must be a NEW file.
- Write output in the same directory unless instructed otherwise.
"@

$user = @"
Task: $Instruction

Input file path: $Path
Preferred output name: $defaultOut

Return JSON only.
"@

$body = @{
    model = $Model
    input = @(
        @{ role="system"; content=$system },
        @{ role="user"; content=$user }
    )
    text = @{
        format = @{ type = "json_object" }
    }
} | ConvertTo-Json -Depth 10

$headers = @{
    Authorization = "Bearer $ApiKey"
    "Content-Type" = "application/json"
}

# ---------------- CALL OPENAI ----------------

$resp = Invoke-RestMethod -Method Post -Uri $ApiUrl -Headers $headers -Body $body

$jsonText = $resp.output_text
if ([string]::IsNullOrWhiteSpace($jsonText)) {
    $jsonText = ($resp.output | ForEach-Object {
        $_.content | ForEach-Object { $_.text }
    }) -join ""
}

try {
    $plan = $jsonText | ConvertFrom-Json
}
catch {
    throw "Model did not return valid JSON. Raw:`n$jsonText"
}

# ---------------- VALIDATE PLAN ----------------

if (-not $plan.args) { throw "Invalid plan: missing args[]" }

$args = @($plan.args)
if ($args.Count -lt 2) { throw "Invalid plan: args too short" }

if ([IO.Path]::GetFileName($args[0]).ToLower() -ne "ffmpeg") {
    throw "Refusing to run: argv[0] is not ffmpeg"
}

$inputName = [IO.Path]::GetFileName($Path)
$inputFound = $false

foreach ($a in $args) {
    if ($a -eq $Path -or $a -eq $inputName) {
        $inputFound = $true
        break
    }
}

if (-not $inputFound) {
    throw "Refusing to run: input path not present in args"
}

if ([string]::IsNullOrWhiteSpace($plan.output)) {
    throw "Invalid plan: missing output"
}

$outPath = $plan.output

if ($outPath -eq $Path) {
    throw "Refusing: output equals input"
}

# ---- EXECUTE (correct quoting, pipeline-safe) ----

$exe = $args[0]
$exeArgs = if ($args.Count -gt 1) { $args[1..($args.Count-1)] } else { @() }

# Print command
$prettyCmd = ($args | ForEach-Object {
    if ($_ -match '\s') { '"' + $_ + '"' } else { $_ }
}) -join " "

Write-Host ""
Write-Host "Executing:"
Write-Host $prettyCmd
Write-Host ""

if ($DryRun) {
    Write-Output $outPath
    return
}

# Execute with correct argument handling
& $exe @exeArgs

$exit = $LASTEXITCODE
if ($exit -ne 0) {
    throw "ffmpeg failed with exit code $exit"
}

Write-Output $outPath
return