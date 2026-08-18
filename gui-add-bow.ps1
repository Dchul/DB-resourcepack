<#
  도구 치장 창 그림에 '활' 단추를 하나 더 그려 넣는 스크립트.

  창 그림은 손으로 그린 그림 한 장이라 단추를 늘리려면 그림도 함께 늘려야 한다.
  단추 한 칸은 16x16 이고, 가로로 18칸씩 떨어져 있다. 여섯 번째 자리는 x=134 다.

  하는 일
    1) tool_*.png 여섯 장 모두에 여섯 번째(활) 단추를 회색으로 그려 넣는다.
    2) 첫 화면(tool_home.png)에는 지금 입힌 것을 보여 주는 칸도 하나 더 그린다.
    3) 활 화면(tool_bow.png)을 새로 만든다 — 검 화면을 본떠 활 단추만 초록으로.

  한 번만 돌리면 되고, 이미 그려져 있으면 알아서 건너뛴다.
#>
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$Gui = Join-Path $PSScriptRoot 'gui'
$BOX = 16
$X6  = 134          # 여섯 번째 단추의 왼쪽 끝
$X5  = 116          # 다섯 번째(검) 단추의 왼쪽 끝
$YB  = 42           # 단추 줄의 위쪽 끝

function C([string]$hex){
  [System.Drawing.Color]::FromArgb(255,
    [Convert]::ToInt32($hex.Substring(0,2),16),
    [Convert]::ToInt32($hex.Substring(2,2),16),
    [Convert]::ToInt32($hex.Substring(4,2),16))
}

# 단추 한 칸의 색 (회색 = 안 고른 것, 초록 = 지금 보고 있는 것)
$GRAY  = @{ border=C '221F26'; topHi=C 'FFFFFF'; frame=C 'DCDEE2'; bg=C '848A98'
            shadow=C '585E6C'; icon=C 'FFFFFF'; iconShade=C '5E6473' }
$GREEN = @{ border=C '221F26'; topHi=C 'D8F5A2'; frame=C 'C0EB75'; bg=C '37B24D'
            shadow=C '087F5B'; icon=C 'FFFFFF'; iconShade=C '087F5B' }

# 활 그림 — 다른 단추들처럼 비스듬히 눕혀 그린다 (활대가 왼쪽 위로 휘고, 시위는 곧은 선)
$ARC = @( @(2,10),@(2,9),@(2,8),@(2,7),@(3,6),@(3,5),@(4,4),@(5,3),@(6,3),@(7,2),@(8,2),@(9,2),@(10,2) )
$STR = @( @(3,9),@(4,8),@(5,7),@(6,6),@(7,5),@(8,4),@(9,3) )
$ARR = @()

function New-Button([hashtable]$pal){
  $bm = New-Object System.Drawing.Bitmap($BOX,$BOX,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  for($y=0;$y -lt $BOX;$y++){
    for($x=0;$x -lt $BOX;$x++){
      $c =
        if($y -eq 0 -or $y -eq 15 -or $x -eq 0 -or $x -eq 15) { $pal.border }
        elseif($y -eq 1) { $pal.topHi }
        elseif($y -eq 14 -or $x -eq 1 -or $x -eq 14) { $pal.frame }
        elseif($y -eq 2 -and $x -ge 3 -and $x -le 12) { $pal.shadow }
        else { $pal.bg }
      $bm.SetPixel($x,$y,$c)
    }
  }
  # 그림자 먼저, 그 위에 흰 선
  $pts = @($ARC + $STR + $ARR)
  foreach($p in $pts){
    $x = $p[0]+3; $y = $p[1]+4
    if($x -ge 2 -and $x -le 13 -and $y -ge 3 -and $y -le 13){ $bm.SetPixel($x,$y,$pal.iconShade) }
  }
  foreach($p in $pts){
    $x = $p[0]+2; $y = $p[1]+3
    if($x -ge 2 -and $x -le 13 -and $y -ge 3 -and $y -le 13){ $bm.SetPixel($x,$y,$pal.icon) }
  }
  $bm
}

function Paste([System.Drawing.Bitmap]$dst,[System.Drawing.Bitmap]$src,[int]$ox,[int]$oy){
  for($y=0;$y -lt $src.Height;$y++){ for($x=0;$x -lt $src.Width;$x++){ $dst.SetPixel($ox+$x,$oy+$y,$src.GetPixel($x,$y)) } }
}
function CopyRegion([System.Drawing.Bitmap]$src,[int]$x,[int]$y,[int]$w,[int]$h){
  $b=New-Object System.Drawing.Bitmap($w,$h,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  for($j=0;$j -lt $h;$j++){ for($i=0;$i -lt $w;$i++){ $b.SetPixel($i,$j,$src.GetPixel($x+$i,$y+$j)) } }
  $b
}

$grayBtn  = New-Button $GRAY
$greenBtn = New-Button $GREEN

# 이미 그려져 있는지 (여섯 번째 자리에 테두리 색이 있으면 이미 한 것)
function Has6([System.Drawing.Bitmap]$b){
  $c=$b.GetPixel($X6,$YB); ($c.A -gt 200 -and $c.R -lt 60 -and $c.G -lt 60)
}

$names = 'tool_home','tool_axe','tool_hoe','tool_pickaxe','tool_rod','tool_sword'
$swordGray = $null

foreach($n in $names){
  $p = Join-Path $Gui "$n.png"
  $b = [System.Drawing.Bitmap]::FromFile($p)
  $work = New-Object System.Drawing.Bitmap($b.Width,$b.Height,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g = [System.Drawing.Graphics]::FromImage($work); $g.DrawImage($b,0,0); $g.Dispose(); $b.Dispose()

  if($n -eq 'tool_home'){ $swordGray = CopyRegion $work $X5 $YB $BOX $BOX }

  if(-not (Has6 $work)){
    Paste $work $grayBtn $X6 $YB
    if($n -eq 'tool_home'){
      # 지금 입힌 것을 보여 주는 칸 하나 더 (아랫줄 세 번째)
      $w = [System.Drawing.Color]::FromArgb(255,255,255,255)
      for($y=98;$y -le 113;$y++){ $work.SetPixel(114,$y,$w) }
      for($x=98;$x -le 114;$x++){ $work.SetPixel($x,114,$w) }
    }
    $work.Save($p, [System.Drawing.Imaging.ImageFormat]::Png)
    Write-Host "$n : 활 단추를 그렸습니다" -ForegroundColor Green
  } else {
    Write-Host "$n : 이미 그려져 있습니다" -ForegroundColor DarkGray
  }
  if($n -eq 'tool_sword'){
    # 활 화면 = 검 화면에서 검 단추를 회색으로 되돌리고 활 단추를 초록으로
    $bow = New-Object System.Drawing.Bitmap($work.Width,$work.Height,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g2 = [System.Drawing.Graphics]::FromImage($bow); $g2.DrawImage($work,0,0); $g2.Dispose()
    Paste $bow $swordGray $X5 $YB
    Paste $bow $greenBtn  $X6 $YB
    $bow.Save((Join-Path $Gui 'tool_bow.png'), [System.Drawing.Imaging.ImageFormat]::Png)
    $bow.Dispose()
    Write-Host "tool_bow.png 를 만들었습니다" -ForegroundColor Green
  }
  $work.Dispose()
}
$grayBtn.Dispose(); $greenBtn.Dispose(); if($swordGray){$swordGray.Dispose()}
