<#
  공식 서버 채팅 아이콘(글꼴 taggame:ui)을 팩에 넣는다.

  ui-art\assets\ (ui-art\make-ui-art.ps1이 만든 것)를
    - DB.zip          (원본 팩)
    - DB_full.zip     (지인 서버 손님에게 내려가는 팩)
    - 지인 서버 plugins\DBPack\resourcepack\  (다음 번 ItemsAdder 합치기 때 살아남도록)
  세 곳에 모두 넣는다. (tab-pack.ps1과 같은 방식)
  공식 서버 팩(DB_official.zip)은 DB_full.zip에서 만들어지므로, 이 뒤에 official-pack.ps1을 돌리면 따라 들어간다.
#>
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

$Root     = $PSScriptRoot
$Src      = Join-Path $Root 'ui-art'
$Unpacked = 'C:\Users\dredr\OneDrive\문서\ServerEngine\servers\server_890160838\plugins\DBPack\resourcepack'

$files = [ordered]@{}
foreach ($f in Get-ChildItem (Join-Path $Src 'assets') -Recurse -File) {
    $files[$f.FullName.Substring($Src.Length + 1).Replace('\', '/')] = [IO.File]::ReadAllBytes($f.FullName)
}
if ($files.Count -eq 0) { throw "ui-art\assets가 비어 있습니다. make-ui-art.ps1을 먼저 돌리세요." }

function Add-ToZip($zipPath) {
    $zip = [IO.Compression.ZipFile]::Open($zipPath, 'Update')
    try {
        # 예전에 넣은 아이콘은 지우고 새로 넣는다 (조각 수가 바뀌어도 찌꺼기가 남지 않게)
        foreach ($old in @($zip.Entries | Where-Object { $_.FullName -like 'assets/taggame/textures/font/ui/*' -or $_.FullName -eq 'assets/taggame/font/ui.json' })) { $old.Delete() }
        foreach ($name in $files.Keys) {
            $e = $zip.CreateEntry($name)
            $s = $e.Open(); $s.Write($files[$name], 0, $files[$name].Length); $s.Dispose()
        }
    } finally { $zip.Dispose() }
    Write-Host ("  " + (Split-Path $zipPath -Leaf) + " : " + $files.Count + "개 반영")
}

Add-ToZip (Join-Path $Root 'DB.zip')
Add-ToZip (Join-Path $Root 'DB_full.zip')

if (Test-Path $Unpacked) {
    foreach ($name in $files.Keys) {
        $dest = Join-Path $Unpacked ($name -replace '/', '\')
        New-Item -ItemType Directory -Force (Split-Path $dest) | Out-Null
        [IO.File]::WriteAllBytes($dest, $files[$name])
    }
    Write-Host ("  풀어 둔 팩 : " + $files.Count + "개 반영")
}
