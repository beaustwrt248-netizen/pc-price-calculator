$ErrorActionPreference = 'SilentlyContinue'

$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1 -ExpandProperty Name
$gpus = Get-CimInstance Win32_VideoController | Where-Object { $_.Name -and $_.Name -notmatch 'Microsoft Basic|Remote|Virtual' } | Select-Object -ExpandProperty Name -Unique
$ramBytes = (Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum).Sum
$ramGB = if ($ramBytes) { [math]::Round($ramBytes / 1GB) } else { 0 }
$ramSpeed = Get-CimInstance Win32_PhysicalMemory | Where-Object Speed | Select-Object -First 1 -ExpandProperty Speed
$board = Get-CimInstance Win32_BaseBoard | Select-Object -First 1
$drives = Get-CimInstance Win32_DiskDrive | Where-Object { $_.Size -gt 0 } | ForEach-Object {
  $sizeGB = [math]::Round($_.Size / 1GB)
  [PSCustomObject]@{ Model = $_.Model; SizeGB = $sizeGB; MediaType = $_.MediaType }
}

$lines = @()
if ($cpu) { $lines += "CPU: $cpu" }
foreach ($gpu in $gpus) { $lines += "GPU: $gpu" }
if ($ramGB -gt 0) {
  $ramText = "RAM: ${ramGB}GB"
  if ($ramSpeed) { $ramText += " ${ramSpeed}MHz" }
  $lines += $ramText
}
if ($board.Manufacturer -or $board.Product) { $lines += "Motherboard: $($board.Manufacturer) $($board.Product)".Trim() }
foreach ($d in $drives) { $lines += "Storage: $($d.SizeGB)GB $($d.Model)" }

$lines += "Note: PSU, case and CPU cooler usually cannot be identified reliably by Windows software."

$output = $lines -join [Environment]::NewLine
Write-Host ""
Write-Host "=== PC PRICE CALCULATOR DEVICE SCAN ===" -ForegroundColor Cyan
Write-Host $output
Write-Host "=======================================" -ForegroundColor Cyan

try {
  Set-Clipboard -Value $output
  Write-Host "Scan copied to clipboard. Paste it into the PC Price Calculator." -ForegroundColor Green
} catch {
  Write-Host "Copy the scan above and paste it into the PC Price Calculator." -ForegroundColor Yellow
}

Read-Host "Press Enter to close"