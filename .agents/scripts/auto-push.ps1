$ErrorActionPreference = "Stop"

function Reply {
    param([string]$Reason = "")
    $result = @{ decision = "allow" }
    if ($Reason) { $result.reason = $Reason }
    $result | ConvertTo-Json -Compress
}

try {
    $inputText = [Console]::In.ReadToEnd()
    $event = $inputText | ConvertFrom-Json

    $workspace = $event.workspacePaths[0]
    $transcriptPath = $event.transcriptPath
    $conversationId = $event.conversationId

    if (-not $workspace -or -not $transcriptPath) {
        Reply
        exit 0
    }

    Set-Location $workspace

    $stateFile = Join-Path $workspace ".git\antigravity-prompt-state.json"

    if (-not (Test-Path $transcriptPath)) {
        Reply
        exit 0
    }

    # Count user prompts in this conversation.
    $userPromptCount = 0

    Get-Content -LiteralPath $transcriptPath -ErrorAction SilentlyContinue |
        ForEach-Object {
            try {
                $entry = $_ | ConvertFrom-Json

                if ($entry.role -eq "user") {
                    $userPromptCount++
                }
                elseif ($entry.message -and $entry.message.role -eq "user") {
                    $userPromptCount++
                }
            }
            catch {
                # Ignore non-JSON lines.
            }
        }

    if ($userPromptCount -le 0) {
        Reply
        exit 0
    }

    # Load persistent state.
    $state = @{
        totalPrompts = 0
        conversations = @{}
    }

    if (Test-Path $stateFile) {
        try {
            $loaded = Get-Content $stateFile -Raw | ConvertFrom-Json

            if ($null -ne $loaded.totalPrompts) {
                $state.totalPrompts = [int]$loaded.totalPrompts
            }

            if ($null -ne $loaded.conversations) {
                foreach ($p in $loaded.conversations.PSObject.Properties) {
                    $state.conversations[$p.Name] = [int]$p.Value
                }
            }
        }
        catch {
            # Start fresh if state is invalid.
        }
    }

    if (-not $conversationId) {
        $conversationId = "default"
    }

    $previousCount = 0

    if ($state.conversations.ContainsKey($conversationId)) {
        $previousCount = [int]$state.conversations[$conversationId]
    }

    # Only count newly completed prompts.
    $delta = $userPromptCount - $previousCount

    if ($delta -le 0) {
        Reply
        exit 0
    }

    $state.conversations[$conversationId] = $userPromptCount
    $state.totalPrompts += $delta

    $state | ConvertTo-Json -Depth 5 |
        Set-Content -Encoding UTF8 $stateFile

    # Push only on prompt 5, 10, 15, 20, ...
    if (($state.totalPrompts % 5) -ne 0) {
        Reply
        exit 0
    }

    $status = git status --porcelain

    if (-not $status) {
        Reply
        exit 0
    }

    git add .

    $staged = git diff --cached --name-only

    if (-not $staged) {
        Reply
        exit 0
    }

    git commit -m "Auto-save after $($state.totalPrompts) Antigravity prompts"

    if ($LASTEXITCODE -ne 0) {
        Reply
        exit 0
    }

    git push origin main

    if ($LASTEXITCODE -ne 0) {
        Reply
        exit 0
    }

    Reply "MotionCare automatically pushed after $($state.totalPrompts) prompts."
}
catch {
    Reply
}
