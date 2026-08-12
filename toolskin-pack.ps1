<#
  도구 치장(손에 든 도구의 겉모습)을 DB.zip 안에 넣고,
  서버가 읽을 목록 파일도 함께 만드는 스크립트.

  원본은 두 가지다.
    toolskin-items.yml … 치장의 이름·종류·모양 (여기가 원본)
    toolskin\ 폴더      … 모양(models)과 그림(textures)

  하는 일 네 가지.

  1) 모양 파일을 DB.zip 에 넣는다. 그림은 반드시 textures/item/ 아래에 두어야
     게임이 그림 모음판에 실어 주므로, 모양 파일 안의 그림 경로도 함께 고친다.
  2) 움직이는 그림(.mcmeta)도 같이 넣는다 — 이게 빠지면 그림이 세로로 길게
     늘어난 채로 보인다.
  3) "이 겉모습을 쓰라"고 알려 주는 연결 파일을 치장 개수만큼 만든다.
     낚싯대는 찌를 던진 동안 모양이 달라지므로 두 모양을 함께 적는다.
  4) 서버의 plugins\TagGame\toolskins.yml 을 다시 만든다 (꼬리잡기가 읽는 목록).

  치장을 늘리거나 이름을 고쳤으면 이 스크립트를 다시 돌리고,
  그 다음 README 의 갱신 절차(주소·SHA-1)를 따른다.
#>
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

$Root   = $PSScriptRoot
$Zip    = Join-Path $Root 'DB.zip'
$Src    = Join-Path $Root 'toolskin'
$List   = Join-Path $Root 'toolskin-items.yml'
$NS     = 'toolskin'
$Server = 'C:\Users\dredr\Documents\ServerEngine\servers\server_890160838'

if (-not (Test-Path $Zip))  { throw "DB.zip이 없습니다: $Zip" }
if (-not (Test-Path $Src))  { throw "toolskin 폴더가 없습니다: $Src" }
if (-not (Test-Path $List)) { throw "toolskin-items.yml이 없습니다: $List" }

# ── 목록 읽기 ────────────────────────────────────────────────────
$skins = @()
$cur = $null
foreach ($line in ([IO.File]::ReadAllText($List, [Text.Encoding]::UTF8) -split "`r?`n")) {
    if     ($line -match '^\s{2}([A-Za-z0-9_]+):\s*$') {
        if ($cur) { $skins += $cur }
        $cur = [ordered]@{ id = $Matches[1]; name = $null; kind = $null; model = $null; cast = $null }
    }
    elseif ($line -match '^\s+이름:\s*"(.*)"')      { if ($cur) { $cur.name  = $Matches[1] } }
    elseif ($line -match '^\s+종류:\s*(\S+)')        { if ($cur) { $cur.kind  = $Matches[1] } }
    elseif ($line -match '^\s+모양:\s*"(.*)"')      { if ($cur) { $cur.model = $Matches[1] } }
    elseif ($line -match '^\s+던진모양:\s*"(.*)"')  { if ($cur) { $cur.cast  = $Matches[1] } }
}
if ($cur) { $skins += $cur }
$skins = @($skins | Where-Object { $_.name -and $_.model })
if ($skins.Count -eq 0) { throw "toolskin-items.yml에서 치장을 하나도 읽지 못했습니다." }

# ── 그림이 안 붙은 면 걷어내기 ───────────────────────────────────
<#
  받아 온 모양 중에는 어떤 면에 그림을 지정하지 않은 채로 온 것이 있다.
  게임은 그런 면을 보라·검정 격자(그림 없음 표시)로 그려 버려서 물건이
  망가져 보인다 (심해 낚싯대가 그랬다).

  그림이 없는 면은 원래 보이지 않아야 할 면이므로 통째로 빼 버린다.
  면이 하나도 남지 않은 덩어리도 함께 뺀다.
#>
function Remove-BlankFaces([string]$json) {
    if ($json -notmatch '"#') { return $json }
    $obj = $json | ConvertFrom-Json
    if (-not $obj.elements) { return $json }

    $known = @{}
    if ($obj.textures) {
        foreach ($p in $obj.textures.PSObject.Properties) { $known[$p.Name] = $true }
    }

    $keep = New-Object System.Collections.ArrayList
    $touched = $false
    foreach ($el in $obj.elements) {
        if (-not $el.faces) { [void]$keep.Add($el); continue }
        $left = 0
        foreach ($fn in @($el.faces.PSObject.Properties.Name)) {
            $t = $el.faces.$fn.texture
            $key = if ($t) { ([string]$t).TrimStart('#') } else { $null }
            if ($key -and $known.ContainsKey($key)) { $left++ }
            else { $el.faces.PSObject.Properties.Remove($fn); $touched = $true }
        }
        if ($left -gt 0) { [void]$keep.Add($el) } else { $touched = $true }
    }
    if (-not $touched) { return $json }
    $obj.elements = $keep.ToArray()
    return ($obj | ConvertTo-Json -Depth 40 -Compress)
}

# ── DB.zip 에 넣기 ───────────────────────────────────────────────
$archive = [System.IO.Compression.ZipFile]::Open($Zip, 'Update')

function Put-Text([string]$entryName, [string]$text) {
    $old = $script:archive.GetEntry($entryName)
    if ($old) { $old.Delete() }
    $e = $script:archive.CreateEntry($entryName, [System.IO.Compression.CompressionLevel]::Optimal)
    $sw = New-Object System.IO.StreamWriter($e.Open(), (New-Object System.Text.UTF8Encoding($false)))
    $sw.Write($text); $sw.Flush(); $sw.Dispose()
}
function Put-File([string]$entryName, [string]$sourcePath) {
    $old = $script:archive.GetEntry($entryName)
    if ($old) { $old.Delete() }
    [void][System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
        $script:archive, $sourcePath, $entryName,
        [System.IO.Compression.CompressionLevel]::Optimal)
}

try {
    # 예전에 들어간 것은 통째로 지우고 새로 넣는다
    foreach ($e in @($archive.Entries | Where-Object { $_.FullName -like "assets/$NS/*" })) { $e.Delete() }

    $modelCount = 0
    $cleaned = 0
    foreach ($m in Get-ChildItem (Join-Path $Src 'models') -Filter *.json -File) {
        $id = [IO.Path]::GetFileNameWithoutExtension($m.Name)
        $json = [IO.File]::ReadAllText($m.FullName, [Text.Encoding]::UTF8)
        $fixed = Remove-BlankFaces $json
        if ($fixed -ne $json) { $cleaned++; $json = $fixed }
        $json = $json.Replace("`"$NS" + ":", "`"$NS" + ":item/")
        Put-Text "assets/$NS/models/$id.json" $json
        $modelCount++
    }

    $texCount = 0
    foreach ($t in Get-ChildItem (Join-Path $Src 'textures') -File) {
        Put-File "assets/$NS/textures/item/$($t.Name)" $t.FullName
        $texCount++
    }

    foreach ($s in $skins) {
        if ($s.cast) {
            # 낚싯대 — 찌를 던진 동안에는 다른 모양으로 바뀐다
            $body = @"
{
  "model": {
    "type": "minecraft:condition",
    "property": "minecraft:fishing_rod/cast",
    "on_true":  { "type": "minecraft:model", "model": "$NS`:$($s.cast)" },
    "on_false": { "type": "minecraft:model", "model": "$NS`:$($s.model)" }
  }
}
"@
        } else {
            $body = @"
{
  "model": {
    "type": "minecraft:model",
    "model": "$NS`:$($s.model)"
  }
}
"@
        }
        Put-Text "assets/$NS/items/$($s.id).json" $body
    }

    Write-Host ("도구 치장 : 치장 {0}개, 모양 {1}개(손질 {3}개), 그림 {2}개" -f $skins.Count, $modelCount, $texCount, $cleaned) -ForegroundColor Green
} finally {
    $archive.Dispose()
}

# ── 서버가 읽을 목록 ─────────────────────────────────────────────
$pluginDir = Join-Path $Server 'plugins\TagGame'
if (Test-Path $pluginDir) {
    $sb = New-Object Text.StringBuilder
    [void]$sb.AppendLine('# 도구 치장 목록 — toolskin-pack.ps1 이 자동으로 만든다.')
    [void]$sb.AppendLine('# 직접 고치지 말고 Resourcepacks\toolskin-items.yml 을 고친 뒤 다시 돌릴 것.')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('skins:')
    foreach ($s in $skins) {
        [void]$sb.AppendLine("  $($s.id):")
        [void]$sb.AppendLine("    name: `"$($s.name)`"")
        [void]$sb.AppendLine("    kind: `"$($s.kind)`"")
    }
    [IO.File]::WriteAllText((Join-Path $pluginDir 'toolskins.yml'), $sb.ToString(),
        (New-Object Text.UTF8Encoding($false)))
    Write-Host "서버 목록도 새로 썼습니다: $pluginDir\toolskins.yml" -ForegroundColor Green
} else {
    Write-Host "서버 폴더를 찾지 못해 목록은 건너뜁니다: $pluginDir" -ForegroundColor Yellow
}

$sha = (Get-FileHash -Algorithm SHA1 $Zip).Hash.ToLower()
Write-Host "DB.zip SHA-1 = $sha" -ForegroundColor Cyan
