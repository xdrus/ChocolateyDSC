Configuration SampleConfig 
{
    param ($MachineName="localhost")

    Node $MachineName
    {
        cChocolateyPackage Nunit
        {
            Ensure = "Present"
            PackageName = "nunit"
        }
    }
}

& SampleConfig -OutputPath "C:\projects\output\SampleConfig"

Start-DscConfiguration -Path "C:\projects\output\SampleConfig" -Verbose -Wait