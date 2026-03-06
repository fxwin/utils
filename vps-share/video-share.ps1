param(
    [Parameter(Mandatory=$true)]
    [string]$Path
)

$HostAlias = "fxwin-vps" # ssh profile for vps
$RemoteDir = "/srv/videos/public" # path inside the vps that is served (e.g. by nginx)
$BaseUrl   = "https://videos.fxwin.net/raw" # base url the remote directory is served at

function Invoke-BalloonTip {
  Param(
    [Parameter(Mandatory=$True)][string]$Message,
    [string]$Title="Share via VPS",
    [string]$MessageType="None",
    [string]$SysTrayIconPath="$env:WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe",
    [int]$Duration=8000
  )

  Add-Type -AssemblyName System.Windows.Forms
  Add-Type -AssemblyName System.Drawing

  $balloon = New-Object System.Windows.Forms.NotifyIcon
  $balloon.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($SysTrayIconPath)

  $icon = [System.Windows.Forms.ToolTipIcon]::None
  switch ($MessageType.ToLower()) {
    "info"    { $icon = [System.Windows.Forms.ToolTipIcon]::Info }
    "warning" { $icon = [System.Windows.Forms.ToolTipIcon]::Warning }
    "error"   { $icon = [System.Windows.Forms.ToolTipIcon]::Error }
  }
  $balloon.BalloonTipIcon  = $icon
  $balloon.BalloonTipText  = $Message
  $balloon.BalloonTipTitle = $Title
  $balloon.Visible = $true

  if ($script:BalloonUrl) {
    $handler = [System.EventHandler]{ Start-Process $script:BalloonUrl }
    $balloon.Add_BalloonTipClicked($handler)
    $balloon.Add_Click($handler)
  }

  $balloon.ShowBalloonTip($Duration)
  Start-Sleep -Milliseconds ($Duration + 2000)
  $balloon.Dispose()
}

if (!(Test-Path $Path)) {
    Invoke-BalloonTip -Message "File not found." -MessageType Error -Duration 6000
    exit 1
}

$ext = [IO.Path]::GetExtension($Path)
$id  = [Convert]::ToBase64String([Guid]::NewGuid().ToByteArray()) -replace '[+/=]',''
$newName = "$id$ext"

$remotePath = "${HostAlias}:${RemoteDir}/${newName}"

Write-Host "Uploading $([IO.Path]::GetFileName($Path)) ..."
& scp "$Path" "$remotePath" | Out-Null
if ($LASTEXITCODE -ne 0) {
    Invoke-BalloonTip -Message "Upload failed." -MessageType Error -Duration 8000
    exit $LASTEXITCODE
}

$link = "$BaseUrl/$newName"
Set-Clipboard $link
Write-Output $link
# make link clickable from balloon
$script:BalloonUrl = $link
Invoke-BalloonTip -Message "Uploaded. Link copied to clipboard.`nClick to open." -MessageType None -Duration 5000

