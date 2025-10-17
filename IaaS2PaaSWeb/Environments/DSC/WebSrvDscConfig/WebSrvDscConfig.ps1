Configuration Main
{

  Param ( [string] $nodeName )

  Import-DscResource -ModuleName PSDesiredStateConfiguration
  Import-DscResource -ModuleName cChoco

  Node $nodeName
  {
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
        $currentProtocols = [System.Net.ServicePointManager]::SecurityProtocol
        $tls12            = [System.Net.SecurityProtocolType]::Tls12
        $tls11            = [System.Net.SecurityProtocolType]::Tls11
        $tls10            = [System.Net.SecurityProtocolType]::Tls
        [System.Net.ServicePointManager]::SecurityProtocol = $currentProtocols -bor $tls12 -bor $tls11 -bor $tls10
        Write-Verbose "DownloadWebDeploy: Enabled TLS flags $([System.Net.ServicePointManager]::SecurityProtocol)"

        if (-not (Test-Path (Split-Path $dest))) {
          New-Item -ItemType Directory -Path (Split-Path $dest) -Force | Out-Null
        }

        try {
          Write-Verbose "DownloadWebDeploy: Attempting Invoke-WebRequest from $source"
          Invoke-WebRequest -Uri $source -OutFile $dest -UseBasicParsing -ErrorAction Stop
          Write-Verbose "DownloadWebDeploy: Invoke-WebRequest succeeded"
        }
        catch {
          Write-Verbose "DownloadWebDeploy: Invoke-WebRequest failed with $_. Start BITS fallback."
          if (Test-Path $dest) { Remove-Item $dest -Force }
          try {
            Start-BitsTransfer -Source $source -Destination $dest -ErrorAction Stop
            Write-Verbose "DownloadWebDeploy: BITS transfer succeeded"
          }
          catch {
            throw "DownloadWebDeploy: Unable to download WebDeploy via Invoke-WebRequest or BITS. Last error: $($_.Exception.Message)"
          }
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
  cChocoPackageInstaller googlechrome
  {            
    Name = "googlechrome"
    DependsOn = "[cChocoInstaller]installChoco"
  }
  cChocoPackageInstaller dotnet48
  {
    Name = "dotnetfx"
    DependsOn = "[cChocoInstaller]installChoco"
  }
  cChocoPackageInstaller webpi
  {            
    Name = "webpi"
    DependsOn = "[cChocoPackageInstaller]dotnet48"
  }
  }
}