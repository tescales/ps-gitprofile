<#
##cribbed from https://gist.github.com/chrisbrownie/f20cb4508975fb7fb5da145d3d38024a 
.Synopsis
   This function will download a Github Repository without using Git
.DESCRIPTION
.EXAMPLE

#>
function Get-GitFiles {
    Param(
        [string]$Owner = ($env:gitprofile).split('/')[0],
        [string]$Repository = ($env:gitprofile).split('/')[1],
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$DestinationPath,
        [string]$ExcludePath = ""
    )

    Write-Verbose "Loading $file from $owner/$repository..."

    if (-not (Test-Path $DestinationPath)) {
        # Destination path does not exist, let's create it
        try {
            New-Item -Path $DestinationPath -ItemType Directory -ErrorAction Stop | Out-Null
        }
        catch {
            throw "Could not create path '$DestinationPath'!"
        }
    }

    $baseUri = "https://api.github.com/"
    $paths = "repos/$Owner/$Repository/contents/$Path"
    $wr = Invoke-WebRequest -usebasicparsing -Uri $($baseuri + $paths)
    $objects = $wr.Content | ConvertFrom-Json
    $files = $objects | Where-Object { $_.type -eq "file" } | Select-Object -exp download_url
    $directories = $objects | Where-Object { $_.type -eq "dir" }
        
    $directories | ForEach-Object { 
        #if ($_.name -ne $ExcludePath) {
        Get-GitFiles -Owner $Owner -Repository $Repository -Path $_.path -DestinationPath (join-path $DestinationPath -childpath $_.name)
        #}
    }
    
    foreach ($file in $files) {
        $fileDestination = Join-Path $DestinationPath (Split-Path $file -Leaf)
        if (test-path $fileDestination) { continue }
        else {
            try {
                write-host "Saving file $file to $fileDestination..."
                Invoke-WebRequest -usebasicparsing -Uri $file -OutFile $fileDestination -ErrorAction Stop 
            }
            catch {
                throw "Unable to download '$($file.path)'"
            }
        }
    }
    #future use
    if (Get-Command -ErrorAction SilentlyContinue git) { $global:gitInstalled = $true }

    #git clone subdirs cribbed from https://en.terminalroot.com.br/how-to-clone-only-a-subdirectory-with-git-or-svn/
    #if ($global:gitInstalled) { 
    #     if (test-path "(split-path ($DestinationPath) -Parent)/.git") {
    #         & git pull origin master
    #     }
    #     else {
    #         & cd (split-path ($DestinationPath) -Parent)
    #         & git init
    #         & git remote add -f origin https://github.com/$Owner/$Repository
    #         & git config core.sparseCheckout true
    #         & echo $Path >> .git/info/sparse-checkout
    #         & echo $ExcludePath >> .git/info/sparse-checkout
    #         & git pull origin master
    #     }
    #} else {
}