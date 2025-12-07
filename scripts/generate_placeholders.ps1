# Generates small PNG placeholder files for testing
$files = @(
  "example-exercise-00\week-04-excercise-01\week-04-exercise-01-template\apple-dot-com-but-with-papyrus-font.png",
  "example-exercise-00\week-04-exercise-02\week-04-exercise-02-template\Daft_Punk_-_Discovery(image 1).png",
  "example-exercise-00\week-04-exercise-02\week-04-exercise-02-template\daftpunk_homework_(image 2).png",
  "example-exercise-00\week-04-exercise-02\week-04-exercise-02-template\longlegs (Image 4).png",
  "example-exercise-00\week-04-exercise-02\week-04-exercise-02-template\midsommar (image 3).png",
  "example-exercise-00\week-04-exercise-02\week-04-exercise-02-template\one tree hill (image 6).png",
  "example-exercise-00\week-04-exercise-02\week-04-exercise-02-template\Season_11_Poster (image 5).png"
)

# A tiny 1x1 transparent PNG in base64 (safe placeholder).
$pngBase64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR4nGNgYAAAAAMAAWgmWQ0AAAAASUVORK5CYII='
$bytes = [System.Convert]::FromBase64String($pngBase64)

$root = Get-Location
foreach ($f in $files) {
  $path = Join-Path $root.Path $f
  $dir = Split-Path $path -Parent
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  [System.IO.File]::WriteAllBytes($path, $bytes)
  Write-Host "Created placeholder: $path"
}

Write-Host "Done. Created $($files.Count) placeholder images."
