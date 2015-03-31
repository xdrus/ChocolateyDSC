function Get-TargetResource
{
    param (
        [Parameter(Mandatory)]
        [string]$PackageName
    )

    $ensure = ""

    $versionInfo = Get-InstalledVersion $PackageName

    if($versionInfo.count -lt 1) {
        $ensure = "Absent"
    } else {
        $ensure = "Present"
    }

    return @{
        Ensure = $ensure
        PackageName = $PackageName
        Version = $versionInfo
    }
}

function Set-TargetResource
{
    param (
        [ValidateSet("Present", "Absent")]
        [string]$Ensure = "Present",

        [Parameter(Mandatory)]
        [string]$PackageName,

        [string]$Version,

        [string]$InstallOptions,

        [string]$PackageParameters,

        [string]$Source
    )

    Write-Verbose "Running chocolatey command"

    $parameters = @("install", $PackageName, "-verbose", "-debug")

    if($Version){
        $parameters += "-version"
        $parameters += "$Version"
    }

    if($Source){
        $parameters += "-source"
        $parameters += "$Source"
    }

    if($InstallOptions){
        $parameters += "-ia"
        $parameters += "$InstallOptions"
    }

    if($PackageParameters){
        $parameters += "-packageParameters"
        $parameters += "$PackageParameters"
    }

    # Make sure the  chocolatey output is captured, used write-host :(
    $result = Select-WriteHost {& "$env:ChocolateyInstall\chocolateyinstall\chocolatey.cmd" $parameters}

    Write-Verbose "Chocolatey result: $result"
}

function Test-TargetResource
{
    param (
        [Parameter(Mandatory)]
        [string]$PackageName,

        [ValidateSet("Present", "Absent")]
        [string]$Ensure = "Present",

        [string]$Version,

        [string]$InstallOptions,

        [string]$PackageParameters,

        [string]$Source
    )

    $versionInfo = Get-InstalledVersion $PackageName

	if($versionInfo.count -lt 1)
    {
		Write-Verbose "Not found"
        return $false
    }

	Write-Verbose "found"
	return $true
}

function Get-InstalledVersion
{
    param([string]$PackageName)

    $choco = "$env:ChocolateyInstall\chocolateyinstall\chocolatey.ps1"

    # find installed version
    $versionInfo = &$choco version $PackageName

    return $versionInfo
}

# This function temporarily replaces the write-host operator
# See http://latkin.org/blog/2012/04/25/how-to-capture-or-redirect-write-host-output-in-powershell/
function Select-WriteHost
{
   [CmdletBinding(DefaultParameterSetName = 'FromPipeline')]
   param(
     [Parameter(ValueFromPipeline = $true, ParameterSetName = 'FromPipeline')]
     [object] $InputObject,

     [Parameter(Mandatory = $true, ParameterSetName = 'FromScriptblock', Position = 0)]
     [ScriptBlock] $ScriptBlock,

     [switch] $Quiet
   )

   begin
   {
     function Cleanup
     {
       # clear out our proxy version of write-host
       remove-item function:write-host -ea 0
     }

     function ReplaceWriteHost([switch] $Quiet, [string] $Scope)
     {
         # create a proxy for write-host
         $metaData = New-Object System.Management.Automation.CommandMetaData (Get-Command 'Microsoft.PowerShell.Utility\Write-Host')
         $proxy = [System.Management.Automation.ProxyCommand]::create($metaData)

         # change its behavior
         $content = if($quiet)
                    {
                       # in quiet mode, whack the entire function body, simply pass input directly to the pipeline
                       $proxy -replace '(?s)\bbegin\b.+', '$Object'
                    }
                    else
                    {
                       # in noisy mode, pass input to the pipeline, but allow real write-host to process as well
                       $proxy -replace '($steppablePipeline.Process)', '$Object; $1'
                    }

         # load our version into the specified scope
         Invoke-Expression "function ${scope}:Write-Host { $content }"
     }

     Cleanup

     # if we are running at the end of a pipeline, need to immediately inject our version
     #    into global scope, so that everybody else in the pipeline uses it.
     #    This works great, but dangerous if we don't clean up properly.
     if($pscmdlet.ParameterSetName -eq 'FromPipeline')
     {
        ReplaceWriteHost -Quiet:$quiet -Scope 'global'
     }
   }

   process
   {
      # if a scriptblock was passed to us, then we can declare
      #   our version as local scope and let the runtime take it out
      #   of scope for us.  Much safer, but it won't work in the pipeline scenario.
      #   The scriptblock will inherit our version automatically as it's in a child scope.
      if($pscmdlet.ParameterSetName -eq 'FromScriptBlock')
      {
        . ReplaceWriteHost -Quiet:$quiet -Scope 'local'
        & $scriptblock
      }
      else
      {
         # in pipeline scenario, just pass input along
         $InputObject
      }
   }

   end
   {
      Cleanup
   }
}

Export-ModuleMember -Function *-TargetResource
