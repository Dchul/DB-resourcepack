<#
  cos 폴더(cos260523 등)를 DB.zip 안에 집어넣는 스크립트.

  Nexo가 뱉어 놓은 폴더에는 모양(models)과 그림(textures)만 있고,
  게임이 "이 아이템은 이 모양으로 그려라"라고 알아듣는 연결 파일(items)이 없다.
  그 연결 파일을 모양 개수만큼 자동으로 만들어서 함께 넣는다.

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
try {
    foreach ($f in $folders) {
        $ns = $f.Name
        $added = 0

        function Put([string]$entryName, [string]$sourcePath) {
            $old = $archive.GetEntry($entryName)
            if ($old) { $old.Delete() }
            [void][System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
                $archive, $sourcePath, $entryName,
                [System.IO.Compression.CompressionLevel]::Optimal)
        }

        function PutText([string]$entryName, [string]$text) {
            $old = $archive.GetEntry($entryName)
            if ($old) { $old.Delete() }
            $e = $archive.CreateEntry($entryName, [System.IO.Compression.CompressionLevel]::Optimal)
            $sw = New-Object System.IO.StreamWriter($e.Open(), (New-Object System.Text.UTF8Encoding($false)))
            $sw.Write($text); $sw.Flush(); $sw.Dispose()
        }

        # 모양 파일 + 연결 파일
        $modelDir = Join-Path $f.FullName 'models'
        if (Test-Path $modelDir) {
            foreach ($m in Get-ChildItem -Path $modelDir -Filter *.json -File) {
                $id = [System.IO.Path]::GetFileNameWithoutExtension($m.Name)
                Put "assets/$ns/models/$($m.Name)" $m.FullName
                PutText "assets/$ns/items/$id.json" @"
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

        # 그림 파일 (mcmeta 포함)
        $texDir = Join-Path $f.FullName 'textures'
        if (Test-Path $texDir) {
            foreach ($t in Get-ChildItem -Path $texDir -File -Recurse) {
                $rel = $t.FullName.Substring($texDir.Length).TrimStart('\','/').Replace('\','/')
                Put "assets/$ns/textures/$rel" $t.FullName
            }
        }

        Write-Host "$ns : 모양 $added 개 넣음" -ForegroundColor Green
    }
} finally {
    $archive.Dispose()
}

$sha = (Get-FileHash -Algorithm SHA1 $Zip).Hash.ToLower()
Write-Host "DB.zip SHA-1 = $sha" -ForegroundColor Cyan
