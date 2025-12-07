# DevTools-like check: fetch pages and validate all resource links
$baseUrl = "http://localhost:8001"
$pages = @(
  "/",
  "/example-exercise-00/",
  "/example-exercise-00/week-04-excercise-01/week-04-exercise-01-template/",
  "/example-exercise-00/week-04-exercise-02/week-04-exercise-02-template/",
  "/example-exercise-00/week-06-exercise-01/week-06-exercise-01-template/",
  "/example-exercise-00/week-06-exercise-01/week-06-exercise-01-template/gallery/",
  "/example-project-00/",
  "/week-01-exercise-01/",
  "/assignment-01/"
)

$issues = @()

foreach ($page in $pages) {
  $url = "$baseUrl$page"
  Write-Host "Checking: $url"
  
  try {
    $response = Invoke-WebRequest -Uri $url -UseBasicParsing -ErrorAction Stop
    $html = $response.Content
    
    # Extract resource URLs from href and src attributes
    $regex = [regex] '(?:href|src)\s*=\s*["\x27]([^"\x27]+)["\x27]'
    $matches = $regex.Matches($html)
    
    foreach ($match in $matches) {
      $resourceUrl = $match.Groups[1].Value
      
      # Skip absolute URLs, anchors, mailto, etc.
      if ($resourceUrl -match '^(https?:|mailto:|tel:|javascript:|data:|#)') { continue }
      if ($resourceUrl -eq '') { continue }
      
      # Build absolute URL for the resource
      $resourceFullUrl = $resourceUrl
      if ($resourceUrl -match '^/') {
        $resourceFullUrl = "$baseUrl$resourceUrl"
      } else {
        # Relative URL - resolve from page URL
        $pageBase = $url -replace '[^/]*$'
        $resourceFullUrl = "$pageBase$resourceUrl"
        # Simple path normalization
        $resourceFullUrl = $resourceFullUrl -replace '/\./', '/'
        while ($resourceFullUrl -match '/[^/]+/\.\.') {
          $resourceFullUrl = $resourceFullUrl -replace '/[^/]+/\.\.', ''
        }
      }
      
      # Test the resource
      try {
        $resourceResponse = Invoke-WebRequest -Uri $resourceFullUrl -UseBasicParsing -ErrorAction Stop
        if ($resourceResponse.StatusCode -ne 200) {
          $issues += @{Page = $url; Resource = $resourceUrl; FullUrl = $resourceFullUrl; Status = $resourceResponse.StatusCode }
        }
      } catch {
        $statusCode = if ($_.Exception.Response.StatusCode) { $_.Exception.Response.StatusCode.value__ } else { "Network Error" }
        $issues += @{Page = $url; Resource = $resourceUrl; FullUrl = $resourceFullUrl; Status = $statusCode }
      }
    }
    Write-Host "  ✓ Page loaded; checked resources."
  } catch {
    $statusCode = if ($_.Exception.Response.StatusCode) { $_.Exception.Response.StatusCode.value__ } else { "Connection Error" }
    Write-Host "  ✗ Page failed (Status: $statusCode)"
    $issues += @{Page = $url; Resource = "(page itself)"; FullUrl = $url; Status = $statusCode }
  }
}

# Report
Write-Host "`n=== DevTools Report ===" -ForegroundColor Cyan
if ($issues.Count -eq 0) {
  Write-Host "✓ No 404s or errors found!" -ForegroundColor Green
} else {
  Write-Host "Found $($issues.Count) broken resource(s):" -ForegroundColor Yellow
  $issues | ForEach-Object {
    Write-Host "  Page: $($_.Page)" -ForegroundColor Yellow
    Write-Host "    Resource: $($_.Resource)" -ForegroundColor Gray
    Write-Host "    Status: $($_.Status)" -ForegroundColor Red
  }
}
