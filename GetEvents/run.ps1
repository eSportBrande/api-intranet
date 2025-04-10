using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
$EventList = @()

$a = Invoke-WebRequest -Uri "$($env:EVENTURL)"

$events = $a.Content | ConvertFrom-Json 
foreach ($event in $events) {
    if ($event.start -gt (Get-Date -Format yyyy-MM-dd) -and [datetime]$event.start -lt (Get-Date).AddDays(60) -and $event.summary -notmatch "Regnskab" -and $event.summary -notmatch "Ansøg" -and $Event.summary -notmatch "Indkald" -and $event.summary -notmatch "Ansøgning" -and $event.summary -notmatch "eSport Brande Main vs") {
        $EventObj = New-Object psobject
        $EventObj | Add-Member -MemberType NoteProperty -Name "Titel" -Value $($Event.summary)
        $EventObj | Add-Member -MemberType NoteProperty -Name "Start" -Value $($Event.start).Split("+")[0]
        $EventObj | Add-Member -MemberType NoteProperty -Name "Slut" -Value $($Event.end).Split("+")[0]
        $EventObj | Add-Member -MemberType NoteProperty -Name "URL" -Value "$($event.URL)"
        $EventList += $EventObj
    }
}

$EventJson = $EventList | ConvertTo-Json

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $EventJson
})