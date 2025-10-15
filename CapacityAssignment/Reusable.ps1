 #Basic Processing function
function Convert-FixedWidthTableToObjects {
    param (
        [Parameter(ValueFromPipeline = $true)]
        [string[]]$TableText
    )

    begin {
        $lines = @()
    }

    process {
        # Ensure each input is treated as a string
        $lines += $_.ToString()
    }

    end {
        # Remove empty or whitespace-only lines
        $lines = $lines | Where-Object { $_.Trim() -ne "" }

        # Validate input: expect at least 3 lines (header, separator, and at least one row)
        if ($lines.Count -lt 3) {
            Write-Host "Expected tabular output with at least 3 lines (header, separator, data). Received: $lines"
            return @()
        }

        $headerLine = $lines[0]
        $separatorLine = $lines[1]

        # Validate separator line (should be dashes and spaces only)
        if ($separatorLine -notmatch "^-{3,}") {
            Write-Host "Second line is not a valid separator. Did you forget to use `-l` with the command?"
            Write-Host $separatorLine
            Write-Host "header: $headerLine"
            return @()
        }

        # Identify column start and end positions
        $columnBounds = @()
        $inColumn = $false
        for ($i = 0; $i -lt $headerLine.Length; $i++) {
            if ($headerLine[$i] -ne ' ' -and -not $inColumn) {
                $start = $i
                $inColumn = $true
            } elseif ($headerLine[$i] -eq ' ' -and $inColumn) {
                $end = $i
                $columnBounds += ,@($start, $end)
                $inColumn = $false
            }
        }
        if ($inColumn) {
            $columnBounds += ,@($start, $headerLine.Length)
        }

        # Extract column names based on header line and boundaries
        $columns = $columnBounds | ForEach-Object {
            $start = $_[0]
            $length = $_[1] - $_[0]
            if ($start -lt $headerLine.Length) {
                $length = [Math]::Min($length, $headerLine.Length - $start)
                $headerLine.Substring($start, $length).Trim()
            } else {
                "Column$start"
            }
        }

        # Validate column parsing
        if ($columns.Count -eq 0 -or $columns.Count -ne $columnBounds.Count) {
            throw "Failed to parse columns from header. Please check the tabular alignment of the input."
        }

        # Parse data lines into objects
        $dataLines = $lines[2..($lines.Count - 1)]

        $objects = foreach ($line in $dataLines) {
            $obj = [PSCustomObject]@{}
            for ($i = 0; $i -lt $columns.Count; $i++) {
                $start = $columnBounds[$i][0]
                if ($i -lt $columnBounds.Count)                
                { 
                    if ($null -ne $columnBounds[$i + 1]) {
                        $length = ($columnBounds[$i + 1][0] - $start)
                    }
                    else
                    {
                        $length = ($separatorLine.Length - $start)                
                    }
                }
                else
                {
                    $length = ($separatorLine.Length - $start)                
                }

                if ($start -ge $line.Length) {
                    $value = ""
                } else {
                    $length = [Math]::Min($length, $line.Length - $start)                     
                    $Dirtvalue = ($line.Substring($start, $length) -replace '\p{C}', '').Trim()
                    $value = -join ($DirtValue.ToCharArray() | Where-Object { [int]$_ -ge 32 -and [int]$_ -le 126 })
                }

                $obj | Add-Member -NotePropertyName $columns[$i] -NotePropertyValue $value
            }
            $obj
        }

        return $objects
    }
} 

function Show-Progress {
    param(
        [int]$Current,
        [int]$Total,
        [string]$Message
    )
    $percent = [math]::Round(($Current / $Total) * 100)
    Write-Progress -Activity "Assigning capacity..." -Status "$percent% - $Message" -PercentComplete $percent
}