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
# 밀어 올릴 수 있는 칸수의 상한. 많을수록 좋으므로 모양이 감당하는 데까지 올린다.
$MaxRows = 8
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

        # ── 내릴 수 있는 여유를 최대로 벌어 둔다 ──
        #  모양을 아래로 내리는 데 쓸 수 있는 밑천은 두 가지다. 자리 값(80까지)과
        #  모양 좌표(-16까지)다. 그런데 모양 좌표를 잘게 줄이고 '크기'를 그만큼
        #  키우면 보이는 모습은 똑같으면서 좌표 쪽 밑천이 늘어난다.
        #  크기는 4까지만 허용되므로 거기에 딱 맞춰 줄여 둔다.
        #  (이 사본은 등에 얹힐 때만 쓰이므로 창에 뜨는 모습에는 영향이 없다)
        $sm = [regex]::Match($head, '"scale"\s*:\s*\[\s*(-?[\d.]+)\s*,\s*(-?[\d.]+)\s*,\s*(-?[\d.]+)\s*\]')
        $sMax = 1.0
        if ($sm.Success) {
            foreach ($g in 1..3) { $v = [Math]::Abs([double]$sm.Groups[$g].Value); if ($v -gt $sMax) { $sMax = $v } }
        }
        $k = $sMax / 4.0
        if ($k -lt 1.0 -and $k -gt 0) {
            $script:factor = $k
            $grow = {
                param($mm)
                $nums = $mm.Groups[2].Value -split ','
                $mm.Groups[1].Value +
                    [Math]::Round([double]$nums[0] * $script:factor, 4) + ',' +
                    [Math]::Round([double]$nums[1] * $script:factor, 4) + ',' +
                    [Math]::Round([double]$nums[2] * $script:factor, 4) + ']'
            }
            $triple = '("(?:from|to|origin)"\s*:\s*\[)\s*(-?[\d.]+\s*,\s*-?[\d.]+\s*,\s*-?[\d.]+)\s*\]'
            $json = [regex]::Replace($json, $triple, $grow)
            # 좌표를 줄이면서 글의 길이가 달라졌으므로 머리 자리를 다시 찾는다.
            # (이걸 빼먹으면 엉뚱한 곳에 끼워 넣어 모양 파일이 깨진다)
            $m = [regex]::Match($json, '"head"\s*:\s*\{[^{}]*\}')
            if (-not $m.Success) { $skipped += "$($b.key) (머리 위치 없음)"; continue }
            $head = $m.Value
            $sm = [regex]::Match($head, '"scale"\s*:\s*\[\s*(-?[\d.]+)\s*,\s*(-?[\d.]+)\s*,\s*(-?[\d.]+)\s*\]')

            # 줄인 만큼 크기를 키운다. 크기 항목이 없던 모양에는 새로 넣어 준다.
            $newScale = if ($sm.Success) {
                '"scale":[' +
                    [Math]::Round([double]$sm.Groups[1].Value / $k, 4) + ',' +
                    [Math]::Round([double]$sm.Groups[2].Value / $k, 4) + ',' +
                    [Math]::Round([double]$sm.Groups[3].Value / $k, 4) + ']'
            } else { '"scale":[4,4,4]' }
            $head2 = if ($sm.Success) { $head.Remove($sm.Index, $sm.Length).Insert($sm.Index, $newScale) }
                     else { $head.Insert($head.Length - 1, ',' + $newScale).Replace('{,', '{') }
            $json = $json.Remove($m.Index, $m.Length).Insert($m.Index, $head2)
            # 자리와 길이가 바뀌었으니 다시 찾는다
            $m = [regex]::Match($json, '"head"\s*:\s*\{[^{}]*\}')
            $head = $m.Value
            $t = [regex]::Match($head, '"translation"\s*:\s*\[\s*(-?[\d.]+)\s*,\s*(-?[\d.]+)\s*,\s*(-?[\d.]+)\s*\]')
            if (-not $t.Success) { $skipped += "$($b.key) (높이 값 없음)"; continue }
        }

        $y  = [double]$t.Groups[2].Value
        $z0 = [double]$t.Groups[3].Value
        $room = $Limit - [Math]::Abs($y)

        # 모양은 '크기'로 부풀려진 뒤 '기울기'만큼 돌아간 다음 자리로 옮겨진다.
        # 그러니 모양을 d 만큼 내리면 화면에서는 아래로 d × 크기 × cos(기울기) 만큼,
        # 그리고 앞뒤로도 d × 크기 × sin(기울기) 만큼 밀린다. 아래로 내려간 양은
        # 원하던 것이지만 앞뒤로 밀린 양은 어긋남이라 자리 값으로 되돌려 준다.
        $sc = 1.0
        $sm = [regex]::Match($head, '"scale"\s*:\s*\[\s*(-?[\d.]+)')
        if ($sm.Success) { $sc = [double]$sm.Groups[1].Value }
        $tilt = 0.0
        $rm = [regex]::Match($head, '"rotation"\s*:\s*\[\s*(-?[\d.]+)')
        if ($rm.Success) { $tilt = [double]$rm.Groups[1].Value }
        $rad = $tilt * [Math]::PI / 180.0
        $denom = $sc * [Math]::Cos($rad)

        # 높이 뽑아 올리는 칸수는 많을수록 좋다 — 위를 더 가파르게 올려다보아야
        # 사본이 화면에 들어온다. 그래서 가장 많은 칸수부터 넣어 보고, 모양의
        # 좌표가 만들 수 있는 자리(-16) 밖으로 나가면 한 칸씩 줄인다.
        $fpJson = $null; $rows = 0; $drop = 0.0
        for ($try = $MaxRows; $try -ge 1; $try--) {
            $carve = ($PerRow * $try) - $room     # 자리 값만으로 못 내리는 나머지
            $d = 0.0
            $newZ = $z0
            if ($carve -gt 0.001) {
                if ([Math]::Abs($denom) -lt 0.01) { continue }
                $d = $carve / $denom
                $newZ = $z0 + ($d * $sc * [Math]::Sin($rad))
                if ($newZ -gt $Limit -or $newZ -lt -$Limit) { continue }
            }
            $newY = $y - ($PerRow * $try)
            if ($newY -lt -$Limit) { $newY = -$Limit }

            $newT = '"translation":[' + $t.Groups[1].Value + ',' + $newY + ',' + [Math]::Round($newZ, 4) + ']'
            $newHead = $head.Remove($t.Index, $t.Length).Insert($t.Index, $newT)
            $candidate = $json.Remove($m.Index, $m.Length).Insert($m.Index, $newHead)

            if ($d -gt 0) {
                $script:lowest = $null
                $script:dropAmount = $d
                $shift = {
                    param($mm)
                    $nums = $mm.Groups[2].Value -split ','
                    $v = [double]$nums[1] - $script:dropAmount
                    if ($null -eq $script:lowest -or $v -lt $script:lowest) { $script:lowest = $v }
                    $mm.Groups[1].Value + $nums[0] + ',' + [Math]::Round($v, 4) + ',' + $nums[2] + ']'
                }
                $pat = '("(?:from|to|origin)"\s*:\s*\[)\s*(-?[\d.]+\s*,\s*-?[\d.]+\s*,\s*-?[\d.]+)\s*\]'
                $candidate = [regex]::Replace($candidate, $pat, $shift)
                if ($null -ne $script:lowest -and $script:lowest -lt -16) { continue }
            }

            $fpJson = $candidate; $rows = $try; $drop = $d
            break
        }
        if ($null -eq $fpJson) { $skipped += "$($b.key) (한 칸도 밀어 올릴 자리가 없음)"; continue }
        if ($drop -gt 0) { $carved += "$($b.key) : $rows 칸 (모양을 $([Math]::Round($drop,2)) 만큼 옮김)" }

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
