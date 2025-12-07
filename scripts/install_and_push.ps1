# Attempt to install Git (winget -> choco) and then commit & push changes
# WARNING: Installing software may require admin rights.
$ErrorActionPreference = 'Stop'

function WriteOk($m){ Write-Host "[OK] $m" -ForegroundColor Green }
function WriteErr($m){ Write-Host "[ERR] $m" -ForegroundColor Red }

# Check git
try {
  & git --version | Out-Null
  WriteOk "Git already installed"
} catch {
  Write-Host "Git not found. Attempting to install..."
  # Try winget
  $installed = $false
  try {
    & winget --version | Out-Null
    Write-Host "winget found — installing Git via winget (may require consent)..."
    & winget install --id Git.Git -e --accept-source-agreements --accept-package-agreements
    $installed = $true
  } catch {
    Write-Host "winget not available or install failed: $_"
  }

  if (-not $installed) {
    try {
      & choco -v | Out-Null
      Write-Host "choco found — installing Git via choco (may require admin)..."
      & choco install git -y
      $installed = $true
    } catch {
      Write-Host "choco not available or install failed: $_"
    }
  }

  if (-not $installed) {
    WriteErr "Could not install Git automatically. Please install Git manually and re-run this script."
    exit 2
  }

  # verify
  try { & git --version; WriteOk "Git installed." } catch { WriteErr "Git still not available after install."; exit 3 }
}

# Now in repo, attempt commit & push
Push-Location (Get-Location)
try {
  # ensure inside a git repo
  $isRepo = $false
  try { & git rev-parse --is-inside-work-tree > $null; $isRepo = $true } catch { $isRepo = $false }
  if (-not $isRepo) { WriteErr "Current folder is not a git repository."; exit 4 }

  # Show status
  & git status --porcelain

  # Stage changes
  & git add .

  # Commit
  $msg = 'Fix: replace empty hrefs, add placeholders and CSS; update serve/devtools scripts'
  try {
    & git commit -m $msg
    WriteOk "Committed changes with message: $msg"
  } catch {
    WriteHost "No changes to commit or commit failed: $_"
  }

  # Check remote
  try {
    & git remote -v
    WriteHost "Attempting to push to remote (current branch)..."
    & git rev-parse --abbrev-ref HEAD | ForEach-Object { $branch = $_ }
    & git push origin $branch
    WriteOk "Push completed (may have required credentials)."
  } catch {
    WriteErr "Push failed: $_"
  }
} finally {
  Pop-Location
}
