# ItemsAdder가 만든 팩(generated.zip)을 서버 배포용 DB.zip으로 다듬는다.
#
# ItemsAdder는 자기 내부 글꼴이 쓰는 글자(U+E000~E01A)를 default.json 앞쪽에 넣으면서
# 같은 글자를 쓰는 DB 팩 항목을 버린다. 마인크래프트는 앞에 온 항목이 이기므로,
# 겹치는 글자는 DB 쪽 그림이 아예 보이지 않는다. 그래서 칭호 그림은 U+E900~ 로 옮겨 두었다.
# 혹시 ItemsAdder가 버린 항목이 또 생기면 살아나도록, DB 원본 글꼴 항목을 통째로 뒤에 다시 붙인다.

param(
    [string]$Generated = "$PSScriptRoot\generated.zip",   # ItemsAdder 결과물
    [string]$Source    = "$PSScriptRoot\DBPack",          # 합치기 전 DB 팩 폴더 (assets/ 를 담고 있음)
    [string]$Output    = "$PSScriptRoot\DB.zip",
    [string]$Description = "DB SERVER"
)

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$fontPath = Join-Path $Source "assets\minecraft\font\default.json"
if (-not (Test-Path $fontPath)) { throw "원본 글꼴 파일 없음: $fontPath" }
$srcFont = (Get-Content $fontPath -Raw -Encoding UTF8) | ConvertFrom-Json

Copy-Item $Generated $Output -Force
$zip = [IO.Compression.ZipFile]::Open($Output, 'Update')

function Set-Entry($name, $text) {
    $e = $zip.Entries | Where-Object { $_.FullName -eq $name }
    if ($e) { $e.Delete() }
    $e = $zip.CreateEntry($name)
    $w = New-Object IO.StreamWriter($e.Open(), (New-Object Text.UTF8Encoding($false)))
    $w.Write($text); $w.Close()
}

function Get-Entry($name) {
    $e = $zip.Entries | Where-Object { $_.FullName -eq $name }
    if (-not $e) { return $null }
    $r = New-Object IO.StreamReader($e.Open(), [Text.Encoding]::UTF8)
    $t = $r.ReadToEnd(); $r.Close(); return $t
}

# 1) 글꼴: ItemsAdder 항목 뒤에 DB 원본 항목을 다시 붙인다
#    uniform.json은 ItemsAdder가 default.json을 복사해 만드는 것이라 같이 손본다
foreach ($name in @("assets/minecraft/font/default.json", "assets/minecraft/font/uniform.json")) {
    $raw = Get-Entry $name
    if (-not $raw) { continue }
    $font = $raw | ConvertFrom-Json
    $font.providers = @($font.providers) + @($srcFont.providers)
    Set-Entry $name ($font | ConvertTo-Json -Depth 30 -Compress)
    Write-Host ("$name : DB 원본 " + @($srcFont.providers).Count + "개를 뒤에 다시 붙였습니다.")
}

# 2) ItemsAdder가 끼워 넣는 바닐라 번역 덮어쓰기를 걷어낸다
#    ('염색됨' 표시 지우기 등 — 요청하지 않은 변화라서 뺀다. DB 원본에 있는 것만 남긴다)
$removed = 0
foreach ($e in @($zip.Entries | Where-Object { $_.FullName -like "assets/minecraft/lang/*" })) {
    $local = Join-Path $Source ($e.FullName -replace "/", "\")
    if (-not (Test-Path $local)) { $e.Delete(); $removed++ }
}
Write-Host "바닐라 번역 덮어쓰기 $removed 개를 제거했습니다."

# 3) 팩 이름을 서버 것으로 되돌린다
$name = "pack.mcmeta"
$meta = Get-Entry $name | ConvertFrom-Json
$meta.pack.description = $Description
Set-Entry $name ($meta | ConvertTo-Json -Depth 30 -Compress)

$zip.Dispose()
$size = [math]::Round((Get-Item $Output).Length / 1MB, 2)
Write-Host "완성: $Output ($size MB)"
