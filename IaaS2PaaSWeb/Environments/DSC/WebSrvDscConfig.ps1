Configuration Main
{

  Param ( [string] $nodeName )

  Import-DscResource -ModuleName PSDesiredStateConfiguration
  Import-DscResource -ModuleName cChoco

  Node $nodeName
  {
    LocalConfigurationManager {
      RebootNodeIfNeeded = $true
      ActionAfterReboot  = "ContinueConfiguration"
    }

    WindowsFeature WebServerRole {
      Name   = "Web-Server"
      Ensure = "Present"
    }
    WindowsFeature WebManagementConsole {
      Name   = "Web-Mgmt-Console"
      Ensure = "Present"
    }
    WindowsFeature WebManagementService {
      Name   = "Web-Mgmt-Service"
      Ensure = "Present"
    }
    WindowsFeature ASPNet45 {
      Name   = "Web-Asp-Net45"
      Ensure = "Present"
    }
    WindowsFeature HTTPRedirection {
      Name   = "Web-Http-Redirect"
      Ensure = "Present"
    }
    WindowsFeature CustomLogging {
      Name   = "Web-Custom-Logging"
      Ensure = "Present"
    }
    WindowsFeature LogginTools {
      Name   = "Web-Log-Libraries"
      Ensure = "Present"
    }
    WindowsFeature RequestMonitor {
      Name   = "Web-Request-Monitor"
      Ensure = "Present"
    }
    WindowsFeature Tracing {
      Name   = "Web-Http-Tracing"
      Ensure = "Present"
    }
    WindowsFeature BasicAuthentication {
      Name   = "Web-Basic-Auth"
      Ensure = "Present"
    }
    WindowsFeature WindowsAuthentication {
      Name   = "Web-Windows-Auth"
      Ensure = "Present"
    }
    WindowsFeature ApplicationInitialization {
      Name   = "Web-AppInit"
      Ensure = "Present"
    }
    Script DownloadWebDeploy {
      TestScript = {
        Test-Path "C:\WindowsAzure\WebDeploy_amd64_en-US.msi"
      }
      SetScript  = {
        $source = "https://download.microsoft.com/download/0/1/D/01DC28EA-638C-4A22-A57B-4CEF97755C6C/WebDeploy_amd64_en-US.msi"
        $dest = "C:\WindowsAzure\WebDeploy_amd64_en-US.msi"

        # Ensure modern TLS versions are available; keep existing flags so older endpoints still work
        $currentProtocols = [System.Net.ServicePointManager]::SecurityProtocol
        $tls12          = [System.Net.SecurityProtocolType]::Tls12
        $tls11          = [System.Net.SecurityProtocolType]::Tls11
        $tls10          = [System.Net.SecurityProtocolType]::Tls
        [System.Net.ServicePointManager]::SecurityProtocol = $currentProtocols -bor $tls12 -bor $tls11 -bor $tls10

        if (-not (Test-Path (Split-Path $dest))) {
          New-Item -ItemType Directory -Path (Split-Path $dest) -Force | Out-Null
        }

        try {
          Invoke-WebRequest -Uri $source -OutFile $dest -UseBasicParsing -ErrorAction Stop
        }
        catch {
          # Fallback to BITS transfer to handle transient HTTPS issues
          if (Test-Path $dest) { Remove-Item $dest -Force }
          Start-BitsTransfer -Source $source -Destination $dest -ErrorAction Stop
        }
      }
      GetScript  = {@{Result = "DownloadWebDeploy"}}
      DependsOn  = "[WindowsFeature]WebServerRole"
    }
    Package InstallWebDeploy {
      Ensure    = "Present"  
      Path      = "C:\WindowsAzure\WebDeploy_amd64_en-US.msi"
      Name      = "Microsoft Web Deploy 3.6"
      ProductId = "{6773A61D-755B-4F74-95CC-97920E45E696}"
      Arguments = "ADDLOCAL=ALL"
      DependsOn = "[Script]DownloadWebDeploy"
    }
    Service StartWebDeploy {                    
      Name        = "WMSVC"
      StartupType = "Automatic"
      State       = "Running"
      DependsOn   = "[Package]InstallWebDeploy"
    }
    cChocoInstaller installChoco
    { 
      InstallDir = "C:\choco" 
    }
    cChocoPackageInstaller dotnet48
    {
      Name      = "dotnetfx"
      DependsOn = "[cChocoInstaller]installChoco"
    }
    cChocoPackageInstaller googlechrome
    {            
      Name      = "googlechrome"
      DependsOn = "[cChocoPackageInstaller]dotnet48"
    }
    cChocoPackageInstaller webpi
    {            
      Name      = "webpi"
      DependsOn = "[cChocoPackageInstaller]dotnet48"
    }
  }
}