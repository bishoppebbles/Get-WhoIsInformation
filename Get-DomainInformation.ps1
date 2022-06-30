<#
.SYNOPSIS
    Queries domain registration and DNS information for given IPs
.DESCRIPTION
    Uses https://rdap.arin.net and the Resolve-DnsName cmdlet to gather details for the specified IP and returns consolidated data as a single object
.PARAMETER IPAddress
    The IP address(es) to query for domain registration and DNS information
.EXAMPLE
    .\Get-DomainInformation.ps1 192.168.10.10

    Get the domain information for a single IP
.EXAMPLE
    .\Get-DomainInformation.ps1 '192.168.10.10','10.10.20.3','172.16.30.5'

    Get the domain information for a list of IPs
.EXAMPLE
    .\Get-DomainInformation.ps1 (Get-Content .\IPs.txt)

    Get the domain information for a list of IPs (one per line) in the file IPs.txt
.EXAMPLE
    .\Get-DomainInformation.ps1 (Get-Content .\ips.txt) | 
        Select-Object IP,HostName,Name,Country,Remarks | 
        Format-Table -AutoSize

    Format the output into a table with the select values of: IP, HostName, Name, Country, Remarks
.NOTES
    The Get-WhoIs function was sourced from the PowerShell Gallery, including the IPv4 validation code
    
    https://www.powershellgallery.com/packages/PSScriptTools/2.9.0/Content/functions%5CGet-WhoIs.ps1

    Version 1.0.0
    Sam Pursglove
    Last modified: 30 June 2022
#>

[CmdletBinding()]
Param (
    [Parameter(Position = 0, 
        Mandatory=$True, 
        ValueFromPipeline=$False, 
        HelpMessage='IP address(es) to query for domain registry information')]
    [ValidateNotNullOrEmpty()]
    [ValidatePattern("^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$")]
    [ValidateScript({
            #verify each octet is valid to simplify the regex
            $test = ($_.split(".")).where({[int]$_ -gt 255})
            if ($test) {
                Throw "$_ does not appear to be a valid IPv4 address"
                $false
            } else {
                $true
            }
    })]
    $IPAddress
 )


<#
# Get-WhoIs function code sourced from the PowerShell Gallery with some modifications
#>

Function Get-WhoIs {
    [cmdletbinding()]
    [OutputType("WhoIsResult")]
    Param (
        [parameter(Position = 0,
            HelpMessage = "Enter an IPV4 address to lookup with WhoIs",
            ValueFromPipeline=$True)]
        [String]$IPAddress
    )

    Begin {
        $baseURL = 'https://rdap.arin.net/registry'             
        $header  = @{"Accept" = "application/json"}
    } #begin

    Process {
        $url = "$baseUrl/ip/$ipaddress"
        #Write-Output $url # prints the build URL string

        Try {
            $r = Invoke-RestMethod $url -Headers $header -ErrorAction SilentlyContinue
            Write-verbose ($r.net | Out-String)
        }
        Catch {
            $errMsg = "Sorry. There was an error retrieving WhoIs information for $IPAddress. $($_.exception.message)"
            $host.ui.WriteErrorLine($errMsg)
        }

        $resolveDNS = (Resolve-DnsName $ipaddress -ErrorAction SilentlyContinue)

        if ($r) {
            Write-Verbose "Creating result"
            [pscustomobject]@{
                PSTypeName   = "WhoIsResult"
                IP           = $ipaddress
                ReverseDNS   = $resolveDNS.Name
                HostName     = $resolveDNS.NameHost
                Name         = $r.name
                Type         = $r.type
                StartAddress = $r.startAddress
                EndAddress   = $r.endAddress
                TTL          = $resolveDNS.TTL
                Country      = $r.country
                Remarks      = $r.remarks | ForEach-Object {"$($_.description)"}
                Events       = $r.events | ForEach-Object {"$($_.eventDate): $($_.eventAction)"}
                Entities     = $r.entities | ForEach-Object {"$($_.roles): $($_.handle)"}
                Links        = $r.links | ForEach-Object {"$($_.rel): $($_.href)"}
                Notices      = $r.notices | ForEach-Object {"$($_.title): $($_.description)"}
            }
        } #If $r
    } #Process

    End {
        Write-Verbose "Ending $($MyInvocation.Mycommand)"
    } #end
}

$IPAddress | Get-WhoIs