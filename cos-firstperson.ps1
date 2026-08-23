<#
  등 치장이 걸친 본인의 1인칭 화면을 가리지 않게 만든다.

  치장 프로그램(HMCCosmetics)에는 "걸친 본인에게만 다른 사본을 보여 주는" 기능이 있다.
  그 사본을 머리 위로 몇 칸 밀어 올리면 1인칭 화면 밖으로 나가 눈앞을 가리지 않고,
  3인칭과 남들 눈에는 원래 사본이 그대로 보인다.

  밀어 올리는 한 칸은 정확히 반 칸(높이 값 12.8)이다. 그러니 사본의 모양을 그만큼
  미리 내려 두면 등에 제자리로 붙어 보인다. 이 스크립트가 그 사본을 만들어 넣는다.

  높이 값은 게임이 80까지만 허용하므로, 이미 아래에 있는 치장일수록 밀어 올릴 수 있는
  칸수가 적다. 각 치장이 감당할 수 있는 최대 칸수를 여기서 계산한다.
  한 칸도 못 미는 치장은 건너뛰고 이름을 알려 준다 (모양 자체를 손봐야 하는 것들이다).

  cos-pack.ps1 이 DB.zip 을 다시 만들면 이 사본들이 지워지므로, 반드시 그 뒤에 돌린다.
  결과로 firstperson.txt 를 남기고, make-cosmetics.ps1 이 그것을 읽어 설정에 적어 준다.
#>
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

$Root      = $PSScriptRoot
$Zip       = Join-Path $Root 'DB.zip'
$FullZip   = Join-Path $Root 'DB_full.zip'
$Unpacked  = 'C:\Users\dredr\OneDrive\문서\ServerEngine\servers\server_890160838\plugins\DBPack\resourcepack'
$TableFile = Join-Path $Root 'firstperson.txt'

# 한 칸 밀어 올릴 때 내려야 하는 높이 값. (반 칸 = 12.8)
$PerRow  = 12.8
# 아무리 여유가 많아도 이보다 더 밀지는 않는다.
$MaxRows = 3
# 게임이 허용하는 높이 값의 한계
$Limit   = 80.0

if (-not (Test-Path $Zip)) { throw "DB.zip이 없습니다: $Zip" }

# ── 등에 다는 치장 목록 읽기 ─────────────────────────────────
#  '1인칭숨김: 아니오' 를 적어 둔 치장은 건드리지 않는다 (위치를 견줘 보는 용도 등).
$backs = @()
$key = $null; $part = $null; $model = $null; $opt = $true
function Save-Item {
    if ($script:part -eq '상체' -and $script:key -and $script:model -and $script:opt) {
        $script:backs += [pscustomobject]@{ key = $script:key; model = $script:model }
    }
    $script:key = $null; $script:part = $null; $script:model = $null; $script:opt = $true
}
foreach ($line in ([IO.File]::ReadAllText((Join-Path $Root 'cosmetic-items.yml'), [Text.Encoding]::UTF8) -split "`r?`n")) {
    if     ($line -match '^\s{2}([A-Za-z0-9_]+):\s*$') { Save-Item; $key = $Matches[1] }
    elseif ($line -match '^\s+부위:\s*(\S+)')          { $part  = $Matches[1] }
    elseif ($line -match '^\s+모양:\s*"(.+)"')         { $model = $Matches[1] }
    elseif ($line -match '^\s+1인칭숨김:\s*(\S+)')     { $opt   = ($Matches[1] -ne '아니오') }
}
Save-Item

# ── DB.zip 을 열고 사본을 만들어 넣는다 ──────────────────────
$made = @{}      # 치장이름 -> 밀어 올릴 칸수
$newFiles = @{}  # 팩 안 경로 -> 내용
$skipped = @()
$carved  = @()

$archive = [IO.Compression.ZipFile]::Open($Zip, 'Update')
try {
    function Read-Entry([string]$name) {
        $e = $script:archive.GetEntry($name)
        if (-not $e) { return $null }
        $sr = New-Object IO.StreamReader($e.Open(), [Text.Encoding]::UTF8)
        $t = $sr.ReadToEnd(); $sr.Dispose(); return $t
    }
    function Write-Entry([string]$name, [string]$text) {
        $old = $script:archive.GetEntry($name)
        if ($old) { $old.Delete() }
        $e = $script:archive.CreateEntry($name, [IO.Compression.CompressionLevel]::Optimal)
        $sw = New-Object IO.StreamWriter($e.Open(), (New-Object Text.UTF8Encoding($false)))
        $sw.Write($text); $sw.Flush(); $sw.Dispose()
    }

    foreach ($b in $backs) {
        $p = $b.model -split ':'
        $ns = $p[0]; $id = $p[1]
        $modelPath = "assets/$ns/models/$id.json"
        $json = Read-Entry $modelPath
        if (-not $json) { $skipped += "$($b.key) (모양 파일 없음)"; continue }

        $m = [regex]::Match($json, '"head"\s*:\s*\{[^{}]*\}')
        if (-not $m.Success) { $skipped += "$($b.key) (머리 위치 없음)"; continue }
        $head = $m.Value
        $t = [regex]::Match($head, '"translation"\s*:\s*\[\s*(-?[\d.]+)\s*,\s*(-?[\d.]+)\s*,\s*(-?[\d.]+)\s*\]')
        if (-not $t.Success) { $skipped += "$($b.key) (높이 값 없음)"; continue }

        $y = [double]$t.Groups[2].Value
        $room = $Limit - [Math]::Abs($y)
        $rows = [Math]::Floor($room / $PerRow)
        if ($rows -gt $MaxRows) { $rows = $MaxRows }

        # 높이 값만으로는 한 칸도 못 내리는 치장은, 모자란 만큼 모양 자체를 아래로 옮긴다.
        $carve = 0.0
        if ($rows -lt 1) {
            $rows = 1
            $carve = ($PerRow - $room)   # 높이 값이 한계에 걸려 못 내린 나머지
        }

        $newY = $y - ($PerRow * $rows)
        if ($newY -lt -$Limit) { $newY = -$Limit }
        $newZ = [double]$t.Groups[3].Value
        $drop = 0.0

        if ($carve -gt 0) {
            # 모양은 '크기'로 부풀려진 뒤 '기울기'만큼 돌아간 다음 자리로 옮겨진다.
            # 그러니 모양을 d 만큼 내리면 화면에서는 아래로 d × 크기 × cos(기울기) 만큼,
            # 그리고 앞뒤로도 d × 크기 × sin(기울기) 만큼 밀린다.
            # 아래로 내려간 양은 원하던 것이지만 앞뒤로 밀린 양은 어긋남이므로,
            # 그만큼 자리 값을 되돌려 준다. (이걸 빼먹으면 몸에서 앞뒤로 떠 보인다)
            $sc = 1.0
            $sm = [regex]::Match($head, '"scale"\s*:\s*\[\s*(-?[\d.]+)')
            if ($sm.Success) { $sc = [double]$sm.Groups[1].Value }
            $tilt = 0.0
            $rm = [regex]::Match($head, '"rotation"\s*:\s*\[\s*(-?[\d.]+)')
            if ($rm.Success) { $tilt = [double]$rm.Groups[1].Value }
            $rad = $tilt * [Math]::PI / 180.0
            $denom = $sc * [Math]::Cos($rad)
            if ([Math]::Abs($denom) -lt 0.01) { $skipped += "$($b.key) (너무 많이 기울어 옮길 수 없음)"; continue }
            $drop = $carve / $denom
            $newZ = $newZ + ($drop * $sc * [Math]::Sin($rad))
            if ($newZ -gt $Limit) { $newZ = $Limit } elseif ($newZ -lt -$Limit) { $newZ = -$Limit }
        }

        $newT = '"translation":[' + $t.Groups[1].Value + ',' + $newY + ',' + [Math]::Round($newZ, 4) + ']'
        $newHead = $head.Remove($t.Index, $t.Length).Insert($t.Index, $newT)
        $fpJson = $json.Remove($m.Index, $m.Length).Insert($m.Index, $newHead)

        if ($carve -gt 0) {
            $lowest = $null
            $shift = {
                param($mm)
                $nums = $mm.Groups[2].Value -split ','
                $v = [double]$nums[1] - $drop
                if ($null -eq $script:lowest -or $v -lt $script:lowest) { $script:lowest = $v }
                $mm.Groups[1].Value + $nums[0] + ',' + [Math]::Round($v, 4) + ',' + $nums[2] + ']'
            }
            $pat = '("(?:from|to|origin)"\s*:\s*\[)\s*(-?[\d.]+\s*,\s*-?[\d.]+\s*,\s*-?[\d.]+)\s*\]'
            $fpJson = [regex]::Replace($fpJson, $pat, $shift)
            if ($null -ne $lowest -and $lowest -lt -16) {
                $skipped += "$($b.key) (모양이 만들 수 있는 자리 밖으로 나감)"
                continue
            }
            $carved += "$($b.key) (모양을 $([Math]::Round($drop,2)) 만큼 옮김)"
        }

        $tintLine = ''
        if ($fpJson -match 'tintindex') {
            $tintLine = ",`n    `"tints`": [ { `"type`": `"minecraft:dye`", `"default`": -1 } ]"
        }
        $itemJson = @"
{
  "model": {
    "type": "minecraft:model",
    "model": "$ns`:${id}_fp"$tintLine
  }
}
"@
        $newFiles["assets/$ns/models/${id}_fp.json"] = $fpJson
        $newFiles["assets/$ns/items/${id}_fp.json"]  = $itemJson
        Write-Entry "assets/$ns/models/${id}_fp.json" $fpJson
        Write-Entry "assets/$ns/items/${id}_fp.json"  $itemJson
        $made[$b.key] = [int]$rows
    }
} finally {
    $archive.Dispose()
}

# ── 배포되는 팩과 서버가 읽는 풀어 둔 팩에도 같은 사본을 넣는다 ──
if (Test-Path $FullZip) {
    $full = [IO.Compression.ZipFile]::Open($FullZip, 'Update')
    try {
        foreach ($name in $newFiles.Keys) {
            $old = $full.GetEntry($name)
            if ($old) { $old.Delete() }
            $e = $full.CreateEntry($name, [IO.Compression.CompressionLevel]::Optimal)
            $sw = New-Object IO.StreamWriter($e.Open(), (New-Object Text.UTF8Encoding($false)))
            $sw.Write($newFiles[$name]); $sw.Flush(); $sw.Dispose()
        }
    } finally { $full.Dispose() }
}
if (Test-Path $Unpacked) {
    foreach ($name in $newFiles.Keys) {
        $dest = Join-Path $Unpacked ($name -replace '/', '\')
        $dir = Split-Path $dest -Parent
        if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        [IO.File]::WriteAllText($dest, $newFiles[$name], (New-Object Text.UTF8Encoding($false)))
    }
}

# ── make-cosmetics.ps1 이 읽어 갈 표 ─────────────────────────
$sb = New-Object Text.StringBuilder
[void]$sb.AppendLine('# 자동 생성 파일. 직접 고치지 말 것. (cos-firstperson.ps1 이 만든다)')
[void]$sb.AppendLine('# 1인칭에서 안 보이게 할 등 치장과, 머리 위로 밀어 올릴 칸수')
foreach ($k in ($made.Keys | Sort-Object)) { [void]$sb.AppendLine("$k $($made[$k])") }
[IO.File]::WriteAllText($TableFile, $sb.ToString(), (New-Object Text.UTF8Encoding($false)))

$byRows = $made.Values | Group-Object | Sort-Object Name
Write-Host ("1인칭 사본 {0}개 만듦" -f $made.Count) -ForegroundColor Green
foreach ($g in $byRows) { Write-Host ("  {0}칸 올림 : {1}개" -f $g.Name, $g.Count) -ForegroundColor DarkGray }
if ($carved.Count -gt 0) {
    Write-Host ("모양을 직접 옮긴 것 {0}개 (앞뒤로 아주 조금 어긋날 수 있음):" -f $carved.Count) -ForegroundColor Cyan
    foreach ($c in $carved) { Write-Host "  $c" -ForegroundColor Cyan }
}
if ($skipped.Count -gt 0) {
    Write-Host ("자리가 없어 건너뛴 것 {0}개:" -f $skipped.Count) -ForegroundColor Yellow
    foreach ($s in $skipped) { Write-Host "  $s" -ForegroundColor Yellow }
}
Write-Host ('DB.zip SHA-1 = ' + (Get-FileHash -Algorithm SHA1 $Zip).Hash.ToLower()) -ForegroundColor Cyan
