param(
    [Parameter(Position = 0)]
    [ValidateSet("list","list-noadmin","set-admin")]
    [string]$Mode = "list-noadmin",

    [Parameter(Position = 1)]
    [string]$AdminGroupName = "PowerBIAdmins",

    [Parameter(Position = 2)]
    [string]$AdminGroupId
)

. .\Reusable.ps1  # Load Show-Progress, fixed-width parser, etc.

function Get-WorkspacePermissions {
    param(
        [Parameter(Mandatory=$true)]
        [string]$WorkspaceName
    )

    try {
        # Capture raw output (stdout + stderr) because fab sometimes writes warnings to stderr
        $raw = (fab acl ls $WorkspaceName -l 2>&1)

        if (-not $raw) { return @() }

        # Normalize to array of trimmed, non-empty lines
        $lines = if ($raw -is [string]) { $raw -split "`r?`n" } else { @($raw) }
        $lines = $lines | ForEach-Object { $_.ToString().Trim() }

        # Drop leading empty lines
        while ($lines.Count -gt 0 -and [string]::IsNullOrWhiteSpace($lines[0])) {
            $lines = $lines | Select-Object -Skip 1
        }

        if ($lines.Count -eq 0) { return @() }

        # If the first non-empty line is a Fabric admin-role warning, skip it
        if ($lines[0] -match '(?i)requires fabric admin role' -or $lines[0].StartsWith('!')) {
            $lines = $lines | Select-Object -Skip 1
        }

        # Drop any additional leading empty lines that might remain
        while ($lines.Count -gt 0 -and [string]::IsNullOrWhiteSpace($lines[0])) {
            $lines = $lines | Select-Object -Skip 1
        }

        if (-not $lines) { return @() }

        # Convert the remaining fixed-width table lines into objects
        try {
            $permObjects = $lines | Convert-FixedWidthTableToObjects
            return $permObjects ? $permObjects : @()
        } catch {
            Write-Warning "Failed to parse permissions table for '$WorkspaceName': $_"
            return @()
        }
    } catch {
        Write-Warning "Error reading ACL for '$WorkspaceName': $_"
        return @()
    }
}

function Get-WorkspacesWithoutAdmin {
    param(
        [Parameter(Mandatory=$true)]
        [array]$Workspaces,
        [Parameter(Mandatory=$true)]
        [string]$AdminGroupName
    )

    $withoutAdmin = @()
    $total = $Workspaces.Count
    $i = 0

    foreach ($w in $Workspaces) {
        $i++
        Show-Progress -Activity "Checking workspace permissions..." -Current $i -Total $total -Status $w.name

        $permissions = Get-WorkspacePermissions -WorkspaceName $w.name

        $hasAdmin = $false
        if ($permissions) {
            $hasAdmin = ($permissions | Where-Object { $_.identity -eq $AdminGroupName })
        }

        if (-not $hasAdmin) {
            $withoutAdmin += $w
        }
    }

    Write-Progress -Activity "Checking workspace permissions..." -Completed
    return $withoutAdmin
}

fab auth login
$workspaces = fab ls -l | Convert-FixedWidthTableToObjects


# Prepare switch structure
switch ($Mode.ToLower()) {
    "list" {
        Write-Host "`n=== All Workspaces ==="
        $workspaces | Format-Table name, id, capacityName, capacityRegion
    }
    "list-noadmin" {
        Write-Host "`n=== Workspaces missing admin group ==="
        $withoutAdmin = Get-WorkspacesWithoutAdmin -Workspaces $workspaces -AdminGroupName $AdminGroupName

        if (-not $withoutAdmin) {
            Write-Host "✅ All workspaces already have '$AdminGroupName' permission."
        } else {
            Write-Host "`n=== Workspaces without '$AdminGroupName' permission ==="
            $withoutAdmin | Format-Table name, id, capacityName, capacityRegion
        }
    }
    "set-admin" {
        if (-not $AdminGroupId) {
            Write-Error "❌ AdminGroupId is required in 'set-admin' mode."
            exit 1
        }

        Write-Host "`n=== Scanning & Setting '$AdminGroupName' admin permission ==="

        # Step 1: Identify workspaces missing the Azure admin group
        $withoutAdmin = Get-WorkspacesWithoutAdmin -Workspaces $workspaces -AdminGroupName $AdminGroupName

        # Step 2: Stop if everything is already compliant
        if (-not $withoutAdmin -or $withoutAdmin.Count -eq 0) {
            Write-Host "✅ All workspaces already have '$AdminGroupName' permission."
            return
        }

        # Step 3: Loop through missing workspaces and assign permissions
        $failed = @()
        $total = $withoutAdmin.Count
        $i = 0

        foreach ($w in $withoutAdmin) {
            $i++
            Show-Progress -Activity "Setting admin permissions..." -Current $i -Total $total -Status $w.name

            # Apply admin permission using Fabric CLI
            $out = (fab acl set "$($w.name)" -I $AdminGroupId -R admin -f 2>&1)
            $outText = -join ($out)

            # Track failures for visibility
            if ($outText -match '(?i)error' -or $LASTEXITCODE -ne 0) {
                $failed += [PSCustomObject]@{ Workspace = $w.name; Error = $outText }
                Write-Host "`n⚠️ Failed to set admin for $($w.name): $outText"
            }
        }

        Write-Progress -Activity "Setting admin permissions..." -Completed

        # Step 4: Final result summary
        if ($failed.Count -gt 0) {
            Write-Host "`n❌ Some assignments failed:"
            $failed | Format-Table -AutoSize
        } else {
            Write-Host "`n✅ Admin permission successfully applied to all missing workspaces."
        }
    }
    default {
        Write-Error "❌ Invalid mode. Use one of: list | list-noadmin | set-admin"
        exit 1
    }
}