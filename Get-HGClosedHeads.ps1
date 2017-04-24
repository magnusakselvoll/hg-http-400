param(
    [Parameter(Mandatory=$true)]
    [string]$repositoryPath,
    [string]$hgExecutable = "hg.exe",
    [bool]$disablePull = $false
)

. .\CommonHGFunctions.ps1 $repositoryPath $hgExecutable

function ConvertTo-LogObject
{
    param([string[]] $outputLines)

    $logObjects = @()
    $currentObject = $null

    foreach($line in $outputLines)
    {
        if (-not $line)
        {
            if ($currentObject)
            {
                $logObjects += $currentObject;
                $currentObject = $null
            }
        }
        else 
        {
            if (-not $currentObject)
            {
                $currentObject = New-Object System.Object
            }

            $name, $value = $line -split ':', 2

            $name = $name.Trim()
            $value = $value.Trim()

            if ($name)
            {
                $currentObject | Add-Member -MemberType NoteProperty -Name $name -Value $value
            }
        }
    }

    if ($currentObject)
    {
        $logObjects += $currentObject;
        $currentObject = $null
    }
    

    return $logObjects
}

if (-not $disablePull)
{
    Invoke-HG "pull"
    Write-Host
}

$hgLog = Invoke-HG "log" , "-r", "heads(0:tip) and closed()"

$logObjects = ConvertTo-LogObject $hgLog
Write-Host $logObjects.Count " closed heads found"

Write-Output $logObjects