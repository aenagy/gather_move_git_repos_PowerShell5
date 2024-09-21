Param(
    [Parameter(Mandatory=$true)]
    [ValidateScript(
        {
            $foundFolders = $true
            foreach( $folder in $_ ){
                $foundFolders = $foundFolders -and ( Test-Path -Path $folder -PathType Container )
            }
            return $foundFolders
        }
    )]
    [string[]]
    $sourceFolders
    ,
    [Parameter(Mandatory=$true)]
    [ValidateScript(
        {Test-Path -Path $_ -PathType Container}
    )]
    [string]
    $destinationFolder
    ,
    [string[]]
    [ValidateScript(
        {
            $foundFolders = $true
            foreach( $folder in $_ ){
                $foundFolders = $foundFolders -and ( Test-Path -Path $folder -PathType Container )
            }
            return $foundFolders
        }
    )]
    $ignoreFolders
)

$urlSeparator = "/"
$folderPathSeparator = "\"
$sourceFolder = $null
$localSourceGitRepoFolders = $null
$localSourceGitRepoFolder = $null
$moveSourceFolder = $null
$moveDestinationFolder = $null
$configFileName = $null
$configFileContents = $null
$configFileIni = $null
$configUrl = $null
$configUrlArray = $null

if ( $sourceFolders -is [array] )
{
} elseif ( $sourceFolders.Length -gt 0 ) {
    $sourceFolders = @( $sourceFolders )
} else {
    Write-Error "ERROR: Unable to resolve input 'sourceFolders'. Aborting script."
    exit 2
}
Write-Host "Including $($sourceFolders.Length) folders."

if ( $ignoreFolders -is [array] )
{
} elseif ( $ignoreFolders.Length -gt 0 ) {
    $ignoreFolders = @( $ignoreFolders )
} else {
    $ignoreFolders = @()
}
Write-Host "Ignoring $($ignoreFolders.Length) folders."

# Automatically exlude the destination folder from the list
$localSourceGitRepoFolders = foreach( $sourceFolder in $sourceFolders ){

    Get-ChildItem -Recurse -Path $sourceFolder -Filter ".git" -ErrorAction SilentlyContinue -Force | `
    Where-Object{ $_.Fullname.IndexOf( $destinationFolder ) -eq -1 -and $destinationFolder.IndexOf( $_.FullName ) -eq -1 } | `
    ForEach-Object{
        if ( $ignoreFolders.Length -gt 0 )
        {
            $ignoreThisFolder = $false
            foreach( $ignoreFolder in $ignoreFolders )
            {
                $foundFolderInIgnoreFolder = $ignoreFolder.ToLower().IndexOf( $_.FullName.ToLower() ) -gt -1
                $foundIgnoreFolderInFolder = $_.FullName.ToLower().IndexOf( $ignoreFolder.ToLower() ) -gt -1
                if ( $foundFolderInIgnoreFolder -or $foundIgnoreFolderInFolder )
                {
                    $ignoreThisFolder = $true
                    break
                }
            }
            if ( -not $ignoreThisFolder )
            {
                # Write-Host "Including folder $($_.FullName)."
                Write-Output $_
            } else {
                Write-Host "  Ignoring folder $($_.FullName)." -ForegroundColor Red
            }
        } else {
            Write-Output $_
        }
    }
}

Write-Host "Found $($localSourceGitRepoFolders.Length) local Git repo folders to move."
Write-Host "localSourceGitRepoFolders:"
foreach( $localSourceGitRepoFolder in $localSourceGitRepoFolders ){
    Write-Host "  $($localSourceGitRepoFolder.Fullname)"
}
Write-Host ""

foreach( $localSourceGitRepoFolder in $localSourceGitRepoFolders ){

    Write-Host "----- Start: localSourceGitRepoFolder = '$($localSourceGitRepoFolder.FullName)' -----" -ForegroundColor Green
    $configFileName = Get-ChildItem -Path $localSourceGitRepoFolder.Fullname -Include "config" -Recurse | Select-Object -Property Fullname
    #Write-Host "configFileName.Fullname = '$($configFileName.FullName)'"

    $configFileContents = Get-Content -Path $configFileName.FullName
    #Write-Host "configFileContents:`n${configFileContents}"

    $configFileIni = ConvertFrom-StringData(($configFileContents | Select-String -Pattern "^\[" -NotMatch ) -join "`n")
    $configUrl = $configFileIni.url
    #Write-Host "configUrl = '$configUrl'"

    if ( $configUrl.IndexOf( "https:" ) -eq 0 ){
        $configUrlArray = $configUrl.Split( $urlSeparator )
        $sourceGitRepoFqdn  = $configUrlArray[2]
        $sourceGitRepoOwner = $configUrlArray[3]
        $sourceGitRepoName  = $configUrlArray[4]
    } elseif ( $configUrl.IndexOf( "git@" ) -eq 0 )
    {
        $configUrlArray = $configUrl.Split( "@" )[1].Replace( ":" , $urlSeparator ).Split( $urlSeparator )
        $sourceGitRepoFqdn  = $configUrlArray[0]
        $sourceGitRepoOwner = $configUrlArray[1]
        $sourceGitRepoName  = $configUrlArray[2].Replace( ".git" , "" )
    } else
    {
        Write-Error "configUrl is neither HTTPS nor SSH. Exiting."
        exit 1
    }

    $moveSourceFolder = Resolve-Path -Path "$($localSourceGitRepoFolder.FullName)\..\"
    if ( $sourceGitRepoFqdn.length -gt 0 -and $sourceGitRepoOwner.length -gt 0 -and $sourceGitRepoName.length -gt 0 )
    {
        $moveDestinationFolder = $destinationFolder + $folderPathSeparator + $sourceGitRepoFqdn + $folderPathSeparator + $sourceGitRepoOwner
    } else
    {
        Write-Error "configUrlArray          = $($configUrlArray)`nconfigUrl = '$configUrl'"
        exit 3
    }

    Write-Host "  Creating folder path '$moveDestinationFolder'."
    New-Item -Path $moveDestinationFolder -ItemType Directory -Force -OutVariable newDestinationFolderOutput
    Write-Host "  Created folder path  '$newDestinationFolderOutput'."
    Write-Host "  Move-Item -LiteralPath $moveSourceFolder -Destination $moveDestinationFolder"
                  Move-Item -LiteralPath $moveSourceFolder -Destination $moveDestinationFolder
    Write-Host "----- End  : localSourceGitRepoFolder = '$($localSourceGitRepoFolder.FullName)' -----`n" -ForegroundColor Green
}