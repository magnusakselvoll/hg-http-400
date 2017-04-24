param(
    [Parameter(Mandatory=$true)]
    [string]$repositoryPath,
    [string]$targetBranch = ".graveyard",
    [int]$maxHeadsToClose = 10,
    [string]$hgExecutable = "hg.exe",
    [bool]$disablePushPull = $false
)

. .\CommonHGFunctions.ps1 $repositoryPath $hgExecutable


function Close-HGBranch
{
    param($logObject)

    Write-Host "Closing changeset " $logObject.changeset

    Invoke-HG "update", "--clean", "--rev", $targetBranch
    Invoke-HG "merge", "--rev", $logObject.changeset, "--tool", ":local"
    Invoke-HG "revert", "--all", "--rev", $targetBranch
    Invoke-HG "commit", "--message", "Eliminating closed head $($logObject.changeset) by merging to $targetBranch"
}

$logObjects = .\Get-HGClosedHeads.ps1 -repositoryPath $repositoryPath -hgExecutable $hgExecutable -disablePull $disablePushPull

$headsClosed = 0
foreach ($logObject in $logObjects)
{
    if ($headsClosed -ge $maxHeadsToClose)
    {
        break
    }

    Close-HGBranch $logObject
    $headsClosed = $headsClosed + 1

    Write-Host
    Write-Host "*** $headsClosed closed out of a maximum of $maxHeadsToClose ***"
    Write-Host
}

Write-Host "$headsClosed heads closed"

if (-not $disablePushPull)
{
    Write-Host
    Invoke-HG "push"
}
