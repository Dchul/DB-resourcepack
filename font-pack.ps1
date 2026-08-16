<#
  글꼴 설정 파일을 만들어 DB.zip 과 GUI 크기별 덧씌우기 팩에 넣는 스크립트.

  마인크래프트는 글꼴 그림을 늘리거나 줄일 때 중간값을 섞지 않는다. 그래서 화면에 그리는
  크기와 구워 둔 크기가 정확히 맞을 때만 또렷하다. 화면 크기는 GUI 크기 설정에 따라 달라지고
  (그래서 팩이 2·3·4용으로 나뉜다), 같은 GUI 크기 안에서도 자리에 따라 또 달라진다.

    본문·채팅·창 글씨 … 그대로            → 배수 1
    화면 가운데 부제   … 2배로 늘려 그림   → 배수 2
    화면 가운데 타이틀 … 4배로 늘려 그림   → 배수 4

  그래서 같은 글꼴을 배수만 달리해 세 벌씩 굽는다.

    minecraft:default / taggame:bold  … 본문
    taggame:mid       / taggame:mid_bold  … 부제
    taggame:big       / taggame:big_bold  … 타이틀

  꼬리잡기 플러그인이 타이틀·부제 글에 mid·big 을 지정해 내보낸다(TitleFont).

  글자 크기(size)는 GUI 크기별로 미세하게 달라서, 크기 × 배수가 정수가 되도록 맞춘 값이다.

  고쳤으면 이 스크립트를 돌리고 README의 갱신 절차를 따른다.
#>
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

$Root = $PSScriptRoot

# GUI 크기 → (글자 크기, 기본 배수)
$Scales = @{
    2 = @{ size = '8.5';    over = 2 }
    3 = @{ size = '8.6667'; over = 3 }
    4 = @{ size = '8.75';   over = 4 }
}

# 글꼴보다 앞서 놓이는 그림 글자들 (칭호 문양·하트). 모든 판이 똑같이 갖는다.
$Common = @'
    {
      "type": "space",
      "advances": { "\ue02f": -2 }
    },
    { "type": "bitmap", "file": "taggame:font/title/banana.png",      "ascent": 8, "height": 10, "chars": ["\ue010"] },
    { "type": "bitmap", "file": "taggame:font/title/cat.png",         "ascent": 8, "height": 10, "chars": ["\ue011"] },
    { "type": "bitmap", "file": "taggame:font/title/ditto.png",       "ascent": 8, "height": 10, "chars": ["\ue012"] },
    { "type": "bitmap", "file": "taggame:font/title/mouse.png",       "ascent": 8, "height": 10, "chars": ["\ue013"] },
    { "type": "bitmap", "file": "taggame:font/title/mimikyu.png",     "ascent": 8, "height": 10, "chars": ["\ue014"] },
    { "type": "bitmap", "file": "taggame:font/title/pig.png",         "ascent": 8, "height": 10, "chars": ["\ue015"] },
    { "type": "bitmap", "file": "taggame:font/title/pizzaguinea.png", "ascent": 8, "height": 10, "chars": ["\ue016"] },
    { "type": "bitmap", "file": "taggame:font/heart/full.png",        "ascent": 8, "height": 9,  "chars": ["\ue020"] },
    { "type": "bitmap", "file": "taggame:font/heart/half.png",        "ascent": 8, "height": 9,  "chars": ["\ue021"] },
    { "type": "bitmap", "file": "taggame:font/heart/empty.png",       "ascent": 8, "height": 9,  "chars": ["\ue022"] },
'@

function New-FontJson([string]$ttf, [string]$size, [double]$oversample) {
@"
{
  "providers": [
$Common
    {
      "type": "ttf",
      "file": "minecraft:$ttf",
      "size": $size,
      "oversample": $oversample
    },
    { "type": "reference", "id": "minecraft:include/space" },
    { "type": "reference", "id": "minecraft:include/default" },
    { "type": "reference", "id": "minecraft:include/unifont" }
  ]
}
"@
}

# 한 GUI 크기에 대한 여섯 벌 (경로 → 내용)
function New-FontSet([int]$scale) {
    $size = $Scales[$scale].size
    $base = [double]$Scales[$scale].over
    [ordered]@{
        'assets/minecraft/font/default.json'  = New-FontJson 'paperlogy.ttf'      $size $base
        'assets/taggame/font/bold.json'       = New-FontJson 'paperlogy_bold.ttf' $size $base
        'assets/taggame/font/mid.json'        = New-FontJson 'paperlogy.ttf'      $size ($base * 2)
        'assets/taggame/font/mid_bold.json'   = New-FontJson 'paperlogy_bold.ttf' $size ($base * 2)
        'assets/taggame/font/big.json'        = New-FontJson 'paperlogy.ttf'      $size ($base * 4)
        'assets/taggame/font/big_bold.json'   = New-FontJson 'paperlogy_bold.ttf' $size ($base * 4)
    }
}

function Put-Entry($archive, [string]$name, [string]$text) {
    if ($archive.Mode -ne [System.IO.Compression.ZipArchiveMode]::Create) {
        $old = $archive.GetEntry($name)
        if ($old) { $old.Delete() }
    }
    $e = $archive.CreateEntry($name, [System.IO.Compression.CompressionLevel]::Optimal)
    $sw = New-Object System.IO.StreamWriter($e.Open(), (New-Object System.Text.UTF8Encoding($false)))
    $sw.Write($text)
    $sw.Dispose()
}

# ── 1) 기본 팩 (GUI 크기 3) ─────────────────────────────────────
$zip = Join-Path $Root 'DB.zip'
if (-not (Test-Path $zip)) { throw "DB.zip이 없습니다: $zip" }
$archive = [System.IO.Compression.ZipFile]::Open($zip, 'Update')
try {
    foreach ($kv in (New-FontSet 3).GetEnumerator()) { Put-Entry $archive $kv.Key $kv.Value }
} finally { $archive.Dispose() }
Write-Host "DB.zip 글꼴 갱신 완료 (GUI 크기 3)"

# ── 2) 덧씌우기 팩 (GUI 크기 2·4) ───────────────────────────────
#     글꼴 파일만 들어 있고 글꼴 원본(ttf)과 그림은 기본 팩 것을 쓴다.
foreach ($s in 2, 4) {
    $out = Join-Path $Root "DB_font_scale$s.zip"
    if (Test-Path $out) { Remove-Item $out }
    $archive = [System.IO.Compression.ZipFile]::Open($out, 'Create')
    try {
        Put-Entry $archive 'pack.mcmeta' @"
{
  "pack": {
    "description": "DB 글꼴 · GUI 스케일 $s 전용",
    "min_format": 65,
    "max_format": 999
  }
}
"@
        foreach ($kv in (New-FontSet $s).GetEnumerator()) { Put-Entry $archive $kv.Key $kv.Value }
    } finally { $archive.Dispose() }
    Write-Host "DB_font_scale$s.zip 새로 만듦"
}
