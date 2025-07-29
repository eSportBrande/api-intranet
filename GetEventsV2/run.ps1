using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Download the iCal file
$icalUrl = "$($env:ICALURL)"
$icalContent = Invoke-WebRequest -Uri $icalUrl -UseBasicParsing | Select-Object -ExpandProperty Content

# Split into lines
$lines = $icalContent -split "`r?`n"

# Parse VEVENT blocks
$events = @()
$inEvent = $false
$event = @{}

foreach ($line in $lines) {
    if ($line -eq "BEGIN:VEVENT") {
        $inEvent = $true
        $event = @{}
        continue
    }
    if ($line -eq "END:VEVENT") {
        $inEvent = $false
        # Only select required fields and parse datetimes
        $title = $event['SUMMARY']
        $start = $null
        $end = $null
        $url = $null
        $description = $null
        if ($event.ContainsKey('DTSTART')) {
            $startRaw = $event['DTSTART']
            $start = try {
                if ($startRaw.Length -eq 8) {
                    [datetime]::ParseExact($startRaw, "yyyyMMdd", $null).ToString("yyyy-MM-dd 00:00:00")
                } else {
                    [datetime]::ParseExact($startRaw, "yyyyMMdd'T'HHmmss", $null).ToString("yyyy-MM-dd HH:mm:ss")
                }
            } catch { $startRaw }
        }
        if ($event.ContainsKey('DTEND')) {
            $endRaw = $event['DTEND']
            $end = try {
                if ($endRaw.Length -eq 8) {
                    [datetime]::ParseExact($endRaw, "yyyyMMdd", $null).ToString("yyyy-MM-dd 00:00:00")
                } else {
                    [datetime]::ParseExact($endRaw, "yyyyMMdd'T'HHmmss", $null).ToString("yyyy-MM-dd HH:mm:ss")
                }
            } catch { $endRaw }
        }
        if ($event.ContainsKey('URL')) {
            $url = $event['URL']
        }
        if ($event.ContainsKey('DESCRIPTION')) {
            $description = $event['DESCRIPTION']
        }
        $events += [PSCustomObject]@{
            Titel = $title
            Start = $start
            Slut = $end
            URL = $url
            Beskrivelse = $description
        }
        continue
    }
    if ($inEvent -and $line -match "^([^:;]+)(?:;[^:]+)?:([^\r\n]*)$") {
        $key = $matches[1]
        $value = $matches[2]
        $event[$key] = $value
    }
}

# Convert to JSON and output
$EventJson = $events | ConvertTo-Json -Depth 100

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $EventJson
})