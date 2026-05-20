# ============================================================
#  520 Page · GitHub Pages 一键部署脚本
#  使用方法: 右键此文件 -> "使用 PowerShell 运行"
#  或者在终端中执行: .\deploy.ps1
# ============================================================

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

Write-Host ""
Write-Host "╔══════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║    520 I LOVE YOU · GitHub Pages 一键部署    ║" -ForegroundColor Magenta
Write-Host "╚══════════════════════════════════════════════╝" -ForegroundColor Magenta
Write-Host ""

# ---- Step 0: 环境检查 ----
Write-Host "[Step 0/5] 检查运行环境..." -ForegroundColor Cyan

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "  [ERROR] 未检测到 Git，请先安装: https://git-scm.com/download/win" -ForegroundColor Red
    pause
    exit 1
}
Write-Host "  [OK] Git 版本: $(git --version)" -ForegroundColor Green

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Host "  [WARN] 未检测到 GitHub CLI (gh)。" -ForegroundColor Yellow
    Write-Host "  你可以选择:" -ForegroundColor Yellow
    Write-Host "    A) 安装 gh 后重新运行本脚本: winget install GitHub.cli" -ForegroundColor Yellow
    Write-Host "    B) 手动在 GitHub 上创建仓库，然后继续推送" -ForegroundColor Yellow
    $autoCreateRepo = $false
} else {
    Write-Host "  [OK] GitHub CLI 版本: $(gh --version | Select-Object -First 1)" -ForegroundColor Green
    $autoCreateRepo = $true

    $ghAuth = gh auth status 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  [WARN] 未登录 GitHub CLI，正在启动登录..." -ForegroundColor Yellow
        gh auth login
        if ($LASTEXITCODE -ne 0) {
            Write-Host "  [ERROR] GitHub CLI 登录失败，请重试。" -ForegroundColor Red
            pause
            exit 1
        }
    }
    Write-Host "  [OK] GitHub CLI 已登录" -ForegroundColor Green
}

# ---- Step 1: 初始化 Git 仓库 ----
Write-Host ""
Write-Host "[Step 1/5] 初始化 Git 仓库..." -ForegroundColor Cyan

if (Test-Path ".git") {
    Write-Host "  [INFO] Git 仓库已存在，跳过初始化。" -ForegroundColor Yellow
} else {
    git init
    Write-Host "  [OK] Git 仓库初始化完成。" -ForegroundColor Green
}

# ---- Step 2: 配置 .gitignore ----
Write-Host ""
Write-Host "[Step 2/5] 配置 .gitignore..." -ForegroundColor Cyan

$gitignoreContent = @'
# 操作系统
Thumbs.db
Desktop.ini
.DS_Store

# 编辑器
.vscode/
.idea/
*.swp
*.swo

# 脚本输出
*.log

# 临时文件
tmp/
temp/
'@

$gitignorePath = Join-Path $scriptDir ".gitignore"
if (-not (Test-Path $gitignorePath)) {
    Set-Content -Path $gitignorePath -Value $gitignoreContent -Encoding UTF8
    Write-Host "  [OK] .gitignore 已创建。" -ForegroundColor Green
} else {
    Write-Host "  [INFO] .gitignore 已存在，跳过。" -ForegroundColor Yellow
}

# ---- Step 3: 创建 / 确认 GitHub 仓库 ----
Write-Host ""
Write-Host "[Step 3/5] 准备 GitHub 远程仓库..." -ForegroundColor Cyan

$repoName = "520-love-page"
$repoVisibility = "public"

$remoteUrl = git remote get-url origin 2>$null
if ($remoteUrl) {
    Write-Host "  [INFO] 远程仓库 origin 已配置: $remoteUrl" -ForegroundColor Yellow
} else {
    if ($autoCreateRepo) {
        Write-Host "  正在创建 GitHub 仓库: $repoName (公开)..." -ForegroundColor White
        try {
            gh repo create $repoName --$repoVisibility --source=. --remote=origin --push=$false
            Write-Host "  [OK] GitHub 仓库已创建: https://github.com/$(gh api user --jq '.login')/$repoName" -ForegroundColor Green
        } catch {
            Write-Host "  [ERROR] 创建仓库失败: $_" -ForegroundColor Red
            Write-Host "  请手动在 https://github.com/new 创建仓库，然后运行:" -ForegroundColor Yellow
            Write-Host "    git remote add origin https://github.com/你的用户名/$repoName.git" -ForegroundColor Yellow
            pause
            exit 1
        }
    } else {
        Write-Host "  [WARN] 无法自动创建仓库。请手动操作:" -ForegroundColor Yellow
        Write-Host "    1. 打开 https://github.com/new" -ForegroundColor Yellow
        Write-Host "    2. 仓库名: $repoName" -ForegroundColor Yellow
        Write-Host "    3. 设为 Public (公开)" -ForegroundColor Yellow
        Write-Host "    4. 不要勾选 'Add a README file'" -ForegroundColor Yellow
        Write-Host "    5. 创建后在此输入仓库地址:" -ForegroundColor Yellow
        $manualUrl = Read-Host "  请输入仓库地址 (如 https://github.com/用户名/$repoName.git)"
        if ($manualUrl) {
            git remote add origin $manualUrl
            Write-Host "  [OK] 远程仓库已配置。" -ForegroundColor Green
        } else {
            Write-Host "  [ERROR] 未输入有效地址，脚本终止。" -ForegroundColor Red
            pause
            exit 1
        }
    }
}

# ---- Step 4: 提交并推送代码 ----
Write-Host ""
Write-Host "[Step 4/5] 提交并推送代码..." -ForegroundColor Cyan

$staged = git status --porcelain
if (-not $staged) {
    Write-Host "  [INFO] 没有需要提交的变更。" -ForegroundColor Yellow
} else {
    git add -A
    $commitMsg = "520 Love Page - Initial Deploy"
    git commit -m $commitMsg
    Write-Host "  [OK] 代码已提交: $commitMsg" -ForegroundColor Green
}

$currentBranch = git branch --show-current
if (-not $currentBranch) {
    git checkout -b main
    $currentBranch = "main"
    Write-Host "  [INFO] 已创建并切换到 main 分支。" -ForegroundColor Yellow
}

if ($currentBranch -ne "main") {
    Write-Host "  [INFO] 当前分支为 '$currentBranch'，正在切换到 main..." -ForegroundColor Yellow
    git branch -M main
}

Write-Host "  正在推送到 GitHub (可能需要输入凭据)..." -ForegroundColor White
try {
    git push -u origin main
    Write-Host "  [OK] 代码已成功推送到 GitHub！" -ForegroundColor Green
} catch {
    Write-Host "  [WARN] 推送失败。可能是认证问题，请尝试:" -ForegroundColor Yellow
    Write-Host "    1. 使用 gh auth login 重新登录" -ForegroundColor Yellow
    Write-Host "    2. 或使用 Personal Access Token: git push -u origin main" -ForegroundColor Yellow
    Write-Host "  错误详情: $_" -ForegroundColor Red
    pause
    exit 1
}

# ---- Step 5: 启用 GitHub Pages ----
Write-Host ""
Write-Host "[Step 5/5] 配置 GitHub Pages 自动部署..." -ForegroundColor Cyan

if ($autoCreateRepo) {
    try {
        $owner = gh api user --jq '.login'
        Write-Host "  正在为仓库启用 GitHub Pages (Actions 方式)..." -ForegroundColor White

        gh api -X PUT "/repos/$owner/$repoName/pages" --input - <<EOF | Out-Null
{
  "source": {
    "branch": "main",
    "path": "/"
  },
  "build_type": "workflow"
}
EOF

        Write-Host "  [OK] GitHub Pages 已启用！" -ForegroundColor Green
        Write-Host ""
        Write-Host "  [INFO] GitHub Actions 将自动构建并部署。" -ForegroundColor White
        Write-Host "  部署完成后，访问地址为:" -ForegroundColor White
        Write-Host ""
        Write-Host "    https://$owner.github.io/$repoName/" -ForegroundColor Green
        Write-Host ""
    } catch {
        Write-Host "  [INFO] 正在通过 API 配置 Pages..." -ForegroundColor Yellow
        Write-Host "  如果失败，请手动在仓库 Setting > Pages 中:" -ForegroundColor Yellow
        Write-Host "    - Source: GitHub Actions" -ForegroundColor Yellow
    }
}

# ---- 完成 ----
$owner = "你的用户名"
if ($autoCreateRepo) {
    try { $owner = gh api user --jq '.login' } catch {}
}

Write-Host ""
Write-Host "╔══════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║              🎉 部署流程完成！                ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "  预计 1-3 分钟后可通过以下地址访问:" -ForegroundColor White
Write-Host ""
Write-Host "    https://$owner.github.io/$repoName/" -ForegroundColor Cyan
Write-Host ""
Write-Host "  查看部署状态:" -ForegroundColor White
if ($autoCreateRepo) {
    Write-Host "    https://github.com/$owner/$repoName/actions" -ForegroundColor White
} else {
    Write-Host "    打开你的 GitHub 仓库 -> Actions 标签页" -ForegroundColor White
}
Write-Host ""
Write-Host "  按任意键退出..." -ForegroundColor Gray
pause
