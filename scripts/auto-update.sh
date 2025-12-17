#!/bin/bash

# Coding-Tool 自动更新脚本
# 从 GitHub 拉取最新代码并重新构建 Docker 镜像

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
UPSTREAM_REPO="https://github.com/CooperJiang/cc-tool.git"

cd "$PROJECT_DIR"

echo "🔍 检查更新..."

# 确保 upstream 远程存在
if ! git remote | grep -q upstream; then
    echo "📦 添加上游仓库..."
    git remote add upstream "$UPSTREAM_REPO"
fi

# 获取上游更新
git fetch upstream

# 获取当前和上游的 commit
LOCAL=$(git rev-parse HEAD)
UPSTREAM=$(git rev-parse upstream/main 2>/dev/null || git rev-parse upstream/master)

if [ "$LOCAL" = "$UPSTREAM" ]; then
    echo "✅ 已是最新版本，无需更新"
    exit 0
fi

echo "📥 发现新版本，正在更新..."

# 保存本地修改
git stash

# 合并上游更新
git merge upstream/main --no-edit 2>/dev/null || git merge upstream/master --no-edit

# 恢复本地修改
git stash pop 2>/dev/null || true

# 获取新版本号
NEW_VERSION=$(node -p "require('./package.json').version")
echo "📦 新版本: $NEW_VERSION"

# 重新构建 Docker 镜像
echo "🔨 重新构建 Docker 镜像..."
docker-compose build --no-cache

# 重启容器
echo "🔄 重启容器..."
docker-compose up -d

echo "✅ 更新完成！新版本: $NEW_VERSION"
echo "🌐 访问 http://localhost:10099 查看"
