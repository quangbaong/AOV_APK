@echo off
chcp 65001 >nul
powershell -NoProfile -ExecutionPolicy Bypass -Command "$outDir = '%~dp0'.TrimEnd('\'); $s = Get-Content -LiteralPath '%~f0' -Encoding UTF8 | Select-Object -Skip 5; Invoke-Expression ($s -join \"`n\")"
pause
exit /b
$ErrorActionPreference = "Continue"
$pkg = "com.garena.game.kgvn"
$adbCandidates = @(
    (Get-Process adb -ErrorAction SilentlyContinue | Select-Object -First 1).Path,
    (Get-Process dnplayer -ErrorAction SilentlyContinue | ForEach-Object { Join-Path (Split-Path $_.Path) "adb.exe" } | Select-Object -First 1),
    "P:\LDPlayer\LDPlayer14\adb.exe",
    "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
) | Where-Object { $_ -and (Test-Path $_) }
$adb = if ($adbCandidates) { $adbCandidates[0] } else { "adb" }

Write-Host "[*] Ket noi ADB ($adb)..." -ForegroundColor Cyan
$devLines = & $adb devices | Select-String "\s+device$" | ForEach-Object { ($_.Line -split "\s+")[0] }
$dev = ($devLines | Where-Object { $_ -like "emulator-*" } | Select-Object -First 1)
if (-not $dev) { $dev = $devLines | Select-Object -First 1 }
if (-not $dev) {
    Write-Host "[!] Khong tim thay thiet bi/gia lap ADB nao dang chay!" -ForegroundColor Red
    exit 1
}
Write-Host "[*] Su dung thiet bi: $dev" -ForegroundColor Cyan
& $adb -s $dev root | Out-Null
& $adb -s $dev wait-for-device

$remoteLib = (& $adb -s $dev shell "find /data/data/$pkg/files/Resources -name libil2cpp.so 2>/dev/null" | Select-Object -First 1)
if ($remoteLib) { $remoteLib = $remoteLib.Trim() }
if (-not $remoteLib) {
    Write-Host "[!] Khong tim thay libil2cpp.so! Hay mo game Lien Quan it nhat 1 lan." -ForegroundColor Red
    exit 1
}
$resRoot = $remoteLib -replace "/arm[^/]+/libil2cpp\.so$", ""
$remoteMeta = "$resRoot/Managed/Metadata/global-metadata.dat"

$outLib = Join-Path $outDir "libil2cpp.so"
$outMeta = Join-Path $outDir "global-metadata.dat"

Write-Host "[*] Dang keo libil2cpp.so va global-metadata.dat ve may..." -ForegroundColor Cyan
& $adb -s $dev pull $remoteLib $outLib
& $adb -s $dev pull $remoteMeta $outMeta

# Giai ma 256 bytes dau cua global-metadata.dat (0xEAB11BAF -> 0xFAB11BAF, v29)
$metaBytes = [System.IO.File]::ReadAllBytes($outMeta)
$magic = [int64][System.BitConverter]::ToUInt32($metaBytes, 0)
if ($magic -eq 0xEAB11BAFL) {
    $inHdr = New-Object uint32[] 64
    $outHdr = New-Object uint32[] 64
    for ($i = 0; $i -lt 64; $i++) {
        $inHdr[$i] = [System.BitConverter]::ToUInt32($metaBytes, $i * 4)
        $outHdr[$i] = $inHdr[$i]
    }
    $map = @(4, 8, 12, 16, 20, 6, 10, 14, 18, 22, 2, 48, 46, 44, 42, 24, 28, 32, 36, 40, 26, 30, 34, 38)
    for ($k = 0; $k -lt 24; $k++) {
        $inIdx  = 2 + (2 * $k)
        $outIdx = $map[$k]
        $v0 = [int64]$inHdr[$inIdx]
        $v1 = [int64]$inHdr[$inIdx + 1]
        $outHdr[$outIdx]     = [uint32]((($v0 - (3 * $k)) -band 0xFFFFFFFFL) -bxor (0x00A8C72DL + $k))
        $outHdr[$outIdx + 1] = [uint32]((($v1 - (7 * $k)) -band 0xFFFFFFFFL) -bxor (0x00A8C72DL + (2 * $k)))
    }
    $outHdr[0] = [uint32]0xFAB11BAFL
    $outHdr[1] = [uint32]29
    for ($i = 0; $i -lt 64; $i++) {
        [Array]::Copy([System.BitConverter]::GetBytes($outHdr[$i]), 0, $metaBytes, $i * 4, 4)
    }
    [System.IO.File]::WriteAllBytes($outMeta, $metaBytes)
    Write-Host "[+] Da giai ma global-metadata.dat (0xFAB11BAF, v29)" -ForegroundColor Green
}

# Lay .rodata va .text da giai ma tu RAM cua game
$pidStr = (& $adb -s $dev shell "pidof $pkg" 2>$null | Out-String).Trim()
if (-not $pidStr) {
    Write-Host "[*] Dang mo game Lien Quan de giai ma .rodata & .text..." -ForegroundColor Yellow
    & $adb -s $dev shell "monkey -p $pkg -c android.intent.category.LAUNCHER 1" | Out-Null
    for ($i = 0; $i -lt 15; $i++) {
        Start-Sleep -Seconds 1
        $pidStr = (& $adb -s $dev shell "pidof $pkg" 2>$null | Out-String).Trim()
        if ($pidStr) { Start-Sleep -Seconds 5; break }
    }
}

if ($pidStr) {
    $gamePid = ($pidStr -split "\s+")[0]
    $libBytes = [System.IO.File]::ReadAllBytes($outLib)
    $e_phoff = [int64][System.BitConverter]::ToUInt64($libBytes, 32)
    $e_phnum = [int][System.BitConverter]::ToUInt16($libBytes, 56)
    $loads = @()
    for ($i = 0; $i -lt $e_phnum; $i++) {
        $p = [int]$e_phoff + ($i * 56)
        $p_type = [System.BitConverter]::ToUInt32($libBytes, $p)
        if ($p_type -eq 1) {
            $loads += [PSCustomObject]@{
                offset = [int64][System.BitConverter]::ToUInt64($libBytes, $p + 8)
                vaddr  = [int64][System.BitConverter]::ToUInt64($libBytes, $p + 16)
                filesz = [int64][System.BitConverter]::ToUInt64($libBytes, $p + 32)
            }
        }
    }
    $ph_ro = $loads[0]
    $ph_tx = $loads[1]
    $txPageOff = [int64]([Math]::Floor($ph_tx.offset / 4096) * 4096)
    $txOffHex = "{0:x8}" -f $txPageOff
    $maps = (& $adb -s $dev shell "grep libil2cpp.so /proc/$gamePid/maps") -split "`r?`n"
    $baseAddr = [int64]0
    for ($i = 1; $i -lt $maps.Count; $i++) {
        if ($maps[$i] -match $txOffHex) {
            $baseAddr = [Convert]::ToInt64(($maps[$i - 1] -split "-")[0], 16)
            break
        }
    }
    if ($baseAddr -gt 0) {
        $roStart  = [int64]0x1600000
        $roLen    = [int]($ph_ro.filesz - $roStart)
        $roAddrAl = [int64]([Math]::Floor(($baseAddr + $roStart) / 65536) * 65536)
        $roPad    = [int](($baseAddr + $roStart) - $roAddrAl)
        $roSkip   = [int64]($roAddrAl / 65536)
        $roCnt    = [int64]([Math]::Floor(($roLen + $roPad + 65535) / 65536))

        $txAddrAl = [int64]([Math]::Floor(($baseAddr + $ph_tx.vaddr) / 65536) * 65536)
        $txPad    = [int](($baseAddr + $ph_tx.vaddr) - $txAddrAl)
        $txLen    = [int]$ph_tx.filesz
        $txSkip   = [int64]($txAddrAl / 65536)
        $txCnt    = [int64]([Math]::Floor(($txLen + $txPad + 65535) / 65536))

        Write-Host "[*] Dang giai ma .rodata & .text cua libil2cpp.so..." -ForegroundColor Cyan
        & $adb -s $dev shell "toybox dd if=/proc/$gamePid/mem of=/data/local/tmp/ro.bin bs=65536 skip=$roSkip count=$roCnt 2>/dev/null && toybox dd if=/proc/$gamePid/mem of=/data/local/tmp/tx.bin bs=65536 skip=$txSkip count=$txCnt 2>/dev/null"
        $roTmp = Join-Path $outDir "ro.bin"
        $txTmp = Join-Path $outDir "tx.bin"
        & $adb -s $dev pull /data/local/tmp/ro.bin $roTmp | Out-Null
        & $adb -s $dev pull /data/local/tmp/tx.bin $txTmp | Out-Null
        & $adb -s $dev shell "rm -f /data/local/tmp/ro.bin /data/local/tmp/tx.bin" | Out-Null

        $roData = [System.IO.File]::ReadAllBytes($roTmp)
        $txData = [System.IO.File]::ReadAllBytes($txTmp)
        [Array]::Copy($roData, $roPad, $libBytes, [int]$roStart, $roLen)
        [Array]::Copy($txData, $txPad, $libBytes, [int]$ph_tx.offset, $txLen)
        Remove-Item -Force $roTmp, $txTmp -ErrorAction SilentlyContinue
        [System.IO.File]::WriteAllBytes($outLib, $libBytes)
        Write-Host "[+] Da giai ma hoan tat libil2cpp.so!" -ForegroundColor Green
    }
}
Write-Host "`n[OK] Hoan tat! Mo Il2CppDumper GUI va bam Start Dump." -ForegroundColor Yellow
