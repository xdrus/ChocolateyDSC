function Get-TargetResource
{
    param (
        [ValidateSet("Present", "Absent")]
        [string]$Ensure = "Present",

        [Parameter(Mandatory)]
        [string]$PackageName,

        [string]$Version
    )
}

function Set-TargetResource
{
    param (
        [ValidateSet("Present", "Absent")]
        [string]$Ensure = "Present",

        [Parameter(Mandatory)]
        [string]$PackageName,

        [string]$Version
    )

    $choco = "c:\ProgramData\chocolatey\chocolateyinstall\chocolatey.ps1"
    $result = &$choco install $PackageName

}

function Test-TargetResource
{
    param (
        [Parameter(Mandatory)]
        [string]$PackageName,

        [ValidateSet("Present", "Absent")]
        [string]$Ensure = "Present",

        [string]$Version
    )
    $choco = "c:\ProgramData\chocolatey\chocolateyinstall\chocolatey.ps1"

    # find installed version
    $versionInfo = &$choco version $PackageName

	if($versionInfo.count -lt 1)
    {
		Write-Verbose "Not found"
        return $false
    }
	
	Write-Verbose "found"
	return $true
}

Export-ModuleMember -Function *-TargetResource