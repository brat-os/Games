<#
.SYNOPSIS
    Advanced Endless Geometric Jumping Game built using Windows Forms.
.DESCRIPTION
    Obstacles and collectibles move toward the player. Press SPACEBAR to jump.
    Features green ground pipes, flying red hazards, gold coins, and a high score tracker.
.AUTHOR
    Alexandru Bratosin
#>

$ErrorActionPreference = "Stop"

# 1. Load required .NET Assemblies for graphical interfaces
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

try {
    # 2. Canvas Dimensions
    $CanvasWidth = 1024
    $CanvasHeight = 600

    # Physics & Difficulty Constants
    $Gravity = 1.6
    $JumpStrength = -22
    $BaseObstacleSpeed = 8

    # 3. Game Object State Registries
    $GroundY = $CanvasHeight - 120

    $Player = @{
        X = 150
        Y = $GroundY - 32
        Width = 24
        Height = 32
        VelocityY = 0
        IsJumping = $false
    }

    # Strongly-typed .NET Generic Lists for game elements
    $Obstacles = New-Object 'System.Collections.Generic.List[System.Drawing.Rectangle]'
    $Coins = New-Object 'System.Collections.Generic.List[System.Drawing.Rectangle]'
    
    # Trackers
    $Score = 0
    if ($global:SessionHighScore -eq $null) { $global:SessionHighScore = 0 }
    $GameOver = $false
    $ObstacleSpeed = $BaseObstacleSpeed
    $SpawnTimerCounter = 0
    $SpawnInterval = 60 
    $KeysPressed = @{}

    # Define custom drawn button bounding layout vectors
    $ResetButtonRect = [System.Drawing.Rectangle]::new([int](($CanvasWidth / 2) - 80), [int](($CanvasHeight / 2) + 60), 160, 35)

    # COMPONENT: Game Reset Machine State
    function Reset-Game {
        $script:Obstacles.Clear()
        $script:Coins.Clear()
        $script:KeysPressed.Clear()
        
        # Save high score profile natively before resetting score counter
        if ($script:Score -gt $global:SessionHighScore) {
            $global:SessionHighScore = $script:Score
        }
        
        $script:Score = 0
        $script:GameOver = $false
        $script:ObstacleSpeed = $BaseObstacleSpeed
        $script:SpawnTimerCounter = 0
        $script:SpawnInterval = 60
        
        # Reset Player back onto the ground safely
        $script:Player.Y = $GroundY - $script:Player.Height
        $script:Player.VelocityY = 0
        $script:Player.IsJumping = $false
        
        $Timer.Start()
        $Form.Invalidate()
    }

    # Helper function: Randomly spawns Pipes, Flying Hazards, or Sky Coins
    function Spawn-GameElement {
        $SpawnType = Get-Random -Minimum 0 -Maximum 10
        
        if ($SpawnType -le 5) {
            # Ground Pipe Obstacle (Green)
            $Width = Get-Random -Minimum 25 -Maximum 45
            $Height = Get-Random -Minimum 35 -Maximum 75
            $Y = $GroundY - $Height
            $script:Obstacles.Add([System.Drawing.Rectangle]::new($CanvasWidth, $Y, $Width, $Height))
        } 
        elseif ($SpawnType -le 7) {
            # Flying Hazard Obstacle (Red)
            $Width = 30
            $Height = 20
            $Y = $GroundY - (Get-Random -Minimum 60 -Maximum 110)
            $script:Obstacles.Add([System.Drawing.Rectangle]::new($CanvasWidth, $Y, $Width, $Height))
        } 
        else {
            # Collectible Star Coin (Gold Circle)
            $Width = 16
            $Height = 16
            $Y = $GroundY - (Get-Random -Minimum 50 -Maximum 140)
            $script:Coins.Add([System.Drawing.Rectangle]::new($CanvasWidth, $Y, $Width, $Height))
        }
    }

    # 4. Create Main GUI Window
    $Form = New-Object System.Windows.Forms.Form
    $Form.Text = "PowerShell Advanced Endless Jumper"
    $Form.Size = [System.Drawing.Size]::new($CanvasWidth + 16, $CanvasHeight + 39)
    $Form.StartPosition = "CenterScreen"
    $Form.FormBorderStyle = "FixedSingle"
    $Form.MaximizeBox = $false
    $Form.BackColor = [System.Drawing.Color]::LightSkyBlue

    # Activate hardware DoubleBuffering properties via structural string assembly Reflection 
    $BindingFlags = [System.Reflection.BindingFlags]"NonPublic, Instance"
    $Form.GetType().GetProperty("DoubleBuffered", $BindingFlags).SetValue($Form, $true, $null)

    # 5. Mouse Click Interception for custom-drawn button area
    $Form.Add_MouseClick({
        param($Sender, $MouseEventArgs)
        if ($script:GameOver -and $ResetButtonRect.Contains($MouseEventArgs.Location)) {
            Reset-Game
        }
    })

    # 6. Keyboard Input Interception Matrix
    $Form.Add_KeyDown({
        param($Sender, $EventArgs)
        $KeyName = $EventArgs.KeyCode.ToString()
        
        # Intercept reset action triggers
        if ($script:GameOver -and ($KeyName -eq "Space" -or $KeyName -eq "R")) {
            Reset-Game
            return
        }

        # Safe down key register mapping
        $script:KeysPressed[$KeyName] = $true
    })

    $Form.Add_KeyUp({
        param($Sender, $EventArgs)
        $KeyName = $EventArgs.KeyCode.ToString()
        $script:KeysPressed[$KeyName] = $false
    })

    # 7. Presentation Visual Graphics Paint Engine 
    $Form.Add_Paint({
        param($Sender, $PaintEventArgs)
        $Graphics = $PaintEventArgs.Graphics

        # Render Floor Foundation Line
        $GroundBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::SaddleBrown)
        $GrassBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::LimeGreen)
        $Graphics.FillRectangle($GroundBrush, 0, $GroundY, $CanvasWidth, 120)
        $Graphics.FillRectangle($GrassBrush, 0, $GroundY, $CanvasWidth, 8)

        # Render Active Moving Obstacles
        $PipeBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::ForestGreen)
        $HazardBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Crimson)
        foreach ($Obstacle in $Obstacles) {
            if ($Obstacle.Y -lt ($GroundY - 75)) {
                $Graphics.FillRectangle($HazardBrush, $Obstacle)
            } else {
                $Graphics.FillRectangle($PipeBrush, $Obstacle)
            }
            $Graphics.DrawRectangle([System.Drawing.Pens]::Black, $Obstacle)
        }

        # Render Sky Coins
        $CoinBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Gold)
        foreach ($Coin in $Coins) {
            $Graphics.FillEllipse($CoinBrush, $Coin)
            $Graphics.DrawEllipse([System.Drawing.Pens]::DarkGoldenrod, $Coin)
        }

        # Render Player Character Asset
        $PlayerBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::DarkSlateBlue)
        $Graphics.FillRectangle($PlayerBrush, [int]$Player.X, [int]$Player.Y, [int]$Player.Width, [int]$Player.Height)
        $Graphics.DrawRectangle([System.Drawing.Pens]::White, [int]$Player.X, [int]$Player.Y, [int]$Player.Width, [int]$Player.Height)

        # Live Score UI Overlay Display
        $FontUI = New-Object System.Drawing.Font("Consolas", 14, [System.Drawing.FontStyle]::Bold)
        $FontSmall = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Regular)
        $BrushWhite = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
        
        $Graphics.DrawString("Score: $Score   |   HIGH SCORE: $global:SessionHighScore", $FontUI, $BrushWhite, 20, 20)
        $Graphics.DrawString("Controls: SPACEBAR to Jump over ground obstacles and catch gold coins!", $FontSmall, $BrushWhite, 20, 50)

        # End Screen State Handling
        if ($GameOver) {
            $FontTitle = New-Object System.Drawing.Font("Consolas", 22, [System.Drawing.FontStyle]::Bold)
            $FontBtn = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Bold)
            $BrushRed = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Red)
            
            $StringFormat = New-Object System.Drawing.StringFormat
            $StringFormat.Alignment = [System.Drawing.StringAlignment]::Center
            
            $Graphics.DrawString("GAME OVER`nFinal Score: $Score`nPress SPACEBAR or 'R' to play again!", $FontTitle, $BrushRed, [float]($CanvasWidth / 2), [float]($CanvasHeight / 3), $StringFormat)

            # Render custom Restart button asset
            $CustomBtnBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::DimGray)
            $Graphics.FillRectangle($CustomBtnBrush, $ResetButtonRect)
            $Graphics.DrawRectangle([System.Drawing.Pens]::White, $ResetButtonRect)
            $Graphics.DrawString("Restart Game", $FontBtn, $BrushWhite, [float]($ResetButtonRect.X + 32), [float]($ResetButtonRect.Y + 10))
        }
    })

    # 8. Main Infinite Runner Loop Core Engine Frame Clock
    $Timer = New-Object System.Windows.Forms.Timer
    $Timer.Interval = 20
    $Timer.Add_Tick({
        try {
            if ($GameOver) { return }

            # --- 1. Jump Input Processing Execution ---
            if ($script:KeysPressed["Space"] -eq $true -and -not $Player.IsJumping) {
                $script:Player.VelocityY = $JumpStrength
                $script:Player.IsJumping = $true
            }

            # --- 2. Manage Dynamic Obstacle Spawning Logic ---
            $script:SpawnTimerCounter++
            if ($script:SpawnTimerCounter -ge $script:SpawnInterval) {
                Spawn-GameElement
                $script:SpawnTimerCounter = 0
                
                # Dynamic Difficulty scaling values
                if ($script:ObstacleSpeed -lt 20) { $script:ObstacleSpeed += 0.2 }
                if ($script:SpawnInterval -gt 35) { $script:SpawnInterval -= 1 }
            }

            # --- 3. Update and Shift Moving Obstacles ---
            for ($i = $Obstacles.Count - 1; $i -ge 0; $i--) {
                $Rect = $Obstacles[$i]
                $NewX = $Rect.X - [int]$script:ObstacleSpeed
                
                if (($NewX + $Rect.Width) -lt 0) {
                    $Obstacles.RemoveAt($i)
                    $script:Score += 10 
                } else {
                    $Obstacles[$i] = [System.Drawing.Rectangle]::new($NewX, $Rect.Y, $Rect.Width, $Rect.Height)
                }
            }

            # --- 4. Update and Shift Moving Coins ---
            $PlayerRect = [System.Drawing.Rectangle]::new([int]$Player.X, [int]$Player.Y, [int]$Player.Width, [int]$Player.Height)
            for ($i = $Coins.Count - 1; $i -ge 0; $i--) {
                $Rect = $Coins[$i]
                $NewX = $Rect.X - [int]$script:ObstacleSpeed
                
                $CurrentCoin = [System.Drawing.Rectangle]::new($NewX, $Rect.Y, $Rect.Width, $Rect.Height)
                
                if ($PlayerRect.IntersectsWith($CurrentCoin)) {
                    $Coins.RemoveAt($i)
                    $script:Score += 50 
                } elseif (($NewX + $Rect.Width) -lt 0) {
                    $Coins.RemoveAt($i)
                } else {
                    $Coins[$i] = $CurrentCoin
                }
            }

            # --- 5. Compute Vertical Player Gravity Physics ---
            $script:Player.VelocityY += $Gravity
            $script:Player.Y += $script:Player.VelocityY

            # Floor bounds enforcement check
            if ($Player.Y -ge ($GroundY - $Player.Height)) {
                $script:Player.Y = $GroundY - $Player.Height
                $script:Player.VelocityY = 0
                $script:Player.IsJumping = $false
            }

            # --- 6. Collision Crash Evaluation Matrix ---
            foreach ($Obstacle in $Obstacles) {
                if ($PlayerRect.IntersectsWith($Obstacle)) {
                    $script:GameOver = $true
                    
                    if ($script:Score -gt $global:SessionHighScore) {
                        $global:SessionHighScore = $script:Score
                    }
                    $Timer.Stop()
                }
            }

            # Force canvas refresh
            if ($Form.Created) {
                $Form.Invalidate()
            }
        }
        catch [System.Management.Automation.PipelineStoppedException] {
            if ($Timer) { $Timer.Stop() }
        }
    })

    # Start loop processes
    Reset-Game
    $null = $Form.ShowDialog()
}
catch {
    Write-Error "System crash occurred executing infinite runner engine context loop frames: $_"
}
finally {
    if ($Timer) { $Timer.Dispose() }
    if ($Form) { $Form.Dispose() }
}
