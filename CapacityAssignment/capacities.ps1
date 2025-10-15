param(
    [Parameter(Position=0)]
    [ValidateSet("list","list-nocap","assign")]
    [string]$Mode = "list",

    [Parameter(Position=1)]
    [string]$CapacityId
)

. .\Reusable.ps1

# Helper function to show progress


fab auth login
$workspaces = fab ls -l | Convert-FixedWidthTableToObjects

switch ($Mode.ToLower()) {
    "list" {
        $workspaces | Format-Table  name, id, capacityName, capacityRegion
    }
    "list-nocap" {
        $workspaces | Where-Object { $_.capacityName -eq "N/A" } | Format-Table name, id, capacityName, capacityRegion
    }
    "assign" {
        if (-not $CapacityId) {
            Write-Error "CapacityId is required for assign mode"
            exit 1
        }

        $withoutCap = $workspaces | Where-Object { $_.capacityName -eq "N/A" }

        if (-not $withoutCap) {
            Write-Host "✅ All workspaces already have a capacity."
            return
        }

        $total = $withoutCap.Count
        $i = 0
        foreach ($w in $withoutCap) {
            $i++
            Show-Progress -Current $i -Total $total -Message $w.name

            $jsonBody = "{""capacityId"":""$CapacityId""}"
            $url = "workspaces/$($w.id)/assignToCapacity"
            fab api $url -X post -i $jsonBody | Out-Null
        }

        Write-Progress -Activity "Assigning capacity..." -Completed
        Write-Host "`n✅ Capacity assigned to all workspaces without capacity."
    }

    default {
        Write-Host "❌ Invalid mode or not yet implemented."
    }
}

