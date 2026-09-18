# WinSux ARM64
- ARM64-aware Windows one click guide for power users

# Requirements
- Windows 10/11 Home/Pro/LTSC/IoT/Server
- Windows on ARM64 is supported; Windows 11 is required for x64 emulation
- Online access

# ARM64 support
- Native ARM64 installers are used for 7-Zip, the current Visual C++ runtime, and Helium.
- Legacy x86 runtimes remain enabled for older applications.
- x64 runtimes are installed only when the operating system supports x64 emulation.
- The timer-resolution service is compiled as AnyCPU and uses the first available .NET Framework compiler.

# IWR
- Paste below code into an elevated Administrator PowerShell/Terminal window
```
iwr https://github.com/cyroz1/WinSux-arm64/raw/refs/heads/main/WinSux/winsux.ps1 -useb | iex
```
