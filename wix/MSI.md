## Usage Instructions

1. Preparation:

   - Ensure Wix Toolset 6 is installed: `dotnet tool install --global wix --version 6.0.0`
   - Create a simple License.rtf file as the license agreement

2. Building the MSI:

   - For x64 architecture: `dotnet build -c Release -p:Platform=x64`
   - For ARM64 architecture: `dotnet build -c Release -p:Platform=arm64`

3. Installation Options:

   - User scope installation: `winget install nushell.msi --scope user`
   - Machine scope installation: `winget install nushell.msi --scope machine` (requires administrator privileges)

   # For per-user Installation with `msiexec`
   `msiexec /i bin\x64\Release\nushell-x64.msi MSIINSTALLPERUSER=1 ALLUSERS=""`

   # For per-machine Installation with `msiexec` (requires admin privileges)
   `msiexec /i bin\x64\Release\nushell-x64.msi ALLUSERS=1 MSIINSTALLPERUSER=""`

## Feature Description

1. Dual Installation Scope: Supports both user and machine scope installation
2. `PATH` Environment Variable: Automatically adds the installation directory to the `PATH` ENV var
3. Upgrade Retention: Retains the original installation path during upgrades
4. Multi-architecture Support: Supports `x86_64` and `ARM64` architectures
5. System Compatibility: Compatible with Windows 7/10/11

## REF

- https://docs.firegiant.com/quick-start/
