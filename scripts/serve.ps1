$Root = (Get-Location).ProviderPath
$prefix = 'http://localhost:8765/'
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($prefix)
$listener.Start()
Write-Host "Serving $Root on $prefix (stop with Ctrl-C in the terminal)"
$mime = @{
  '.html'='text/html'
  '.htm'='text/html'
  '.css'='text/css'
  '.js'='application/javascript'
  '.json'='application/json'
  '.png'='image/png'
  '.jpg'='image/jpeg'
  '.jpeg'='image/jpeg'
  '.gif'='image/gif'
  '.svg'='image/svg+xml'
  '.webp'='image/webp'
  '.avif'='image/avif'
  '.txt'='text/plain'
}
try {
  while ($listener.IsListening) {
    $ctx = $listener.GetContext()
    $req = $ctx.Request
    # URL-decode the requested path so files with spaces/parentheses resolve correctly
    $path = [System.Uri]::UnescapeDataString($req.Url.AbsolutePath).TrimStart('/')
    if ($path -eq '') { $path = 'index.html' }
    $filePath = Join-Path $Root $path
    # If the path is a directory, serve its index.html
    if (Test-Path $filePath -PathType Container) {
      $filePath = Join-Path $filePath 'index.html'
    }
    if (Test-Path $filePath) {
      $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
      $type = $mime[$ext]
      if (-not $type) { $type = 'application/octet-stream' }
      $bytes = [System.IO.File]::ReadAllBytes($filePath)
      $ctx.Response.ContentType = $type
      $ctx.Response.ContentLength64 = $bytes.Length
      $ctx.Response.OutputStream.Write($bytes,0,$bytes.Length)
    } else {
      $ctx.Response.StatusCode = 404
      $msg = "404 Not Found"
      $b = [System.Text.Encoding]::UTF8.GetBytes($msg)
      $ctx.Response.ContentType = 'text/plain'
      $ctx.Response.ContentLength64 = $b.Length
      $ctx.Response.OutputStream.Write($b,0,$b.Length)
    }
    $ctx.Response.OutputStream.Close()
  }
}
finally {
  $listener.Stop()
  $listener.Close()
}
