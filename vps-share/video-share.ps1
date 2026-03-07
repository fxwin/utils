param(
    [Parameter(Mandatory=$true)]
    [string]$Path
)

$HostAlias = "fxwin-vps" # ssh profile for vps
$RemoteDir = "/srv/videos/public" # path inside the vps that is served (e.g. by nginx)
$BaseUrl   = "https://videos.fxwin.net/raw" # base url the remote directory is served at

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Show-BalloonTip {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [string]$Title = "Share via VPS",

        [int]$Duration = 8000,

        [string]$Url,

        [switch]$Error
    )

    $notify = New-Object System.Windows.Forms.NotifyIcon
    $notify.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon(
        "$env:WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe"
    )
    $notify.BalloonTipTitle = $Title
    $notify.BalloonTipText  = $Message
    $notify.BalloonTipIcon  = if ($Error) {
        [System.Windows.Forms.ToolTipIcon]::Error
    } else {
        [System.Windows.Forms.ToolTipIcon]::None
    }
    $notify.Visible = $true

    if ($Url) {
        $handler = [System.EventHandler]{ Start-Process $Url }
        $notify.Add_BalloonTipClicked($handler)
        $notify.Add_Click($handler)
    }

    $notify.ShowBalloonTip($Duration)
    Start-Sleep -Milliseconds ($Duration + 2000)
    $notify.Dispose()
}

if (!(Test-Path $Path)) {
    Show-BalloonTip -Message "File not found." -Error -Duration 6000
    exit 1
}

$ext = [IO.Path]::GetExtension($Path)
$id  = [Convert]::ToBase64String([Guid]::NewGuid().ToByteArray()) -replace '[+/=]', ''
$newName = "$id$ext"

$remotePath = "${HostAlias}:${RemoteDir}/${newName}"

Write-Host "Uploading $([IO.Path]::GetFileName($Path)) ..."
& scp "$Path" "$remotePath" | Out-Null

if ($LASTEXITCODE -ne 0) {
    Show-BalloonTip -Message "Upload failed." -Error
    exit $LASTEXITCODE
}

$link = "$BaseUrl/$newName"
Set-Clipboard $link
Write-Output $link

Show-BalloonTip -Message "Uploaded. Link copied to clipboard.`nClick to open." -Url $link -Duration 5000