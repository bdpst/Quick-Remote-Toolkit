[CmdletBinding()]
param(
    [string]$OutputPath,
    [string]$SearchBase,
    [int]$InactiveDays = 180,
    [switch]$IncludeDisabled,
    [switch]$NoDnsResolve
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $scriptDirectory = if ([string]::IsNullOrWhiteSpace($PSScriptRoot)) {
        Split-Path -Parent $MyInvocation.MyCommand.Path
    } else {
        $PSScriptRoot
    }

    $OutputPath = Join-Path $scriptDirectory 'QuickRemoteToolkit.clients.csv'
}

function Convert-FileTimeToDateTime {
    param([object]$Value)

    if ($null -eq $Value) {
        return $null
    }

    try {
        $fileTime = [Int64]$Value
        if ($fileTime -le 0) {
            return $null
        }
        return [DateTime]::FromFileTime($fileTime)
    } catch {
        return $null
    }
}

function Get-DirectoryValue {
    param(
        [System.DirectoryServices.SearchResult]$Result,
        [string]$Name
    )

    if (-not $Result.Properties.Contains($Name) -or $Result.Properties[$Name].Count -eq 0) {
        return $null
    }

    return [string]$Result.Properties[$Name][0]
}

function Resolve-ClientIPv4 {
    param(
        [string]$DnsName,
        [string]$ComputerName
    )

    if ($NoDnsResolve) {
        return '-'
    }

    foreach ($name in @($DnsName, $ComputerName)) {
        if ([string]::IsNullOrWhiteSpace($name)) {
            continue
        }

        try {
            $address = [System.Net.Dns]::GetHostAddresses($name) |
                Where-Object { $_.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork } |
                Select-Object -First 1

            if ($address) {
                return $address.IPAddressToString
            }
        } catch {
            continue
        }
    }

    return '-'
}

function Escape-CsvField {
    param([string]$Value)

    if ($null -eq $Value) {
        return ''
    }

    return ($Value -replace ';', ',' -replace "`r|`n", ' ').Trim()
}

try {
    $root = if ([string]::IsNullOrWhiteSpace($SearchBase)) {
        [ADSI]'LDAP://RootDSE'
    } else {
        $null
    }

    $ldapPath = if ([string]::IsNullOrWhiteSpace($SearchBase)) {
        'LDAP://' + [string]$root.defaultNamingContext
    } else {
        'LDAP://' + $SearchBase
    }

    $directoryEntry = [System.DirectoryServices.DirectoryEntry]::new($ldapPath)
    $searcher = [System.DirectoryServices.DirectorySearcher]::new($directoryEntry)
    $searcher.PageSize = 1000
    $searcher.SearchScope = [System.DirectoryServices.SearchScope]::Subtree

    $disabledFilter = if ($IncludeDisabled) {
        ''
    } else {
        '(!(userAccountControl:1.2.840.113556.1.4.803:=2))'
    }

    $searcher.Filter = "(&(objectCategory=computer)$disabledFilter)"

    foreach ($property in @(
        'name',
        'dnshostname',
        'lastlogontimestamp'
    )) {
        [void]$searcher.PropertiesToLoad.Add($property)
    }

    $cutoff = if ($InactiveDays -gt 0) {
        (Get-Date).AddDays(-1 * $InactiveDays)
    } else {
        $null
    }

    $computers = foreach ($result in $searcher.FindAll()) {
        $name = Get-DirectoryValue -Result $result -Name 'name'
        if ([string]::IsNullOrWhiteSpace($name)) {
            continue
        }

        $lastLogon = Convert-FileTimeToDateTime (Get-DirectoryValue -Result $result -Name 'lastlogontimestamp')
        if ($cutoff -and $lastLogon -and $lastLogon -lt $cutoff) {
            continue
        }

        $dnsName = Get-DirectoryValue -Result $result -Name 'dnshostname'
        $ip = Resolve-ClientIPv4 -DnsName $dnsName -ComputerName $name

        [pscustomobject]@{
            Computer = $name
            IP = $ip
        }
    }

    $rows = @($computers | Sort-Object Computer)
    if ($rows.Count -eq 0) {
        throw 'Active Directory returned no computer objects for the selected filter.'
    }

    $lines = [System.Collections.Generic.List[string]]::new()
    [void]$lines.Add('number;computer;ip')

    $number = 1
    foreach ($row in $rows) {
        [void]$lines.Add(('{0};{1};{2}' -f
            $number,
            (Escape-CsvField $row.Computer),
            (Escape-CsvField $row.IP)
        ))
        $number++
    }

    $outputDirectory = Split-Path -Parent $OutputPath
    if (-not [string]::IsNullOrWhiteSpace($outputDirectory) -and -not (Test-Path -LiteralPath $outputDirectory)) {
        New-Item -ItemType Directory -Path $outputDirectory | Out-Null
    }

    $content = ($lines -join "`r`n") + "`r`n"
    [System.IO.File]::WriteAllText($OutputPath, $content, [System.Text.UTF8Encoding]::new($false))

    Write-Host "Saved $($rows.Count) clients to $OutputPath"
    exit 0
} catch {
    Write-Error $_.Exception.Message
    exit 1
}
