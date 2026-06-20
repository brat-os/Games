<#
.SYNOPSIS
    Universal Arcade Snake game built using Windows Forms.
.DESCRIPTION
    Use the arrow keys to control the snake. If you crash, click the 
    on-screen "Restart Game" button OR press SPACEBAR to start a new round.
.AUTHOR
    Alexandru Bratosin
#>

$ErrorActionPreference = "Stop"

# 1. Load required .NET Assemblies for graphical interfaces
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

try {
    # 2. Game Dimensions & Scale Constants (Increased by 20%)
    $GridSize = 20      # Size of each square in pixels
    $Width = 36         # Total grids horizontally (Previously 30 -> 36 * 20 = 720px canvas)
    $Height = 30        # Total grids vertically (Previously 25 -> 30 * 20 = 600px canvas)
    
    # Calculate exact pixel dimensions for centering logic
    $CanvasWidth = $Width * $GridSize
    $CanvasHeight = $Height * $GridSize

    # Initialize Global State Variables
    $Snake = New-Object System.Collections.ArrayList
    $Direction = "RIGHT"
    $NextDirection = "RIGHT"
    $Score = 0
    $GameOver = $false
    $Food = [System.Drawing.Point]::Empty

    # Function: Generate new food coordinates (must not spawn on top of the snake)
    function New-Food {
        param($Width, $Height, $Snake)
        $Valid = $false
        while (-not $Valid) {
            $X = Get-Random -Minimum 0 -Maximum $Width
            $Y = Get-Random -Minimum 0 -Maximum $Height
            $Point = [System.Drawing.Point]::new($X, $Y)
            
            if (-not $Snake.Contains($Point)) { $Valid = $true }
        }
        return $Point
    }

    # FUNCTION: Reset the active state machine loops
    function Reset-Game {
        $script:Snake.Clear()
        # Build original snake segments (centered start)
        $StartX = [int]($Width / 2)
        $StartY = [int]($Height / 2)
        $null = $script:Snake.Add([System.Drawing.Point]::new($StartX, $StartY))
        $null = $script:Snake.Add([System.Drawing.Point]::new($StartX - 1, $StartY))
        $null = $script:Snake.Add([System.Drawing.Point]::new($StartX - 2, $StartY))

        $script:Direction = "RIGHT"
        $script:NextDirection = "RIGHT"
        $script:Score = 0
        $script:GameOver = $false
        $script:Food = New-Food -Width ($Width - 1) -Height ($Height - 1) -Snake $script:Snake
        
        # Hide the Restart button during active gameplay and give window focus back to controls
        $RestartButton.Visible = $false
        $Form.Text = "PowerShell Snake - Score: 0"
        $Timer.Start()
        $Form.Invalidate()
        $Form.Focus() | Out-Null
    }

    # 3. Create Main GUI Window (Form)
    $Form = New-Object System.Windows.Forms.Form
    $Form.Text = "PowerShell Snake"
    $Form.Size = [System.Drawing.Size]::new($CanvasWidth + 16, $CanvasHeight + 39)
    $Form.StartPosition = "CenterScreen"
    $Form.FormBorderStyle = "FixedSingle"
    $Form.MaximizeBox = $false
    $Form.BackColor = [System.Drawing.Color]::Black

    # Enable DoubleBuffering to fix and eliminate visual graphic tearing/flickering
    $BindingFlags = [System.Reflection.BindingFlags]"NonPublic, Instance"
    $Form.GetType().GetProperty("DoubleBuffered", $BindingFlags).SetValue($Form, $true, $null)

    # 4. Create the Graphical UI Restart Button (Perfectly Centered)
    $RestartButton = New-Object System.Windows.Forms.Button
    $RestartButton.Text = "Restart Game"
    
    $ButtonWidth = 180
    $ButtonHeight = 40
    $RestartButton.Size = [System.Drawing.Size]::new($ButtonWidth, $ButtonHeight)
    
    # Mathematically centered on X-axis, positioned under the text on Y-axis
    $ButtonX = ($CanvasWidth / 2) - ($ButtonWidth / 2)
    $ButtonY = ($CanvasHeight / 2) + 60
    $RestartButton.Location = [System.Drawing.Point]::new($ButtonX, $ButtonY)
    
    $RestartButton.Font = New-Object System.Drawing.Font("Consolas", 11, [System.Drawing.FontStyle]::Bold)
    $RestartButton.BackColor = [System.Drawing.Color]::DarkSlateGray
    $RestartButton.ForeColor = [System.Drawing.Color]::White
    $RestartButton.Visible = $false  # Start hidden

    # Click Event handler for the button
    $RestartButton.Add_Click({
        Reset-Game
    })
    $Form.Controls.Add($RestartButton)

    # 5. Keyboard Navigation Event Handlers
    $Form.Add_KeyDown({
        param($Sender, $EventArgs)
        
        # Spacebar triggers a restart if game is over
        if ($script:GameOver -and $EventArgs.KeyCode -eq "Space") {
            Reset-Game
            return
        }

        # Completely ignore arrow key changes if the game state is over
        if ($script:GameOver) { return }

        switch ($EventArgs.KeyCode) {
            "Up"     { if ($Direction -ne "DOWN")  { $script:NextDirection = "UP" } }
            "Down"   { if ($Direction -ne "UP")    { $script:NextDirection = "DOWN" } }
            "Left"   { if ($Direction -ne "RIGHT") { $script:NextDirection = "LEFT" } }
            "Right"  { if ($Direction -ne "LEFT")  { $script:NextDirection = "RIGHT" } }
            "Escape" { $Form.Close() }
        }
    })

    # 6. Graphical Presentation Rendering Engine (Paint Event)
    $Form.Add_Paint({
        param($Sender, $PaintEventArgs)
        $Graphics = $PaintEventArgs.Graphics

        if ($GameOver) {
            $FontTitle = New-Object System.Drawing.Font("Consolas", 26, [System.Drawing.FontStyle]::Bold)
            $FontSub = New-Object System.Drawing.Font("Consolas", 12, [System.Drawing.FontStyle]::Regular)
            $BrushRed = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Red)
            $BrushWhite = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
            
            # Use StringFormat to enforce absolute native centering of drawn strings
            $StringFormat = New-Object System.Drawing.StringFormat
            $StringFormat.Alignment = [System.Drawing.StringAlignment]::Center
            $StringFormat.LineAlignment = [System.Drawing.StringAlignment]::Center

            # Draw strings relative to the exact center point of the canvas
            $TitleYOffset = ($CanvasHeight / 2) - 40
            $SubYOffset = ($CanvasHeight / 2) + 20

            $Graphics.DrawString("GAME OVER`nFinal Score: $Score", $FontTitle, $BrushRed, [System.Drawing.PointF]::new(($CanvasWidth / 2), $TitleYOffset), $StringFormat)
            $Graphics.DrawString("Press SPACEBAR or click button below", $FontSub, $BrushWhite, [System.Drawing.PointF]::new(($CanvasWidth / 2), $SubYOffset), $StringFormat)
            return
        }

        # Render Food Asset (Red circle)
        $FoodBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Red)
        $Graphics.FillEllipse($FoodBrush, ($Food.X * $GridSize), ($Food.Y * $GridSize), $GridSize, $GridSize)

        # Render Snake Asset Segments (Green blocks)
        for ($i = 0; $i -lt $Snake.Count; $i++) {
            $Color = if ($i -eq 0) { [System.Drawing.Color]::LimeGreen } else { [System.Drawing.Color]::DarkGreen }
            $SnakeBrush = New-Object System.Drawing.SolidBrush($Color)
            $Graphics.FillRectangle($SnakeBrush, ($Snake[$i].X * $GridSize), ($Snake[$i].Y * $GridSize), $GridSize - 1, $GridSize - 1)
        }
    })

    # 7. Internal Speed Logic Framework Clock (Timer Ticks every 100ms)
    $Timer = New-Object System.Windows.Forms.Timer
    $Timer.Interval = 100
    $Timer.Add_Tick({
        if ($GameOver) { return }

        $script:Direction = $NextDirection
        $Head = $Snake[0]
        $NewHead = [System.Drawing.Point]::new($Head.X, $Head.Y)

        switch ($Direction) {
            "UP"    { $NewHead.Y-- }
            "DOWN"  { $NewHead.Y++ }
            "LEFT"  { $NewHead.X-- }
            "RIGHT" { $NewHead.X++ }
        }

        # Border Bounds Collision Checks
        if ($NewHead.X -lt 0 -or $NewHead.X -ge $Width -or $NewHead.Y -lt 0 -or $NewHead.Y -ge $Height) {
            $script:GameOver = $true
            $Timer.Stop()
            $RestartButton.Visible = $true # Reveal UI Button element 
            $Form.Invalidate()
            return
        }

        # Self-Eaten Segmentation Collision Checks
        if ($Snake.Contains($NewHead)) {
            $script:GameOver = $true
            $Timer.Stop()
            $RestartButton.Visible = $true # Reveal UI Button element
            $Form.Invalidate()
            return
        }

        # Advance Position Queue Execution
        $Snake.Insert(0, $NewHead)

        # Feeding Threshold Evaluations
        if ($NewHead -eq $Food) {
            $script:Score += 10
            $Form.Text = "PowerShell Snake - Score: $Score"
            $script:Food = New-Food -Width ($Width - 1) -Height ($Height - 1) -Snake $Snake
        } else {
            $Snake.RemoveAt($Snake.Count - 1)
        }

        $Form.Invalidate()
    })

    # Fire Up Environment Variables
    Reset-Game
    $null = $Form.ShowDialog()
}
catch {
    Write-Error "Error executing Windows Forms game wrapper engine target: $_"
}
finally {
    if ($Timer) { $Timer.Dispose() }
    if ($Form) { $Form.Dispose() }
}
