<#
  ModelEngine이 만들어 낸 모양 파일들을 DB.zip 안에 넣는 스크립트.

  커스텀 펫(수달 등)은 두 쪽이 짝을 이룬다.
    · 서버 쪽 : plugins/ModelEngine/blueprints 에 넣는 원본 파일. 여기서 다루지 않는다.
    · 손님 쪽 : 서버가 켜질 때 ModelEngine이 스스로 만들어 내는 그림 묶음.
                그게 손님 화면에 내려가야 펫이 보인다.

  ModelEngine은 서버가 켜질 때마다 자기 폴더 안에 그림 묶음을 새로 굽는다.
  이 스크립트는 그렇게 구워진 것을 통째로 DB.zip 안에 옮겨 담는다.

  그래서 순서가 중요하다.
    1) 펫 원본 파일을 서버의 ModelEngine 폴더에 넣는다
    2) 서버를 한 번 켰다 끈다 (이때 그림 묶음이 구워진다)
    3) 이 스크립트를 돌린다
    4) README의 갱신 절차(올리기 + SHA-1 반영)를 따른다

  게임 판마다 쓰는 그림이 조금씩 달라서 ModelEngine은 '판별 덧씌우기' 폴더를
  여럿 만든다. 그 폴더들과, 어느 판에 어느 폴더를 쓸지 적은 목록까지 함께 옮긴다.
#>
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

$Root   = $PSScriptRoot
$Zip    = Join-Path $Root 'DB.zip'
$Source = 'C:\Users\dredr\OneDrive\문서\ServerEngine\servers\server_890160838\plugins\ModelEngine\resource pack'

if (-not (Test-Path $Zip))    { throw "DB.zip이 없습니다: $Zip" }
if (-not (Test-Path $Source)) { throw "ModelEngine이 구워 둔 그림 묶음이 없습니다. 서버를 한 번 켰다 꺼 주세요: $Source" }

$srcMeta = Get-Content (Join-Path $Source 'pack.mcmeta') -Raw | ConvertFrom-Json

$archive = [System.IO.Compression.ZipFile]::Open($Zip, 'Update')
try {
    function Put-File([string]$entryName, [string]$sourcePath) {
        $old = $script:archive.GetEntry($entryName)
        if ($old) { $old.Delete() }
        [void][System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
            $script:archive, $sourcePath, $entryName,
            [System.IO.Compression.CompressionLevel]::Optimal)
    }
    function Put-Text([string]$entryName, [string]$text) {
        $old = $script:archive.GetEntry($entryName)
        if ($old) { $old.Delete() }
        $e = $script:archive.CreateEntry($entryName, [System.IO.Compression.CompressionLevel]::Optimal)
        $sw = New-Object System.IO.StreamWriter($e.Open(), (New-Object System.Text.UTF8Encoding($false)))
        $sw.Write($text); $sw.Flush(); $sw.Dispose()
    }

    # ── 1) 지난번에 넣어 둔 ModelEngine 것들을 먼저 걷어낸다 ──────────────
    #     펫을 빼거나 바꿨을 때 옛 파일이 남지 않도록.
    $stale = @($archive.Entries | Where-Object {
        $_.FullName -like 'assets/modelengine/*' -or
        $_.FullName -like 'modelengine_*/*' -or
        $_.FullName -eq 'assets/minecraft/atlases/blocks.json' -or
        $_.FullName -like 'assets/minecraft/shaders/*' -or
        $_.FullName -like '*/items/leather_horse_armor.json' -or
        $_.FullName -like '*/models/item/leather_horse_armor.json'
    })
    foreach ($e in $stale) { $e.Delete() }

    # ── 2) 구워진 것을 통째로 옮겨 담는다 ────────────────────────────────
    $skip = @('pack.mcmeta', 'pack.png')
    $files = Get-ChildItem $Source -Recurse -File
    $count = 0
    foreach ($f in $files) {
        $rel = $f.FullName.Substring($Source.Length + 1) -replace '\\', '/'
        if ($skip -contains $rel) { continue }
        Put-File $rel $f.FullName
        $count++
    }

    # ── 3) '어느 판에 어느 폴더를 쓸지' 목록을 DB.zip 쪽 설명서에 합친다 ──
    $dbMetaEntry = $archive.GetEntry('pack.mcmeta')
    if (-not $dbMetaEntry) { throw 'DB.zip 안에 pack.mcmeta가 없습니다.' }
    $sr = New-Object System.IO.StreamReader($dbMetaEntry.Open())
    $dbMeta = $sr.ReadToEnd() | ConvertFrom-Json
    $sr.Dispose()

    # ModelEngine 것 말고 다른 덧씌우기가 이미 있다면 지우지 않고 남겨 둔다.
    $keep = @()
    if ($dbMeta.PSObject.Properties.Name -contains 'overlays' -and $dbMeta.overlays.entries) {
        $keep = @($dbMeta.overlays.entries | Where-Object { $_.directory -notlike 'modelengine_*' })
    }
    $merged = @($keep) + @($srcMeta.overlays.entries)
    $dbMeta | Add-Member -NotePropertyName overlays -NotePropertyValue ([pscustomobject]@{ entries = $merged }) -Force

    # ModelEngine이 요구하는 그림 관련 예외 목록도 함께 옮긴다.
    if ($srcMeta.PSObject.Properties.Name -contains 'sodium') {
        $dbMeta | Add-Member -NotePropertyName sodium -NotePropertyValue $srcMeta.sodium -Force
    }

    Put-Text 'pack.mcmeta' ($dbMeta | ConvertTo-Json -Depth 12)
} finally {
    $archive.Dispose()
}

$sha = (Get-FileHash -Algorithm SHA1 $Zip).Hash.ToLower()
Write-Host "ModelEngine 모양 $count 개를 DB.zip에 넣었습니다." -ForegroundColor Green
Write-Host "DB.zip SHA-1 = $sha" -ForegroundColor Cyan
