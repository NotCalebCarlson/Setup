<#
.SYNOPSIS
    Fresh-Windows setup: updates, drivers, extra drive formatting, spec summary.

.USAGE
    Right-click > Run with PowerShell, or from an admin prompt:
        powershell -ExecutionPolicy Bypass -File .\Setup-NewPC.ps1

    Safety behavior:
      - A System Restore point is created before driver updates.
      - Blank/unpartitioned extra drives are formatted automatically.
      - Extra drives that already contain partitions are NEVER wiped
        automatically. You must type "ERASE DISK <number>" to confirm.
      - Drives already labeled "Storage" are always left alone.

    Add -NoPrompt for unattended runs. In that mode, drives that already
    contain data are skipped (never wiped) and the restore-point failure
    prompt is skipped.
#>

param([switch]$NoPrompt)

# ---------------------------------------------------------------------------
# Self-elevate if not admin
# ---------------------------------------------------------------------------
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Restarting as Administrator..." -ForegroundColor Yellow
    $args2 = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    if ($NoPrompt) { $args2 += " -NoPrompt" }
    Start-Process powershell.exe -Verb RunAs -ArgumentList $args2
    exit
}

$ErrorActionPreference = 'Continue'
$script:RebootNeeded = $false

function Write-Step($text) {
    Write-Host ""
    Write-Host ("=" * 60) -ForegroundColor Cyan
    Write-Host $text -ForegroundColor Cyan
    Write-Host ("=" * 60) -ForegroundColor Cyan
}

# ---------------------------------------------------------------------------
# Windows Update helper (uses built-in COM API, no extra modules needed)
# ---------------------------------------------------------------------------
function Install-WindowsUpdates {
    param(
        [string]$Criteria,
        [string]$Label,
        [int]$MaxPasses = 5
    )

    $totalFailed = @()
    $totalInstalled = 0

    for ($pass = 1; $pass -le $MaxPasses; $pass++) {
        Write-Host "[$Label] Pass $pass - searching..." -ForegroundColor Gray
        try {
            $session  = New-Object -ComObject Microsoft.Update.Session
            $searcher = $session.CreateUpdateSearcher()
            $result   = $searcher.Search($Criteria)
        } catch {
            Write-Warning "Could not search for $Label updates: $($_.Exception.Message)"
            Write-Warning "Check that the PC has an internet connection."
            return [pscustomobject]@{ Installed = $totalInstalled; Failed = @("Search failed"); SearchError = $true }
        }

        if ($result.Updates.Count -eq 0) {
            Write-Host "[$Label] Nothing left to install." -ForegroundColor Green
            break
        }

        $coll = New-Object -ComObject Microsoft.Update.UpdateColl
        foreach ($u in $result.Updates) {
            if (-not $u.EulaAccepted) { $u.AcceptEula() }
            Write-Host "  Found: $($u.Title)"
            [void]$coll.Add($u)
        }

        Write-Host "[$Label] Downloading $($coll.Count) update(s)..." -ForegroundColor Gray
        $downloader = $session.CreateUpdateDownloader()
        $downloader.Updates = $coll
        try { [void]$downloader.Download() } catch { Write-Warning "Download error: $($_.Exception.Message)" }

        $toInstall = New-Object -ComObject Microsoft.Update.UpdateColl
        foreach ($u in $coll) { if ($u.IsDownloaded) { [void]$toInstall.Add($u) } }
        if ($toInstall.Count -eq 0) {
            $totalFailed += "Nothing downloaded successfully"
            break
        }

        Write-Host "[$Label] Installing $($toInstall.Count) update(s)..." -ForegroundColor Gray
        $installer = $session.CreateUpdateInstaller()
        $installer.Updates = $toInstall
        try {
            $res = $installer.Install()
        } catch {
            Write-Warning "Install error: $($_.Exception.Message)"
            $totalFailed += $_.Exception.Message
            break
        }

        $passFailed = 0
        for ($i = 0; $i -lt $toInstall.Count; $i++) {
            $code = $res.GetUpdateResult($i).ResultCode   # 2 = succeeded
            if ($code -eq 2) { $totalInstalled++ }
            else { $passFailed++; $totalFailed += $toInstall.Item($i).Title }
        }

        if ($res.RebootRequired) {
            $script:RebootNeeded = $true
            Write-Host "[$Label] A reboot is required before continuing." -ForegroundColor Yellow
            break
        }
        if ($passFailed -eq $toInstall.Count) { break }  # nothing worked, don't loop forever
    }

    return [pscustomobject]@{ Installed = $totalInstalled; Failed = $totalFailed; SearchError = $false }
}

# ---------------------------------------------------------------------------
# 1) Windows Update
# ---------------------------------------------------------------------------
Write-Step "STEP 1: Windows Update"
$sw = Install-WindowsUpdates -Criteria "IsInstalled=0 and IsHidden=0 and Type='Software'" -Label "Windows"

if ($script:RebootNeeded) {
    Write-Host ""
    Write-Warning "Windows updates need a restart to finish. More updates may appear after reboot."
    $ans = Read-Host "Restart now? Re-run this script afterward to continue (Y/N)"
    if ($ans -match '^[Yy]') { Restart-Computer -Force; exit }
    Write-Host "Continuing without restart. Re-run this script after rebooting to confirm everything is current." -ForegroundColor Yellow
}
if ($sw.Failed.Count -gt 0) {
    Write-Warning "Some Windows updates failed:"
    $sw.Failed | ForEach-Object { Write-Warning "  - $_" }
}

# ---------------------------------------------------------------------------
# 2) Driver updates (with a restore point first)
# ---------------------------------------------------------------------------
Write-Step "STEP 2: Driver updates"

Write-Host "Creating a System Restore point before installing drivers..." -ForegroundColor Gray
$restoreOk = $false
try {
    # System Protection is often off on fresh installs; turn it on for C: first.
    Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction Stop
    # Note: Windows normally allows only one automatic restore point per 24 hours.
    # If one was already made recently, Checkpoint-Computer warns and skips.
    Checkpoint-Computer -Description "Setup-NewPC: before driver updates" `
                        -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
    $restoreOk = $true
    Write-Host "Restore point created." -ForegroundColor Green
} catch {
    Write-Warning "Could not create a restore point: $($_.Exception.Message)"
}
if (-not $restoreOk -and -not $NoPrompt) {
    $ans = Read-Host "Continue with driver updates WITHOUT a restore point? (Y/N)"
    if ($ans -notmatch '^[Yy]') {
        Write-Host "Skipping driver updates." -ForegroundColor Yellow
        $drv = [pscustomobject]@{ Installed = 0; Failed = @(); SearchError = $false; Skipped = $true }
    }
}

if (-not $drv) {
    $drv = Install-WindowsUpdates -Criteria "IsInstalled=0 and IsHidden=0 and Type='Driver'" -Label "Driver"
}

# Devices Windows still reports as having a problem (usually missing drivers)
$problemDevices = Get-CimInstance Win32_PnPEntity |
    Where-Object { $_.ConfigManagerErrorCode -ne 0 -and $_.ConfigManagerErrorCode -ne $null }

$driversOk = ($drv.Failed.Count -eq 0) -and (-not $drv.SearchError) -and (-not $drv.Skipped) -and
             (-not $problemDevices) -and (-not $script:RebootNeeded)

if ($driversOk) {
    Write-Host "Drivers are up to date (no pending driver updates, no devices with problems)." -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "*********************************************************" -ForegroundColor Red
    Write-Host "  DRIVERS ARE NOT FULLY UPDATED" -ForegroundColor Red
    Write-Host "*********************************************************" -ForegroundColor Red
    if ($drv.Skipped) {
        Write-Host "Driver updates were skipped." -ForegroundColor Yellow
    }
    if ($drv.Failed.Count -gt 0) {
        Write-Host "Driver updates that failed:" -ForegroundColor Yellow
        $drv.Failed | ForEach-Object { Write-Host "  - $_" }
    }
    if ($problemDevices) {
        Write-Host "Devices with missing/broken drivers:" -ForegroundColor Yellow
        $problemDevices | ForEach-Object { Write-Host "  - $($_.Name)  (error code $($_.ConfigManagerErrorCode))" }
    }
    if ($script:RebootNeeded) {
        Write-Host "A reboot is pending - re-run this script after restarting." -ForegroundColor Yellow
    }
    Write-Host ""
    $maker = (Get-CimInstance Win32_ComputerSystem).Manufacturer
    if ($maker -match 'Dell') {
        Write-Host "Tip: install Dell Command | Update or grab drivers from dell.com/support." -ForegroundColor Gray
    } else {
        Write-Host "Tip: check the support/drivers page of your PC or motherboard maker ($maker)." -ForegroundColor Gray
    }
    if (-not $NoPrompt) { Read-Host "Press Enter to continue with the rest of the script" }
}

# ---------------------------------------------------------------------------
# 3) Format extra drives and label them "Storage"
#    Blank drives are formatted automatically. Drives with existing partitions
#    are only wiped after the user types an explicit confirmation phrase, and
#    are never wiped in -NoPrompt mode.
# ---------------------------------------------------------------------------
Write-Step "STEP 3: Extra drives"

function Show-DiskDetails($d) {
    $sizeGB = [math]::Round($d.Size / 1GB)
    Write-Host ("  Disk {0}: {1} | {2} GB | Bus: {3} | Style: {4}" -f `
        $d.Number, $d.FriendlyName, $sizeGB, $d.BusType, $d.PartitionStyle) -ForegroundColor White

    $parts = Get-Partition -DiskNumber $d.Number -ErrorAction SilentlyContinue
    if (-not $parts) {
        Write-Host "    (no partitions)" -ForegroundColor Gray
        return
    }
    foreach ($p in $parts) {
        $vol    = $p | Get-Volume -ErrorAction SilentlyContinue
        $letter = if ($p.DriveLetter) { "$($p.DriveLetter):" } else { "-" }
        $label  = if ($vol -and $vol.FileSystemLabel) { $vol.FileSystemLabel } else { "(no label)" }
        $fs     = if ($vol -and $vol.FileSystem) { $vol.FileSystem } else { "unknown fs" }
        $pSize  = [math]::Round($p.Size / 1GB, 1)
        $used   = if ($vol -and $vol.Size) { "{0} GB used" -f [math]::Round(($vol.Size - $vol.SizeRemaining) / 1GB, 1) } else { "" }
        Write-Host ("    Partition {0}: {1,-3} {2,-10} {3,-14} {4} GB  {5}" -f `
            $p.PartitionNumber, $letter, $fs, $label, $pSize, $used) -ForegroundColor Gray
    }
}

# Extra = not the Windows boot/system disk, and not USB/removable/virtual
$excludedBuses = @('USB', '1394', 'SD', 'MMC', 'Virtual', 'File Backed Virtual', 'Spaces')
$extraDisks = Get-Disk | Where-Object {
    -not $_.IsBoot -and -not $_.IsSystem -and
    ($excludedBuses -notcontains [string]$_.BusType) -and
    $_.Size -gt 0
}

$skippedDisks = @()

if (-not $extraDisks) {
    Write-Host "No extra internal drives found." -ForegroundColor Gray
} else {
    foreach ($d in $extraDisks) {
        $num = $d.Number
        try {
            # Bring online / writable so partitions can be inspected
            if ($d.IsOffline)  { Set-Disk -Number $num -IsOffline $false }
            if ($d.IsReadOnly) { Set-Disk -Number $num -IsReadOnly $false }
            $d = Get-Disk -Number $num

            Show-DiskDetails $d

            $parts = Get-Partition -DiskNumber $num -ErrorAction SilentlyContinue |
                     Where-Object { $_.Type -ne 'Reserved' }
            $hasData = ($d.PartitionStyle -ne 'RAW') -and ($null -ne $parts) -and (@($parts).Count -gt 0)

            if ($hasData) {
                # Always leave a drive alone if it's already set up as Storage
                $already = Get-Volume -DiskNumber $num -ErrorAction SilentlyContinue |
                           Where-Object { $_.FileSystemLabel -eq 'Storage' }
                if ($already) {
                    Write-Host "  Already has a volume named 'Storage' - leaving it alone." -ForegroundColor Gray
                    continue
                }

                if ($NoPrompt) {
                    Write-Host "  Contains existing partitions - skipped (-NoPrompt never wipes drives with data)." -ForegroundColor Yellow
                    $skippedDisks += "Disk $num ($($d.FriendlyName)) - has existing data"
                    continue
                }

                Write-Host ""
                Write-Host "  WARNING: Disk $num has existing partitions. Formatting will PERMANENTLY ERASE all of it." -ForegroundColor Red
                $expected = "ERASE DISK $num"
                $typed = Read-Host "  Type '$expected' (exactly) to erase it, or press Enter to skip"
                if ($typed -cne $expected) {
                    Write-Host "  Skipped." -ForegroundColor Yellow
                    $skippedDisks += "Disk $num ($($d.FriendlyName)) - not confirmed"
                    continue
                }
                Clear-Disk -Number $num -RemoveData -RemoveOEM -Confirm:$false
            }

            $d = Get-Disk -Number $num
            if ($d.PartitionStyle -eq 'RAW') {
                Initialize-Disk -Number $num -PartitionStyle GPT
            }

            $part = New-Partition -DiskNumber $num -UseMaximumSize -AssignDriveLetter
            Format-Volume -Partition $part -FileSystem NTFS -NewFileSystemLabel "Storage" -Confirm:$false | Out-Null
            Write-Host "  Formatted as $($part.DriveLetter): labeled 'Storage'" -ForegroundColor Green
        } catch {
            Write-Warning "  Failed on Disk ${num}: $($_.Exception.Message)"
        }
    }

    if ($skippedDisks.Count -gt 0) {
        Write-Host ""
        Write-Host "Drives left untouched:" -ForegroundColor Yellow
        $skippedDisks | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
    }
}

# ---------------------------------------------------------------------------
# 4) Spec summary
# ---------------------------------------------------------------------------
Write-Step "STEP 4: Computer specs"

function Get-Ordinal([int]$n) {
    if (($n % 100) -in 11, 12, 13) { return "${n}th" }
    switch ($n % 10) { 1 { "${n}st" } 2 { "${n}nd" } 3 { "${n}rd" } default { "${n}th" } }
}

# Model
$cs = Get-CimInstance Win32_ComputerSystem
$modelText = $cs.Model

# Processor + generation
$cpu = (Get-CimInstance Win32_Processor | Select-Object -First 1).Name -replace '\s+', ' '
$cpuText = $cpu.Trim()
if ($cpu -match 'Core\(TM\)\s+i([3579])-(\d{3,5})') {
    $tier = $Matches[1]; $digits = $Matches[2]
    switch ($digits.Length) {
        5 { $gen = [int]$digits.Substring(0, 2) }
        4 { $gen = [int]$digits.Substring(0, 1) }
        default { $gen = 1 }
    }
    $cpuText = "i$tier $(Get-Ordinal $gen) gen"
} elseif ($cpu -match 'Ryzen') {
    $cpuText = ($cpu -replace '\(R\)|\(TM\)|Processor|with.*$', '').Trim()
}

# RAM
$mods = Get-CimInstance Win32_PhysicalMemory
$totalGB = [math]::Round(($mods | Measure-Object Capacity -Sum).Sum / 1GB)
$ramType = switch (($mods | Select-Object -First 1).SMBIOSMemoryType) {
    20 { "PC" } 21 { "PC2" } 24 { "PC3" } 26 { "PC4" } 34 { "PC5" } default { "" }
}
$ramText = "$totalGB GB $ramType".Trim()

# C: drive
$cText = "Unknown"
try {
    $part = Get-Partition -DriveLetter C
    $disk = Get-Disk -Number $part.DiskNumber
    $pd   = Get-PhysicalDisk | Where-Object { [int]$_.DeviceId -eq $disk.Number } | Select-Object -First 1
    if (-not $pd) { $pd = Get-PhysicalDisk | Where-Object { $_.FriendlyName -eq $disk.FriendlyName } | Select-Object -First 1 }
    $gb   = [math]::Round($pd.Size / 1e9)
    $std  = 120, 128, 240, 250, 256, 480, 500, 512, 1000, 1024, 2000, 2048, 4000
    $near = $std | Sort-Object { [math]::Abs($_ - $gb) } | Select-Object -First 1
    $sizeText = if ($near -ge 1000) { "$([math]::Round($near / 1000)) TB" } else { "$near GB" }
    $mediaType = $pd.MediaType
    if ($pd.BusType -eq 'NVMe' -or $mediaType -eq 'SSD') { $kind = if ($pd.BusType -eq 'NVMe') { "NVMe SSD" } else { "SSD" } }
    elseif ($mediaType -eq 'HDD') { $kind = "HDD" }
    else { $kind = "(type unknown)" }
    $cText = "$sizeText $kind"
} catch { }

# Wi-Fi / Bluetooth
$wifi = Get-NetAdapter -Physical -ErrorAction SilentlyContinue |
        Where-Object { $_.PhysicalMediaType -match '802\.11' -or $_.InterfaceDescription -match 'Wi-?Fi|Wireless|WLAN|802\.11' }
if (-not $wifi) {
    $wifi = Get-PnpDevice -Class Net -ErrorAction SilentlyContinue |
            Where-Object { $_.FriendlyName -match 'Wi-?Fi|Wireless|WLAN|802\.11' -and $_.Present }
}
$bt = Get-PnpDevice -Class Bluetooth -PresentOnly -ErrorAction SilentlyContinue |
      Where-Object { $_.InstanceId -match '^(USB|PCI|ACPI)\\' }

$wifiText = if ($wifi) { "Yes" } else { "No" }
$btText   = if ($bt)   { "Yes" } else { "No" }

Write-Host ""
Write-Host "  Computer model : $modelText"
Write-Host "  Processor      : $cpuText"
Write-Host "  RAM            : $ramText"
Write-Host "  C: drive       : $cText"
Write-Host "  Wi-Fi          : $wifiText"
Write-Host "  Bluetooth      : $btText"
Write-Host ""

if (-not $driversOk) {
    Write-Host "NOTE: drivers were not fully updated - Wi-Fi/Bluetooth may show 'No' only because their drivers are missing." -ForegroundColor Yellow
}
if (-not $NoPrompt) { Read-Host "Done. Press Enter to exit" }
