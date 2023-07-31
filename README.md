# Get-WhoIsInformation

PowerShell script that queries domain registration and DNS information for given IPs.  It uses [ARIN](https://rdap.arin.net) and the `Resolve-DnsName` cmdlet to gather details for the specified IP and returns consolidated data as a single object.

## Examples
* Get the domain information for a single IP
```powershell
.\Get-WhoIsInformation.ps1 192.168.10.10
```

* Get the domain information for a list of IPs
```powershell
.\Get-WhoIsInformation.ps1 '192.168.10.10','10.10.20.3','172.16.30.5'
```

* Get the domain information for a list of IPs (one per line) in the file IPs.txt
```powershell
.\Get-WhoIsInformation.ps1 (Get-Content .\IPs.txt)
```

* Format the output into a table with the select values of: IP, HostName, Name, Country, Remarks
```powershell
.\Get-WhoIsInformation.ps1 (Get-Content .\ips.txt) |
    Select-Object IP,HostName,Name,Country,Remarks | 
    Format-Table -AutoSize
```
