        # SCRIPT RUN AS ADMIN
        If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator"))
        {Start-Process PowerShell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $PSCommandPath) -Verb RunAs
        Exit}
        $Host.UI.RawUI.WindowTitle = $myInvocation.MyCommand.Definition + " (Administrator)"
        $Host.UI.RawUI.BackgroundColor = "Black"
        $Host.PrivateData.ProgressBackgroundColor = "Black"
        $Host.PrivateData.ProgressForegroundColor = "White"
        Clear-Host

        # SCRIPT ARCHITECTURE
        function Get-WinSuxNativeArchitecture {
        $architectureCandidates = @(
        $env:PROCESSOR_ARCHITEW6432,
        [Environment]::GetEnvironmentVariable('PROCESSOR_ARCHITECTURE', 'Machine'),
        $env:PROCESSOR_ARCHITECTURE
        ) | Where-Object { -not [String]::IsNullOrWhiteSpace($_) }

        foreach ($architecture in $architectureCandidates) {
        switch -Regex ($architecture.ToUpperInvariant()) {
        '^ARM64' { return 'ARM64' }
        '^(AMD64|X64)' { return 'AMD64' }
        '^X86' { return 'X86' }
        }
        }

        try {
        switch ([System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString()) {
        'Arm64' { return 'ARM64' }
        'X64' { return 'AMD64' }
        'X86' { return 'X86' }
        }
        } catch { }
        return 'Unknown'
        }

        $WinSuxArchitecture = Get-WinSuxNativeArchitecture
        $WinSuxIsArm64 = $WinSuxArchitecture -eq 'ARM64'
        $WinSuxSupportsX64 = -not $WinSuxIsArm64 -or ([Environment]::OSVersion.Version.Build -ge 22000)
        $WinSuxTempRoot = Join-Path $env:SystemRoot 'Temp'
        $WinSuxBaseUrl = 'https://github.com/cyroz1/WinSux-arm64'
        $WinSuxReleaseBaseUrl = 'https://github.com/FR33THYFR33THY/WinSux'
        $WinSuxRawUrl = "$WinSuxBaseUrl/raw/refs/heads/main/WinSux"
        $WinSuxReleaseUrl = "$WinSuxReleaseBaseUrl/releases/download/Files"

        Write-Host "Architecture: $WinSuxArchitecture`n"

        # SCRIPT CHECK INTERNET
        if (!(Test-Connection -ComputerName "8.8.8.8" -Count 1 -Quiet -ErrorAction SilentlyContinue)) {
        Write-Host "Internet Connection Required`n" -ForegroundColor Red
        Pause
        exit
        }

        # SCRIPT SILENT
        $progresspreference = 'silentlycontinue'

        Write-Host "DL`n"
		## explorer "https://github.com/FR33THYFR33THY/WinSux/tree/main/WinSux"

# download winsux temp files
IWR "$WinSuxRawUrl/reg.reg" -OutFile "$WinSuxTempRoot\reg.reg"
IWR "$WinSuxRawUrl/settimerresolutionservice.cs" -OutFile "$WinSuxTempRoot\settimerresolutionservice.cs"
IWR "$WinSuxRawUrl/start2.txt" -OutFile "$WinSuxTempRoot\start2.txt"
IWR "$WinSuxRawUrl/stepone.ps1" -OutFile "$WinSuxTempRoot\stepone.ps1"
IWR "$WinSuxRawUrl/steptwo.ps1" -OutFile "$WinSuxTempRoot\steptwo.ps1"

        Write-Host "7Z`n"
        ## explorer "https://www.7-zip.org" 

# download 7zip
$SevenZipInstaller = "$WinSuxTempRoot\7zip.exe"
$SevenZipUrl = if ($WinSuxIsArm64) {
'https://www.7-zip.org/a/7z2301-arm64.exe'
} else {
"$WinSuxReleaseUrl/7zip.exe"
}
IWR $SevenZipUrl -OutFile $SevenZipInstaller

# install 7zip
Start-Process -Wait $SevenZipInstaller -ArgumentList "/S"

# find 7zip after installation; ARM64 and x64 installers use different roots
$SevenZipCandidates = @()
foreach ($ProgramFilesRoot in @(
[Environment]::GetFolderPath('ProgramFiles'),
[Environment]::GetFolderPath('ProgramFilesX86')
)) {
if ($ProgramFilesRoot) {
$SevenZipCandidates += Join-Path $ProgramFilesRoot '7-Zip\7z.exe'
}
}
$SevenZipPath = $SevenZipCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if (-not $SevenZipPath) {
$SevenZipPath = (Get-Command '7z.exe' -ErrorAction SilentlyContinue).Source
}
if (-not $SevenZipPath) {
throw '7-Zip installation failed: 7z.exe was not found.'
}

# set config for 7zip
cmd /c "reg add `"HKEY_CURRENT_USER\Software\7-Zip\Options`" /v `"ContextMenu`" /t REG_DWORD /d `"259`" /f >nul 2>&1"
cmd /c "reg add `"HKEY_CURRENT_USER\Software\7-Zip\Options`" /v `"CascadedMenu`" /t REG_DWORD /d `"0`" /f >nul 2>&1"

# cleaner start menu shortcut path
Move-Item -Path "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\7-Zip\7-Zip File Manager.lnk" -Destination "$env:ProgramData\Microsoft\Windows\Start Menu\Programs" -Force -ErrorAction SilentlyContinue | Out-Null
Remove-Item "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\7-Zip" -Recurse -Force -ErrorAction SilentlyContinue | Out-Null

        Write-Host "C++`n"
		## explorer "https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist?view=msvc-170"

# download c++
IWR "$WinSuxReleaseUrl/vcredist2005_x86.exe" -OutFile "$WinSuxTempRoot\vcredist2005_x86.exe"
if (-not $WinSuxIsArm64 -or $WinSuxSupportsX64) { IWR "$WinSuxReleaseUrl/vcredist2005_x64.exe" -OutFile "$WinSuxTempRoot\vcredist2005_x64.exe" }
IWR "$WinSuxReleaseUrl/vcredist2008_x86.exe" -OutFile "$WinSuxTempRoot\vcredist2008_x86.exe"
if (-not $WinSuxIsArm64 -or $WinSuxSupportsX64) { IWR "$WinSuxReleaseUrl/vcredist2008_x64.exe" -OutFile "$WinSuxTempRoot\vcredist2008_x64.exe" }
IWR "$WinSuxReleaseUrl/vcredist2010_x86.exe" -OutFile "$WinSuxTempRoot\vcredist2010_x86.exe"
if (-not $WinSuxIsArm64 -or $WinSuxSupportsX64) { IWR "$WinSuxReleaseUrl/vcredist2010_x64.exe" -OutFile "$WinSuxTempRoot\vcredist2010_x64.exe" }
IWR "$WinSuxReleaseUrl/vcredist2012_x86.exe" -OutFile "$WinSuxTempRoot\vcredist2012_x86.exe"
if (-not $WinSuxIsArm64 -or $WinSuxSupportsX64) { IWR "$WinSuxReleaseUrl/vcredist2012_x64.exe" -OutFile "$WinSuxTempRoot\vcredist2012_x64.exe" }
IWR "$WinSuxReleaseUrl/vcredist2013_x86.exe" -OutFile "$WinSuxTempRoot\vcredist2013_x86.exe"
if (-not $WinSuxIsArm64 -or $WinSuxSupportsX64) { IWR "$WinSuxReleaseUrl/vcredist2013_x64.exe" -OutFile "$WinSuxTempRoot\vcredist2013_x64.exe" }
IWR "$WinSuxReleaseUrl/vcredist2015_2017_2019_2022_x86.exe" -OutFile "$WinSuxTempRoot\vcredist2015_2017_2019_2022_x86.exe"
if (-not $WinSuxIsArm64 -or $WinSuxSupportsX64) { IWR "$WinSuxReleaseUrl/vcredist2015_2017_2019_2022_x64.exe" -OutFile "$WinSuxTempRoot\vcredist2015_2017_2019_2022_x64.exe" }

# install c++
Start-Process -Wait "$WinSuxTempRoot\vcredist2005_x86.exe" -ArgumentList "/Q /C:`"msiexec /i vcredist.msi /qn /norestart`"" -WindowStyle Hidden
if (-not $WinSuxIsArm64 -or $WinSuxSupportsX64) { Start-Process -Wait "$WinSuxTempRoot\vcredist2005_x64.exe" -ArgumentList "/Q /C:`"msiexec /i vcredist.msi /qn /norestart`"" -WindowStyle Hidden }
Start-Process -Wait "$WinSuxTempRoot\vcredist2008_x86.exe" -ArgumentList "/q" -WindowStyle Hidden
if (-not $WinSuxIsArm64 -or $WinSuxSupportsX64) { Start-Process -Wait "$WinSuxTempRoot\vcredist2008_x64.exe" -ArgumentList "/q" -WindowStyle Hidden }
Start-Process -Wait "$WinSuxTempRoot\vcredist2010_x86.exe" -ArgumentList "/quiet /norestart" -WindowStyle Hidden
if (-not $WinSuxIsArm64 -or $WinSuxSupportsX64) { Start-Process -Wait "$WinSuxTempRoot\vcredist2010_x64.exe" -ArgumentList "/quiet /norestart" -WindowStyle Hidden }
Start-Process -Wait "$WinSuxTempRoot\vcredist2012_x86.exe" -ArgumentList "/quiet /norestart" -WindowStyle Hidden
if (-not $WinSuxIsArm64 -or $WinSuxSupportsX64) { Start-Process -Wait "$WinSuxTempRoot\vcredist2012_x64.exe" -ArgumentList "/quiet /norestart" -WindowStyle Hidden }
Start-Process -Wait "$WinSuxTempRoot\vcredist2013_x86.exe" -ArgumentList "/quiet /norestart" -WindowStyle Hidden
if (-not $WinSuxIsArm64 -or $WinSuxSupportsX64) { Start-Process -Wait "$WinSuxTempRoot\vcredist2013_x64.exe" -ArgumentList "/quiet /norestart" -WindowStyle Hidden }
Start-Process -Wait "$WinSuxTempRoot\vcredist2015_2017_2019_2022_x86.exe" -ArgumentList "/quiet /norestart" -WindowStyle Hidden
if (-not $WinSuxIsArm64 -or $WinSuxSupportsX64) { Start-Process -Wait "$WinSuxTempRoot\vcredist2015_2017_2019_2022_x64.exe" -ArgumentList "/quiet /norestart" -WindowStyle Hidden }

if ($WinSuxIsArm64) {
# Microsoft publishes a native ARM64 runtime for the current v14 toolset.
$VcredistArm64 = "$WinSuxTempRoot\vc_redist.arm64.exe"
IWR 'https://aka.ms/vc14/vc_redist.arm64.exe' -OutFile $VcredistArm64
Start-Process -Wait $VcredistArm64 -ArgumentList "/install /quiet /norestart" -WindowStyle Hidden
}

        Write-Host "DDU`n"
        ## explorer "https://www.wagnardsoft.com/display-driver-uninstaller-ddu"

# download ddu
IWR "$WinSuxReleaseUrl/ddu.exe" -OutFile "$WinSuxTempRoot\ddu.exe"

# extract ddu with 7zip
& $SevenZipPath x "$WinSuxTempRoot\ddu.exe" -o"$WinSuxTempRoot\ddu" -y | Out-Null

# set config for ddu
$DduConfig = @'
<?xml version="1.0" encoding="utf-8"?>
<DisplayDriverUninstaller Version="18.1.4.2">
	<Settings>
		<SelectedLanguage>en-US</SelectedLanguage>
		<RemoveMonitors>True</RemoveMonitors>
		<RemoveCrimsonCache>True</RemoveCrimsonCache>
		<RemoveAMDDirs>True</RemoveAMDDirs>
		<RemoveAudioBus>True</RemoveAudioBus>
		<RemoveAMDKMPFD>True</RemoveAMDKMPFD>
		<RemoveNvidiaDirs>True</RemoveNvidiaDirs>
		<RemovePhysX>True</RemovePhysX>
		<Remove3DTVPlay>True</Remove3DTVPlay>
		<RemoveGFE>True</RemoveGFE>
		<RemoveNVBROADCAST>True</RemoveNVBROADCAST>
		<RemoveNVCP>True</RemoveNVCP>
		<RemoveINTELCP>True</RemoveINTELCP>
		<RemoveINTELIGS>True</RemoveINTELIGS>
		<RemoveOneAPI>True</RemoveOneAPI>
		<RemoveEnduranceGaming>True</RemoveEnduranceGaming>
		<RemoveIntelNpu>True</RemoveIntelNpu>
		<RemoveAMDCP>True</RemoveAMDCP>
		<UseRoamingConfig>False</UseRoamingConfig>
		<CheckUpdates>False</CheckUpdates>
		<CreateRestorePoint>False</CreateRestorePoint>
		<SaveLogs>False</SaveLogs>
		<RemoveVulkan>True</RemoveVulkan>
		<ShowOffer>False</ShowOffer>
		<EnableSafeModeDialog>False</EnableSafeModeDialog>
		<PreventWinUpdate>True</PreventWinUpdate>
		<UsedBCD>False</UsedBCD>
		<KeepNVCPopt>False</KeepNVCPopt>
		<RememberLastChoice>False</RememberLastChoice>
		<LastSelectedGPUIndex>0</LastSelectedGPUIndex>
		<LastSelectedTypeIndex>0</LastSelectedTypeIndex>
	</Settings>
</DisplayDriverUninstaller>
'@
Set-Content -Path "$WinSuxTempRoot\ddu\Settings\Settings.xml" -Value $DduConfig -Force

# set ddu config to read only
Set-ItemProperty -Path "$WinSuxTempRoot\ddu\Settings\Settings.xml" -Name IsReadOnly -Value $true

# prevent downloads of drivers from windows update
cmd /c "reg add `"HKLM\Software\Microsoft\Windows\CurrentVersion\DriverSearching`" /v `"SearchOrderConfig`" /t REG_DWORD /d `"0`" /f >nul 2>&1"

        Write-Host "HELIUM`n"
        ## explorer "https://helium.computer"

# download helium
$HeliumInstaller = "$WinSuxTempRoot\helium.exe"
if ($WinSuxIsArm64) {
# Helium provides a native ARM64 Windows build.
IWR "https://github.com/imputnet/helium-windows/releases/download/0.17.1.1/helium_0.17.1.1_arm64-installer.exe" -OutFile $HeliumInstaller
} else {
IWR "$WinSuxReleaseUrl/helium.exe" -OutFile $HeliumInstaller
}

# install helium
Start-Process -Wait $HeliumInstaller -ArgumentList "/S" -WindowStyle Hidden

# add helium policies
cmd /c "reg add `"HKLM\SOFTWARE\Policies\Helium`" /v `"HardwareAccelerationModeEnabled`" /t REG_DWORD /d `"0`" /f >nul 2>&1"
cmd /c "reg add `"HKLM\SOFTWARE\Policies\Helium`" /v `"BackgroundModeEnabled`" /t REG_DWORD /d `"0`" /f >nul 2>&1"
cmd /c "reg add `"HKLM\SOFTWARE\Policies\Helium`" /v `"HighEfficiencyModeEnabled`" /t REG_DWORD /d `"1`" /f >nul 2>&1"

# remove logon helium
$basePath = "HKLM:\Software\Microsoft\Active Setup\Installed Components"
Get-ChildItem $basePath | ForEach-Object {
$val = (Get-ItemProperty $_.PsPath)."(default)"
if ($val -like "*Helium*") {
Remove-Item $_.PsPath -Force -ErrorAction SilentlyContinue
}
}

# remove helium services
$services = Get-Service | Where-Object { $_.Name -match 'Helium' }
foreach ($service in $services) {
cmd /c "sc stop `"$($service.Name)`" >nul 2>&1"
cmd /c "sc delete `"$($service.Name)`" >nul 2>&1"
}

# remove helium scheduled tasks
Get-ScheduledTask | Where-Object { $_.TaskName -like '*Helium*' } | Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue

# cleaner start menu shortcut path
Move-Item -Path "$env:AppData\Microsoft\Windows\Start Menu\Programs\Helium.lnk" -Destination "$env:ProgramData\Microsoft\Windows\Start Menu\Programs" -Force -ErrorAction SilentlyContinue | Out-Null

        Write-Host "DIRECTX`n"
        ## explorer "https://www.microsoft.com/en-au/download/details.aspx?id=35"

# download directx
IWR "$WinSuxReleaseUrl/directx.exe" -OutFile "$WinSuxTempRoot\directx.exe"

# extract directx with 7zip
& $SevenZipPath x "$WinSuxTempRoot\directx.exe" -o"$WinSuxTempRoot\directx" -y | Out-Null

# install directx
Start-Process -Wait "$WinSuxTempRoot\directx\DXSETUP.exe" -ArgumentList "/silent" -WindowStyle Hidden

# allow password sign in
cmd /c "reg add `"HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\PasswordLess\Device`" /v `"DevicePasswordLessBuildVersion`" /t REG_DWORD /d `"0`" /f >nul 2>&1"

# disable open terminal by default
cmd /c "reg add `"HKCU\Console\%%Startup`" /v `"DelegationConsole`" /t REG_SZ /d `"{B23D10C0-E52E-411E-9D5B-C09FDF709C7D}`" /f >nul 2>&1"
cmd /c "reg add `"HKCU\Console\%%Startup`" /v `"DelegationTerminal`" /t REG_SZ /d `"{B23D10C0-E52E-411E-9D5B-C09FDF709C7D}`" /f >nul 2>&1"

# install runonce stepone ps1 file to run in safe boot
cmd /c "reg add `"HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce`" /v `"*!stepone`" /t REG_SZ /d `"powershell.exe -nop -ep bypass -WindowStyle Maximized -f $WinSuxTempRoot\stepone.ps1`" /f >nul 2>&1"

# install runonce steptwo ps1 file to run in normal boot
cmd /c "reg add `"HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce`" /v `"!steptwo`" /t REG_SZ /d `"powershell.exe -nop -ep bypass -WindowStyle Maximized -f $WinSuxTempRoot\steptwo.ps1`" /f >nul 2>&1"

# turn on safe boot
cmd /c "bcdedit /set {current} safeboot minimal >nul 2>&1"

        Write-Host "RESTARTING`n" -ForegroundColor Red

# restart
Start-Sleep -Seconds 5
shutdown -r -t 00
