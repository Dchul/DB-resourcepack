<#
  뽑기 기계 3D 모양을 리소스팩에 싣는 스크립트.

  원본은 RR.zip 안에 ModelEngine이 구워 둔 모양이다. 그대로 두면 me-pack.ps1이
  ModelEngine 자리를 통째로 갈아엎을 때 함께 지워지므로, 꼬리잡기 자리(taggame)로
  옮겨 담는다. 기계 몸통 하나(bone)만 쓰고 따로 노는 작은 조각들은 쓰지 않는다.

  넣는 것 (N = 1,2,3)
    assets/taggame/textures/item/gacha_N.png
    assets/taggame/models/item/gacha_N.json
    assets/taggame/items/gacha_N.json

  DB.zip과 DB_full.zip 양쪽에 같이 넣는다. 새로 생기는 자리라 다른 것과 겹치지 않는다.
#>
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

$Root = $PSScriptRoot
$Src  = Join-Path $Root 'RR.zip'
$Targets = @((Join-Path $Root 'DB.zip'), (Join-Path $Root 'DB_full.zip'))

# 번호 -> RR.zip 안의 모양 이름
$Models = @(
    [pscustomobject]@{ Number = 1; Id = 'capsule_1' },
    [pscustomobject]@{ Number = 2; Id = 'capsule_2' },
    [pscustomobject]@{ Number = 3; Id = 'capsule_3' }
)

if (-not (Test-Path $Src)) { throw "RR.zip이 없습니다: $Src" }

# ── 1) 원본에서 몸통 모양과 그림을 꺼낸다 ────────────────────────────────
$files = [ordered]@{}   # 팩 안 자리 -> 바이트

$rr = [IO.Compression.ZipFile]::OpenRead($Src)
try {
    foreach ($m in $Models) {
        $n  = $m.Number
        $id = $m.Id
        $me = $rr.GetEntry("assets/modelengine/models/$id/bone.json")
        if (-not $me) { throw "$id 의 몸통 모양을 RR.zip에서 찾지 못했습니다." }
        $sr = New-Object IO.StreamReader($me.Open()); $json = $sr.ReadToEnd(); $sr.Close()

        $tex = [regex]::Match($json, 'modelengine:([0-9a-f\-]{36})').Groups[1].Value
        if (-not $tex) { throw "$id 가 쓰는 그림을 찾지 못했습니다." }

        # 그림 주소를 꼬리잡기 자리로 바꾸고, 색 입히기 표시는 걷어낸다
        # (ModelEngine이 넣어 둔 것이라 그쪽 처리 없이는 쓸모가 없다)
        $json = $json -replace "modelengine:$tex", "taggame:item/gacha_$n"
        $json = $json -replace ',"tintindex":0', ''

        $pe = $rr.GetEntry("assets/modelengine/textures/$tex.png")
        if (-not $pe) { throw "$id 의 그림 파일이 RR.zip에 없습니다." }
        $ms = New-Object IO.MemoryStream
        $s = $pe.Open(); $s.CopyTo($ms); $s.Close()

        $utf8 = New-Object Text.UTF8Encoding($false)
        $files["assets/taggame/textures/item/gacha_$n.png"] = $ms.ToArray()
        $files["assets/taggame/models/item/gacha_$n.json"]  = $utf8.GetBytes($json)
        $files["assets/taggame/items/gacha_$n.json"] = $utf8.GetBytes(
            '{"model":{"type":"minecraft:model","model":"taggame:item/gacha_' + $n + '"}}')
    }
} finally { $rr.Dispose() }

# ── 2) 팩 안에 넣는다 ────────────────────────────────────────────────────
foreach ($target in $Targets) {
    if (-not (Test-Path $target)) { Write-Host "건너뜀 (없음): $target"; continue }
    $zip = [IO.Compression.ZipFile]::Open($target, 'Update')
    try {
        foreach ($name in @($files.Keys)) {
            $old = $zip.GetEntry($name)
            if ($old) { $old.Delete() }
            $entry = $zip.CreateEntry($name, [IO.Compression.CompressionLevel]::Optimal)
            $bytes = $files[$name]
            $out = $entry.Open()
            $out.Write($bytes, 0, $bytes.Length)
            $out.Dispose()
        }
    } finally { $zip.Dispose() }
    Write-Host ("넣음: " + (Split-Path $target -Leaf) + " (" + $files.Count + "개)")
}
