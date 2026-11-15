<#
.SYNOPSIS
    Fresh-Windows setup with a native WPF GUI.
.USAGE
    Right-click > Run with PowerShell, or:
    powershell -ExecutionPolicy Bypass -File .\Source.ps1
#>

# ---------------------------------------------------------------------------
# 1. Self-elevate to Administrator
# ---------------------------------------------------------------------------
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms, Microsoft.VisualBasic

# ---------------------------------------------------------------------------
# 2. XAML UI Definition
# ---------------------------------------------------------------------------
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="New PC Setup &amp; Diagnostics" Height="740" Width="850"
        WindowStartupLocation="CenterScreen" Background="#F3F3F3" FontFamily="Segoe UI">
    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Padding" Value="14,8"/>
            <Setter Property="Margin" Value="0,0,10,0"/>
            <Setter Property="Background" Value="#FFFFFF"/>
            <Setter Property="BorderBrush" Value="#CCCCCC"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Cursor" Value="Hand"/>
        </Style>
        <Style x:Key="PrimaryBtn" TargetType="Button" BasedOn="{StaticResource {x:Type Button}}">
            <Setter Property="Background" Value="#0067C0"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="BorderBrush" Value="#0067C0"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
        </Style>
    </Window.Resources>

    <Grid Margin="20">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>

        <!-- Header -->
        <StackPanel Grid.Row="0" Margin="0,0,0,14">
            <TextBlock Text="New PC Setup &amp; Diagnostics" FontSize="22" FontWeight="SemiBold" Foreground="#1A1A1A"/>
            <TextBlock Text="Inspect hardware, check Windows &amp; driver status, and run post-install tasks." Foreground="#555555" Margin="0,2,0,0"/>
        </StackPanel>

        <!-- Section 1: System Hardware Card -->
        <Border Grid.Row="1" Background="White" BorderBrush="#E0E0E0" BorderThickness="1" CornerRadius="6" Padding="16" Margin="0,0,0,12">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="130"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="130"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="24"/>
                    <RowDefinition Height="24"/>
                    <RowDefinition Height="24"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>

                <TextBlock Grid.Row="0" Grid.ColumnSpan="4" Text="System Hardware" FontSize="15" FontWeight="SemiBold" Margin="0,0,0,8"/>

                <!-- Left Column -->
                <TextBlock Grid.Row="1" Grid.Column="0" Text="Computer Model:" FontWeight="SemiBold" Foreground="#444"/>
                <TextBlock Grid.Row="1" Grid.Column="1" Name="TxtModel" Text="Loading..."/>

                <TextBlock Grid.Row="2" Grid.Column="0" Text="Processor:" FontWeight="SemiBold" Foreground="#444"/>
                <TextBlock Grid.Row="2" Grid.Column="1" Name="TxtCpu" Text="Loading..."/>

                <TextBlock Grid.Row="3" Grid.Column="0" Text="Memory (RAM):" FontWeight="SemiBold" Foreground="#444"/>
                <TextBlock Grid.Row="3" Grid.Column="1" Name="TxtRam" Text="Loading..."/>

                <!-- Right Column -->
                <TextBlock Grid.Row="1" Grid.Column="2" Text="System Drive (C:):" FontWeight="SemiBold" Foreground="#444"/>
                <TextBlock Grid.Row="1" Grid.Column="3" Name="TxtCDrive" Text="Loading..."/>

                <TextBlock Grid.Row="2" Grid.Column="2" Text="Wi-Fi Adapter:" FontWeight="SemiBold" Foreground="#444"/>
                <TextBlock Grid.Row="2" Grid.Column="3" Name="TxtWifi" Text="Loading..."/>

                <TextBlock Grid.Row="3" Grid.Column="2" Text="Bluetooth:" FontWeight="SemiBold" Foreground="#444"/>
                <TextBlock Grid.Row="3" Grid.Column="3" Name="TxtBt" Text="Loading..."/>

                <!-- Attached Drives List -->
                <TextBlock Grid.Row="4" Grid.Column="0" Text="Attached Drives:" FontWeight="SemiBold" Foreground="#444" Margin="0,6,0,0"/>
                <TextBlock Grid.Row="4" Grid.Column="1" Grid.ColumnSpan="3" Name="TxtDrivesList" Text="Loading..." TextWrapping="Wrap" Margin="0,6,0,0"/>
            </Grid>
        </Border>

        <!-- Section 2: System Software Card -->
        <Border Grid.Row="2" Background="White" BorderBrush="#E0E0E0" BorderThickness="1" CornerRadius="6" Padding="16" Margin="0,0,0,14">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="130"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="130"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="24"/>
                    <RowDefinition Height="24"/>
                </Grid.RowDefinitions>

                <TextBlock Grid.Row="0" Grid.ColumnSpan="4" Text="System Software" FontSize="15" FontWeight="SemiBold" Margin="0,0,0,8"/>

                <!-- Left Column -->
                <TextBlock Grid.Row="1" Grid.Column="0" Text="Windows Version:" FontWeight="SemiBold" Foreground="#444"/>
                <TextBlock Grid.Row="1" Grid.Column="1" Name="TxtWinVer" Text="Loading..."/>

                <TextBlock Grid.Row="2" Grid.Column="0" Text="Activation:" FontWeight="SemiBold" Foreground="#444"/>
                <TextBlock Grid.Row="2" Grid.Column="1" Name="TxtActivation" Text="Loading..." FontWeight="SemiBold"/>

                <!-- Right Column -->
                <TextBlock Grid.Row="1" Grid.Column="2" Text="Windows Update:" FontWeight="SemiBold" Foreground="#444"/>
                <TextBlock Grid.Row="1" Grid.Column="3" Name="TxtWinUpdates" Text="Loading..."/>

                <TextBlock Grid.Row="2" Grid.Column="2" Text="Driver Updates:" FontWeight="SemiBold" Foreground="#444"/>
                <TextBlock Grid.Row="2" Grid.Column="3" Name="TxtDriverUpdates" Text="Loading..."/>
            </Grid>
        </Border>

        <!-- Action Buttons -->
        <StackPanel Grid.Row="3" Orientation="Horizontal" Margin="0,0,0,14">
            <Button Name="BtnUpdates" Content="Install Windows Updates" Style="{StaticResource PrimaryBtn}"/>
            <Button Name="BtnDrivers" Content="Update Drivers (with Restore Point)"/>
            <Button Name="BtnDrives" Content="Format Extra Drives..."/>
            <Button Name="BtnRefresh" Content="Refresh Specs"/>
        </StackPanel>

        <!-- Activity Log -->
        <Border Grid.Row="4" Background="#1E1E1E" BorderBrush="#333333" BorderThickness="1" CornerRadius="6" Padding="12">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                </Grid.RowDefinitions>
                <TextBlock Grid.Row="0" Text="Activity Log" Foreground="#CCCCCC" FontWeight="SemiBold" Margin="0,0,0,6"/>
                <TextBox Grid.Row="1" Name="TxtLog" Background="Transparent" Foreground="#E0E0E0" 
                         BorderThickness="0" FontFamily="Consolas" FontSize="12" IsReadOnly="True" 
                         TextWrapping="Wrap" VerticalScrollBarVisibility="Auto"/>
            </Grid>
        </Border>
    </Grid>
</Window>
"@

# Parse XAML and bind controls
$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

$controls = @{}
$xaml.SelectNodes("//*[@Name]") | ForEach-Object {
    $controls[$_.Name] = $window.FindName($_.Name)
}

# ---------------------------------------------------------------------------
# 3. UI & Background Thread Helpers
# ---------------------------------------------------------------------------
$sync = [hashtable]::Synchronized(@{
    Window   = $window
    Controls = $controls
})

function Write-GuiLog([string]$msg) {
    $timestamp = (Get-Date).ToString("HH:mm:ss")
    $sync.Window.Dispatcher.Invoke([action]{
        $sync.Controls.TxtLog.AppendText("[$timestamp] $msg`r`n")
        $sync.Controls.TxtLog.ScrollToEnd()
    })
}

function Set-UiBusy([bool]$busy) {
    $sync.Window.Dispatcher.Invoke([action]{
        $sync.Controls.BtnUpdates.IsEnabled = -not $busy
        $sync.Controls.BtnDrivers.IsEnabled = -not $busy
        $sync.Controls.BtnDrives.IsEnabled  = -not $busy
        $sync.Controls.BtnRefresh.IsEnabled = -not $busy
    })
}

function Invoke-AsyncTask([scriptblock]$ScriptBlock) {
    Set-UiBusy $true
    $ps = [powershell]::Create().AddScript($ScriptBlock)
    $ps.Runspace.SessionStateProxy.SetVariable("sync", $sync)
    $ps.Runspace.SessionStateProxy.SetVariable("WriteGuiLog", ${function:Write-GuiLog})
    $ps.Runspace.SessionStateProxy.SetVariable("SetUiBusy", ${function:Set-UiBusy})
    [void]$ps.BeginInvoke()
}

# ---------------------------------------------------------------------------
# 4. System Hardware, Software & Update Check
# ---------------------------------------------------------------------------
function Load-Specs {
    # Immediately reset update fields to Loading... on UI thread
    $sync.Window.Dispatcher.Invoke([action]{
        $sync.Controls.TxtWinUpdates.Text       = "Loading..."
        $sync.Controls.TxtWinUpdates.Foreground = [System.Windows.Media.Brushes]::Black
        $sync.Controls.TxtDriverUpdates.Text    = "Loading..."
        $sync.Controls.TxtDriverUpdates.Foreground = [System.Windows.Media.Brushes]::Black
    })

    Invoke-AsyncTask {
        & $WriteGuiLog "Scanning hardware and Windows status..."

        function Get-Ordinal([int]$n) {
            if (($n % 100) -in 11, 12, 13) { return "${n}th" }
            switch ($n % 10) { 1 { "${n}st" } 2 { "${n}nd" } 3 { "${n}rd" } default { "${n}th" } }
        }

        function Format-DriveSize([long]$bytes) {
            if ($bytes -le 0) { return "Unknown size" }
            $gb = [math]::Round($bytes / 1e9)
            $std = 120, 128, 240, 250, 256, 480, 500, 512, 1000, 1024, 2000, 2048, 4000, 8000
            $near = $std | Sort-Object { [math]::Abs($_ - $gb) } | Select-Object -First 1
            if ([math]::Abs($near - $gb) -le ($near * 0.08)) {
                if ($near -ge 1000) { return "$([math]::Round($near / 1000)) TB" }
                return "$near GB"
            }
            $gib = [math]::Round($bytes / 1GB)
            if ($gib -ge 1000) { return "$([math]::Round($gib / 1024, 1)) TB" }
            return "$gib GB"
        }

        function Get-DriveKind($pd, $disk) {
            $bus   = if ($pd) { [string]$pd.BusType } else { [string]$disk.BusType }
            $media = if ($pd) { [string]$pd.MediaType } else { "" }
            if ($bus -eq 'NVMe') { return "NVMe SSD" }
            if ($media -eq 'SSD') { return "SSD" }
            if ($media -eq 'HDD') { return "HDD" }
            if ($bus -eq 'USB') { return "USB Drive" }
            return "Drive ($bus)"
        }

        # --- HARDWARE ---
        $modelText = (Get-CimInstance Win32_ComputerSystem).Model

        $cpu = (Get-CimInstance Win32_Processor | Select-Object -First 1).Name -replace '\s+', ' '
        $cpuText = $cpu.Trim()
        if ($cpu -match 'Core\(TM\)\s+i([3579])-(\d{3,5})') {
            $tier = $Matches[1]; $digits = $Matches[2]
            $gen = switch ($digits.Length) { 5 { [int]$digits.Substring(0, 2) } 4 { [int]$digits.Substring(0, 1) } default { 1 } }
            $cpuText = "i$tier $(Get-Ordinal $gen) gen"
        } elseif ($cpu -match 'Ryzen') {
            $cpuText = ($cpu -replace '\(R\)|\(TM\)|Processor|with.*$', '').Trim()
        }

        $mods = Get-CimInstance Win32_PhysicalMemory
        $totalGB = [math]::Round(($mods | Measure-Object Capacity -Sum).Sum / 1GB)
        $ramType = switch (($mods | Select-Object -First 1).SMBIOSMemoryType) {
            20 { "DDR" } 21 { "DDR2" } 24 { "DDR3" } 26 { "DDR4" } 34 { "DDR5" } default { "" }
        }
        $ramText = "$totalGB GB $ramType".Trim()

        # C: Drive
        $cText = "Unknown"
        try {
            $part = Get-Partition -DriveLetter C
            $disk = Get-Disk -Number $part.DiskNumber
            $pd   = Get-PhysicalDisk | Where-Object { [int]$_.DeviceId -eq $disk.Number } | Select-Object -First 1
            if (-not $pd) { $pd = Get-PhysicalDisk | Where-Object { $_.FriendlyName -eq $disk.FriendlyName } | Select-Object -First 1 }
            $cText = "$(Format-DriveSize $disk.Size) $(Get-DriveKind $pd $disk)"
        } catch {}

        # All Attached Drives
        $allDisks = Get-Disk | Where-Object { $_.Size -gt 0 } | Sort-Object Number
        $allPDs   = Get-PhysicalDisk -ErrorAction SilentlyContinue
        $driveLines = foreach ($d in $allDisks) {
            $pd = $allPDs | Where-Object { [int]$_.DeviceId -eq $d.Number } | Select-Object -First 1
            if (-not $pd) { $pd = $allPDs | Where-Object { $_.FriendlyName -eq $d.FriendlyName } | Select-Object -First 1 }
            $sizeStr = Format-DriveSize $d.Size
            $kindStr = Get-DriveKind $pd $d
            $letters = (Get-Partition -DiskNumber $d.Number -ErrorAction SilentlyContinue | Where-Object DriveLetter | ForEach-Object { "$($_.DriveLetter):" }) -join ", "
            $letterTag = if ($letters) { " [$letters]" } elseif ($d.PartitionStyle -eq 'RAW') { " [Unallocated]" } else { "" }
            "Disk $($d.Number): $sizeStr $kindStr - $($d.FriendlyName)$letterTag"
        }
        $drivesListText = if ($driveLines) { $driveLines -join "`r`n" } else { "None detected" }

        # Wi-Fi & Bluetooth
        $wifi = Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Where-Object { $_.PhysicalMediaType -match '802\.11' -or $_.InterfaceDescription -match 'Wi-?Fi|Wireless|WLAN|802\.11' }
        if (-not $wifi) { $wifi = Get-PnpDevice -Class Net -ErrorAction SilentlyContinue | Where-Object { $_.FriendlyName -match 'Wi-?Fi|Wireless|WLAN|802\.11' -and $_.Present } }
        $bt = Get-PnpDevice -Class Bluetooth -PresentOnly -ErrorAction SilentlyContinue | Where-Object { $_.InstanceId -match '^(USB|PCI|ACPI)\\' }

        $wifiText = if ($wifi) { "Yes" } else { "No" }
        $btText   = if ($bt)   { "Yes" } else { "No" }

        # --- SOFTWARE (OS & Activation) ---
        $cv = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -ErrorAction SilentlyContinue
        $prodName = $cv.ProductName
        if ([int]$cv.CurrentBuild -ge 22000) { $prodName = $prodName -replace 'Windows 10', 'Windows 11' }
        $winVerText = "$prodName $($cv.DisplayVersion) (Build $($cv.CurrentBuild).$($cv.UBR))".Trim()

        $lic = Get-CimInstance SoftwareLicensingProduct -Filter "ApplicationID='55c92734-d682-4d71-983e-d6ec3f16059f' AND PartialProductKey IS NOT NULL" -ErrorAction SilentlyContinue |
               Where-Object { $_.LicenseStatus -eq 1 }
        $isActivated = [bool]$lic
        $actText = if ($isActivated) { "Activated" } else { "Not Activated" }

        # Push hardware + OS info to UI immediately (before slow Windows Update scan finishes)
        $sync.Window.Dispatcher.Invoke([action]{
            $sync.Controls.TxtModel.Text      = $modelText
            $sync.Controls.TxtCpu.Text        = $cpuText
            $sync.Controls.TxtRam.Text        = $ramText
            $sync.Controls.TxtCDrive.Text     = $cText
            $sync.Controls.TxtWifi.Text       = $wifiText
            $sync.Controls.TxtBt.Text         = $btText
            $sync.Controls.TxtDrivesList.Text = $drivesListText

            $sync.Controls.TxtWinVer.Text     = $winVerText
            $sync.Controls.TxtActivation.Text = $actText
            $sync.Controls.TxtActivation.Foreground = if ($isActivated) { [System.Windows.Media.Brushes]::Green } else { [System.Windows.Media.Brushes]::Crimson }
        })

        & $WriteGuiLog "Hardware & OS specs loaded. Checking for available Windows & driver updates..."

        # --- CHECK PENDING UPDATES ---
        $winUpdText = "Check failed (no internet?)"
        $winUpdColor = [System.Windows.Media.Brushes]::Crimson
        $drvUpdText = "Check failed (no internet?)"
        $drvUpdColor = [System.Windows.Media.Brushes]::Crimson

        try {
            $session  = New-Object -ComObject Microsoft.Update.Session
            $searcher = $session.CreateUpdateSearcher()

            $swRes  = $searcher.Search("IsInstalled=0 and IsHidden=0 and Type='Software'")
            $swCnt  = $swRes.Updates.Count
            if ($swCnt -eq 0) {
                $winUpdText  = "Up to date (0 updates available)"
                $winUpdColor = [System.Windows.Media.Brushes]::Green
            } else {
                $winUpdText  = "$swCnt update(s) available"
                $winUpdColor = [System.Windows.Media.Brushes]::DarkOrange
            }

            $drvRes = $searcher.Search("IsInstalled=0 and IsHidden=0 and Type='Driver'")
            $drvCnt = $drvRes.Updates.Count
            if ($drvCnt -eq 0) {
                $drvUpdText  = "Up to date (0 driver updates available)"
                $drvUpdColor = [System.Windows.Media.Brushes]::Green
            } else {
                $drvUpdText  = "$drvCnt driver update(s) available"
                $drvUpdColor = [System.Windows.Media.Brushes]::DarkOrange
            }
        } catch {
            & $WriteGuiLog "Update check warning: $($_.Exception.Message)"
        }

        $sync.Window.Dispatcher.Invoke([action]{
            $sync.Controls.TxtWinUpdates.Text          = $winUpdText
            $sync.Controls.TxtWinUpdates.Foreground    = $winUpdColor
            $sync.Controls.TxtDriverUpdates.Text       = $drvUpdText
            $sync.Controls.TxtDriverUpdates.Foreground = $drvUpdColor
        })

        & $WriteGuiLog "Scan complete."
        & $SetUiBusy $false
    }
}

# ---------------------------------------------------------------------------
# 5. Button Event Handlers
# ---------------------------------------------------------------------------

# --- Windows Updates ---
$controls.BtnUpdates.Add_Click({
    Invoke-AsyncTask {
        & $WriteGuiLog "=== Starting Windows Update ==="
        $rebootNeeded = $false
        $criteria = "IsInstalled=0 and IsHidden=0 and Type='Software'"

        for ($pass = 1; $pass -le 5; $pass++) {
            & $WriteGuiLog "[Windows] Pass $pass - searching..."
            try {
                $session  = New-Object -ComObject Microsoft.Update.Session
                $searcher = $session.CreateUpdateSearcher()
                $result   = $searcher.Search($criteria)
            } catch {
                & $WriteGuiLog "ERROR searching updates: $($_.Exception.Message)"
                break
            }

            if ($result.Updates.Count -eq 0) {
                & $WriteGuiLog "[Windows] Everything is up to date."
                $sync.Window.Dispatcher.Invoke([action]{
                    $sync.Controls.TxtWinUpdates.Text       = "Up to date (0 updates available)"
                    $sync.Controls.TxtWinUpdates.Foreground = [System.Windows.Media.Brushes]::Green
                })
                break
            }

            $coll = New-Object -ComObject Microsoft.Update.UpdateColl
            foreach ($u in $result.Updates) {
                if (-not $u.EulaAccepted) { $u.AcceptEula() }
                & $WriteGuiLog "  Found: $($u.Title)"
                [void]$coll.Add($u)
            }

            & $WriteGuiLog "[Windows] Downloading $($coll.Count) update(s)..."
            $downloader = $session.CreateUpdateDownloader()
            $downloader.Updates = $coll
            try { [void]$downloader.Download() } catch { & $WriteGuiLog "Download warning: $($_.Exception.Message)" }

            $toInstall = New-Object -ComObject Microsoft.Update.UpdateColl
            foreach ($u in $coll) { if ($u.IsDownloaded) { [void]$toInstall.Add($u) } }
            if ($toInstall.Count -eq 0) { & $WriteGuiLog "ERROR: Updates failed to download."; break }

            & $WriteGuiLog "[Windows] Installing $($toInstall.Count) update(s)..."
            $installer = $session.CreateUpdateInstaller()
            $installer.Updates = $toInstall
            $res = $installer.Install()

            $failed = 0
            for ($i = 0; $i -lt $toInstall.Count; $i++) {
                if ($res.GetUpdateResult($i).ResultCode -ne 2) {
                    $failed++
                    & $WriteGuiLog "  FAILED: $($toInstall.Item($i).Title)"
                }
            }

            if ($res.RebootRequired) { $rebootNeeded = $true; break }
            if ($failed -eq $toInstall.Count) { break }
        }

        if ($rebootNeeded) {
            & $WriteGuiLog "REBOOT REQUIRED to finish installing updates."
            $sync.Window.Dispatcher.Invoke([action]{
                $choice = [System.Windows.MessageBox]::Show("Windows updates require a restart to complete. Restart now?", "Restart Required", "YesNo", "Question")
                if ($choice -eq "Yes") { Restart-Computer -Force }
            })
        }
        & $SetUiBusy $false
    }
})

# --- Driver Updates (with System Restore Point) ---
$controls.BtnDrivers.Add_Click({
    Invoke-AsyncTask {
        & $WriteGuiLog "=== Starting Driver Updates ==="
        & $WriteGuiLog "Creating System Restore point..."
        $restoreOk = $false
        try {
            Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction Stop
            Checkpoint-Computer -Description "Setup-NewPC: before driver updates" -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
            $restoreOk = $true
            & $WriteGuiLog "Restore point created."
        } catch {
            & $WriteGuiLog "WARNING: Restore point failed: $($_.Exception.Message)"
        }

        $proceed = $true
        if (-not $restoreOk) {
            $sync.Window.Dispatcher.Invoke([action]{
                $ans = [System.Windows.MessageBox]::Show("Could not create a System Restore point. Continue with driver updates anyway?", "Restore Point Failed", "YesNo", "Warning")
                if ($ans -ne "Yes") { $proceed = $false }
            })
        }

        if (-not $proceed) {
            & $WriteGuiLog "Driver updates cancelled by user."
            & $SetUiBusy $false
            return
        }

        try {
            $session  = New-Object -ComObject Microsoft.Update.Session
            $searcher = $session.CreateUpdateSearcher()
            $result   = $searcher.Search("IsInstalled=0 and IsHidden=0 and Type='Driver'")

            if ($result.Updates.Count -eq 0) {
                & $WriteGuiLog "[Drivers] No Windows Update drivers available."
            } else {
                $coll = New-Object -ComObject Microsoft.Update.UpdateColl
                foreach ($u in $result.Updates) {
                    if (-not $u.EulaAccepted) { $u.AcceptEula() }
                    & $WriteGuiLog "  Found driver: $($u.Title)"
                    [void]$coll.Add($u)
                }
                & $WriteGuiLog "Downloading & installing $($coll.Count) driver(s)..."
                $dl = $session.CreateUpdateDownloader(); $dl.Updates = $coll; [void]$dl.Download()
                $in = $session.CreateUpdateInstaller();  $in.Updates = $coll; $res = $in.Install()
                if ($res.RebootRequired) { & $WriteGuiLog "Reboot required for new drivers to take effect." }
            }

            $sync.Window.Dispatcher.Invoke([action]{
                $sync.Controls.TxtDriverUpdates.Text       = "Up to date (0 driver updates available)"
                $sync.Controls.TxtDriverUpdates.Foreground = [System.Windows.Media.Brushes]::Green
            })
        } catch {
            & $WriteGuiLog "ERROR updating drivers: $($_.Exception.Message)"
        }

        $problems = Get-CimInstance Win32_PnPEntity | Where-Object { $_.ConfigManagerErrorCode -ne 0 -and $null -ne $_.ConfigManagerErrorCode }
        if ($problems) {
            $maker = (Get-CimInstance Win32_ComputerSystem).Manufacturer
            & $WriteGuiLog "WARNING: Devices still missing/broken drivers:"
            foreach ($p in $problems) { & $WriteGuiLog "  - $($p.Name) (Code $($p.ConfigManagerErrorCode))" }
            & $WriteGuiLog "Tip: Check support page for $maker."
        } else {
            & $WriteGuiLog "All hardware devices report healthy drivers."
        }

        & $SetUiBusy $false
    }
})

# --- Format Extra Drives ---
$controls.BtnDrives.Add_Click({
    $excludedBuses = @('USB', '1394', 'SD', 'MMC', 'Virtual', 'File Backed Virtual', 'Spaces')
    $extraDisks = Get-Disk | Where-Object {
        -not $_.IsBoot -and -not $_.IsSystem -and
        ($excludedBuses -notcontains [string]$_.BusType) -and $_.Size -gt 0
    }

    if (-not $extraDisks) {
        [System.Windows.MessageBox]::Show("No extra internal drives were detected.", "Extra Drives", "OK", "Information") | Out-Null
        return
    }

    foreach ($d in $extraDisks) {
        $num = $d.Number
        if ($d.IsOffline)  { Set-Disk -Number $num -IsOffline $false }
        if ($d.IsReadOnly) { Set-Disk -Number $num -IsReadOnly $false }
        $d = Get-Disk -Number $num
        $sizeGB = [math]::Round($d.Size / 1GB)

        $parts = Get-Partition -DiskNumber $num -ErrorAction SilentlyContinue | Where-Object { $_.Type -ne 'Reserved' }
        $hasData = ($d.PartitionStyle -ne 'RAW') -and ($null -ne $parts) -and (@($parts).Count -gt 0)

        if ($hasData) {
            $already = Get-Volume -DiskNumber $num -ErrorAction SilentlyContinue | Where-Object { $_.FileSystemLabel -eq 'Storage' }
            if ($already) {
                Write-GuiLog "Disk $num ($($d.FriendlyName)) already has a 'Storage' volume - skipped."
                continue
            }

            $partSummary = ($parts | ForEach-Object {
                $vol = $_ | Get-Volume -ErrorAction SilentlyContinue
                $lbl = if ($vol.FileSystemLabel) { $vol.FileSystemLabel } else { "No Label" }
                "  - Partition $($_.PartitionNumber): $([math]::Round($_.Size/1GB,1)) GB ($lbl)"
            }) -join "`n"

            $prompt = "Disk $num ($($d.FriendlyName) - $sizeGB GB) contains existing partitions:`n$partSummary`n`nType 'ERASE DISK $num' exactly to wipe and format as 'Storage':"
            $typed = [Microsoft.VisualBasic.Interaction]::InputBox($prompt, "Confirm Drive Wipe", "")

            if ($typed -cne "ERASE DISK $num") {
                Write-GuiLog "Disk $num skipped (confirmation did not match)."
                continue
            }
            Clear-Disk -Number $num -RemoveData -RemoveOEM -Confirm:$false
        } else {
            $ans = [System.Windows.MessageBox]::Show("Blank drive detected:`nDisk $num - $($d.FriendlyName) ($sizeGB GB)`n`nInitialize as GPT and format as 'Storage'?", "Format Blank Drive", "YesNo", "Question")
            if ($ans -ne "Yes") {
                Write-GuiLog "Blank Disk $num skipped by user."
                continue
            }
        }

        try {
            $d = Get-Disk -Number $num
            if ($d.PartitionStyle -eq 'RAW') { Initialize-Disk -Number $num -PartitionStyle GPT }
            $part = New-Partition -DiskNumber $num -UseMaximumSize -AssignDriveLetter
            Format-Volume -Partition $part -FileSystem NTFS -NewFileSystemLabel "Storage" -Confirm:$false | Out-Null
            Write-GuiLog "SUCCESS: Disk $num formatted as $($part.DriveLetter): labeled 'Storage'."
        } catch {
            Write-GuiLog "ERROR formatting Disk ${num}: $($_.Exception.Message)"
        }
    }

    # Refresh specs to reflect updated drive letters
    Load-Specs
})

$controls.BtnRefresh.Add_Click({ Load-Specs })

# Run initial scan when window opens and show UI
$window.Add_Loaded({ Load-Specs })
[void]$window.ShowDialog()