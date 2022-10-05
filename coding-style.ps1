param(
     [Parameter()]
     [string]$Delivery,
 
     [Parameter()]
     [string]$Reports
 )
function readme {
    Write-Output ""
    Write-Output "Usage: coding-style.ps1  DELIVERY_DIR REPORTS_DIR"
    Write-Output "       DELIVERY_DIR      Should be the directory where your project files are"
    Write-Output "       REPORTS_DIR       Should be the directory where we output the reports"
    Write-Output "                         Take note that existing reports will be overriden"
    Write-Output ""
}

if($PSBoundParameters.ContainsKey('Delivery') -eq $True -and $PSBoundParameters.ContainsKey('Reports') -eq $True) {
    $resolveddelivery = Resolve-Path $Delivery | Select-Object -ExpandProperty Path
    $resolvedreports = Resolve-Path $Reports | Select-Object -ExpandProperty Path
    $exportfile = "${resolvedreports}\coding-style-reports.log"

    ## Remove existing report
    if (Test-Path -Path $exportfile -PathType Leaf) {
        Remove-Item -Path $exportfile
    }

    ## Pull new version of docker image and clean olds
    docker pull ghcr.io/epitech/coding-style-checker:latest
    docker image prune -f

    ## Generate reports
    docker run --rm -it -v ${resolveddelivery}:/mnt/delivery -v ${resolvedreports}:/mnt/reports ghcr.io/epitech/coding-style-checker "/mnt/delivery" "/mnt/reports"
    if (Test-Path -Path $exportfile -PathType Leaf) {
        $filecontent = Get-Content -Path $exportfile
        $errorscount = $filecontent.Length
        $majorerrors = ($filecontent | select-string -pattern ": MAJOR:").length
        $minorerrors = ($filecontent | select-string -pattern ": MINOR:").length
        $infoerrors = ($filecontent | select-string -pattern ": INFO:").length

        Write-Output "${errorscount} coding style error(s) reported in $exportfile, ${majorerrors} major, ${minorerrors} minor, ${infoerrors} info"
    }
} else {
    readme
}
