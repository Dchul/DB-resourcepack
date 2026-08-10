<#
  cos 폴더(cos260523 등)를 DB.zip 안에 집어넣는 스크립트.

  Nexo가 뱉어 놓은 폴더에는 모양(models)과 그림(textures)만 있고,
  게임이 "이 아이템은 이 모양으로 그려라"라고 알아듣는 연결 파일(items)이 없다.
  그 연결 파일을 모양 개수만큼 자동으로 만들어서 함께 넣는다.

  그림은 반드시 textures/item/ 아래에 두어야 게임이 그림 모음판에 실어 준다.
  Nexo는 자기 목록 파일로 이 문제를 피해 가지만, 여기서는 그림을 item 폴더로
  옮기고 모양 파일 안의 그림 경로도 함께 고쳐 넣는다.

  새 폴더(cos260527 등)가 늘어나면 그냥 이 스크립트를 다시 돌리면 된다.
#>
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

$Root = $PSScriptRoot
$Zip  = Join-Path $Root 'DB.zip'
if (-not (Test-Path $Zip)) { throw "DB.zip이 없습니다: $Zip" }

$folders = Get-ChildItem -Path $Root -Directory | Where-Object { $_.Name -match '^cos\d+$' }
if ($folders.Count -eq 0) { Write-Host 'cos 폴더가 없습니다.'; exit 0 }

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
    foreach ($f in $folders) {
        $ns = $f.Name

        # 예전에 잘못 들어간 것이 있으면 통째로 지우고 새로 넣는다
        foreach ($e in @($archive.Entries | Where-Object { $_.FullName -like "assets/$ns/*" })) {
            $e.Delete()
        }

        $added = 0
        $modelDir = Join-Path $f.FullName 'models'
        if (Test-Path $modelDir) {
            foreach ($m in Get-ChildItem -Path $modelDir -Filter *.json -File) {
                $id = [System.IO.Path]::GetFileNameWithoutExtension($m.Name)
                # 모양 파일 안의 그림 경로를 item 폴더 쪽으로 고친다
                $json = [System.IO.File]::ReadAllText($m.FullName, [System.Text.Encoding]::UTF8)
                $json = $json.Replace("`"$ns" + ":", "`"$ns" + ":item/")
                Put-Text "assets/$ns/models/$id.json" $json
                Put-Text "assets/$ns/items/$id.json" @"
{
  "model": {
    "type": "minecraft:model",
    "model": "$ns`:$id"
  }
}
"@
                $added++
            }
        }

        $texDir = Join-Path $f.FullName 'textures'
        $tex = 0
        if (Test-Path $texDir) {
            foreach ($t in Get-ChildItem -Path $texDir -File -Recurse) {
                $rel = $t.FullName.Substring($texDir.Length).TrimStart('\','/').Replace('\','/')
                Put-File "assets/$ns/textures/item/$rel" $t.FullName
                $tex++
            }
        }

        Write-Host "$ns : 모양 $added 개, 그림 $tex 개" -ForegroundColor Green
    }
} finally {
    $archive.Dispose()
}

$sha = (Get-FileHash -Algorithm SHA1 $Zip).Hash.ToLower()
Write-Host "DB.zip SHA-1 = $sha" -ForegroundColor Cyan
