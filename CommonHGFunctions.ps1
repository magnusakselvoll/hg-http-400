param(
    [Parameter(Mandatory=$true)]
    [string]$repositoryPath,
    [string]$hgExecutable = "hg.exe"
)


function Invoke-HG
{
    param([string[]] $hgParams)

    $result = &{hg.exe --repository $repositoryPath $hgParams}

    return $result
}
