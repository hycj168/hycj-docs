# 🏢 企业级 Git 操作使用指南

## 📋 文档概述

本指南为企业开发团队提供全面的 **Git** 版本控制系统操作规范，涵盖从**基础操作**到**高级工作流**
的完整流程，确保团队协作高效、代码质量可控、版本管理规范。

## 🎯 目标读者

- 企业开发团队成员
- 项目经理和技术负责人
- DevOps 工程师
- 新入职开发人员

---

## 📚 目录

1. [基础配置与环境搭建](#1-基础配置与环境搭建)
2. [分支管理策略](#2-分支管理策略)
3. [日常工作流程](#3-日常工作流程)
4. [代码审查规范](#4-代码审查规范)
5. [版本发布管理](#5-版本发布管理)
6. [协作最佳实践](#6-协作最佳实践)
7. [故障排除指南](#7-故障排除指南)
8. [安全与权限管理](#8-安全与权限管理)

---

## 1. 基础配置与环境搭建

### 1.1 Git 基础配置

#### 用户身份配置

```bash
# 设置全局用户信息（企业统一规范）
git config --global user.name "张三"  # 使用真实姓名
git config --global user.email "zhangsan@company.com"  # 企业邮箱
git config --global core.editor "code --wait"  # VS Code 作为默认编辑器

# 验证配置
git config --list --global
```

#### 企业级 Git 配置模板

```bash
# 创建企业级 Git 配置文件
cat > ~/.gitconfig-enterprise << 'EOF'
[user]
    name = 您的姓名
    email = 您的邮箱@company.com
[core]
    editor = code --wait
    autocrlf = false
    safecrlf = true
[push]
    default = simple
[pull]
    rebase = false
[alias]
    st = status
    co = checkout
    br = branch
    ci = commit
    unstage = reset HEAD --
    last = log -1 HEAD
    visual = !gitk
[color]
    ui = auto
    branch = auto
    diff = auto
    status = auto
[merge]
    tool = vscode
[mergetool "vscode"]
    cmd = code --wait $MERGED
[diff]
    tool = vscode
[difftool "vscode"]
    cmd = code --wait --diff $LOCAL $REMOTE
EOF

# 应用企业配置
git config --global include.path ~/.gitconfig-enterprise
```

### 1.2 SSH 密钥配置

#### 生成 SSH 密钥对

```bash
# 生成 RSA 4096 位密钥
ssh-keygen -t rsa -b 4096 -C "your.email@company.com" -f ~/.ssh/id_rsa_company

# 或者生成 Ed25519 密钥（更安全）
ssh-keygen -t ed25519 -C "your.email@company.com" -f ~/.ssh/id_ed25519_company
```

#### 配置 SSH 主机别名

```bash
# 编辑 SSH 配置文件
cat >> ~/.ssh/config << 'EOF'
# 公司 GitLab
Host company-gitlab
    HostName gitlab.company.com
    User git
    IdentityFile ~/.ssh/id_rsa_company
    PreferredAuthentications publickey
    
# 公司 GitHub Enterprise
Host company-github
    HostName github.company.com
    User git
    IdentityFile ~/.ssh/id_ed25519_company
    PreferredAuthentications publickey
EOF

# 设置权限
chmod 600 ~/.ssh/config
```

### 1.3 仓库初始化规范

#### 新项目初始化流程

```bash
# 1. 在远程仓库平台创建项目（GitLab/GitHub）
# 2. 本地初始化项目
mkdir project-name && cd project-name
git init

# 3. 创建基础文件结构
echo "# Project Name" > README.md
echo "node_modules/\n.env\n*.log\ndist/\nbuild/" > .gitignore

# 4. 添加企业级 .gitignore 模板
curl -o .gitignore https://raw.githubusercontent.com/github/gitignore/main/Node.gitignore

# 5. 初始提交
git add .
git commit -m "Initial commit: Project setup with enterprise standards"

# 6. 添加远程仓库
git remote add origin git@company-gitlab:team/project-name.git

# 7. 推送初始代码
git push -u origin master
```

---

## 2. 分支管理策略

### 2.1 Git Flow 工作流

#### 分支结构说明

```
master (生产分支)
  ↑
develop (开发分支)
  ↑ ↑ ↑
feature/* (功能分支)  release/* (发布分支)  hotfix/* (热修复分支)
```

#### 分支命名规范

```bash
# 功能分支
feature/JIRA-123-user-authentication
feature/add-payment-gateway
feature/update-user-profile

# 发布分支
release/v1.2.0
release/2025-q1-release

# 热修复分支
hotfix/fix-login-error
hotfix/patch-security-vulnerability

# 紧急修复
hotfix/urgent-payment-fix
```

### 2.2 分支操作规范

#### 创建功能分支

```bash
# 1. 确保在 develop 分支
git checkout develop
git pull origin develop

# 2. 创建新的功能分支
git checkout -b feature/JIRA-456-api-integration

# 3. 推送分支到远程
git push -u origin feature/JIRA-456-api-integration
```

#### 分支同步策略

```bash
# 定期同步 develop 分支的最新更改
git checkout feature/JIRA-456-api-integration
git fetch origin
git merge origin/develop

# 或者使用 rebase 保持线性历史
git pull --rebase origin develop
```

---

## 3. 日常工作流程

### 3.1 标准开发流程

#### 每日开发工作流

```bash
# 1. 开始工作 - 同步最新代码
git checkout develop
git pull origin develop

# 2. 创建或切换到功能分支
git checkout -b feature/JIRA-789-new-dashboard
# 或者
git checkout feature/JIRA-789-new-dashboard
git pull origin feature/JIRA-789-new-dashboard

# 3. 进行开发工作
# ... 编写代码 ...

# 4. 查看更改状态
git status
git diff

# 5. 添加更改到暂存区
git add -A  # 添加所有更改
git add -p  # 交互式添加，选择特定更改

# 6. 提交更改
git commit -m "feat: add user dashboard with real-time analytics

- Implement responsive dashboard layout
- Add WebSocket connection for real-time data
- Include user preference settings
- Add comprehensive error handling

JIRA-789 #close"
```

### 3.2 提交信息规范

#### Conventional Commits 标准

```bash
# 格式: <type>(<scope>): <subject>
#
# <body>
#
# <footer>

# 示例 1: 功能添加
git commit -m "feat(auth): add OAuth2 integration with Google

- Implement Google OAuth2 authentication flow
- Add user profile synchronization
- Include token refresh mechanism
- Add comprehensive error handling

Closes #123"

# 示例 2: 问题修复
git commit -m "fix(payment): resolve Stripe webhook processing error

- Fix race condition in webhook handler
- Add proper error logging
- Implement retry mechanism for failed webhooks
- Add validation for webhook signatures

Fixes #456"

# 示例 3: 性能优化
git commit -m "perf(database): optimize user query performance

- Add database indexes for frequently queried fields
- Implement query result caching
- Reduce N+1 query problems
- Add query execution time monitoring

Performance improvement: 75% faster response times"
```

#### 提交类型说明

| 类型       | 描述       | 示例                                        |
|----------|----------|-------------------------------------------|
| feat     | 新功能      | `feat: add user registration`             |
| fix      | 错误修复     | `fix: resolve login timeout issue`        |
| docs     | 文档更新     | `docs: update API documentation`          |
| style    | 代码格式     | `style: fix indentation in main.css`      |
| refactor | 代码重构     | `refactor: simplify authentication logic` |
| perf     | 性能优化     | `perf: improve database query speed`      |
| test     | 测试相关     | `test: add unit tests for user service`   |
| build    | 构建系统     | `build: update webpack configuration`     |
| ci       | CI/CD 配置 | `ci: add GitHub Actions workflow`         |
| chore    | 杂项任务     | `chore: update dependencies`              |

---

## 4. 代码审查规范

### 4.1 合并请求 (Merge Request) 流程

#### 创建合并请求

```bash
# 1. 完成功能开发并推送最新代码
git add .
git commit -m "feat: complete user dashboard feature

- Implement all dashboard components
- Add comprehensive tests
- Update documentation

JIRA-789 #ready-for-review"
git push origin feature/JIRA-789-new-dashboard

# 2. 创建合并请求（通过 GitLab/GitHub Web 界面）
# - 标题: 简洁描述更改内容
# - 描述: 详细说明更改内容、测试情况、注意事项
# - 指派审查者: 选择相关技术负责人
# - 标签: 添加适当的标签（如：enhancement, bugfix）
```

#### 合并请求模板

```markdown
## 📝 更改描述

简要描述本次更改的内容和目的。

## 🔄 更改类型

- [ ] 新功能 (feature)
- [ ] 错误修复 (bugfix)
- [ ] 性能优化 (performance)
- [ ] 代码重构 (refactoring)
- [ ] 文档更新 (documentation)
- [ ] 测试相关 (test)

## 🧪 测试情况

- [ ] 单元测试已通过
- [ ] 集成测试已通过
- [ ] 手动测试已完成
- [ ] 回归测试已执行

## 📋 检查清单

- [ ] 代码遵循企业编码规范
- [ ] 已为关键代码添加注释
- [ ] 已更新相关文档
- [ ] 已考虑向后兼容性
- [ ] 已处理潜在的安全问题

## 🔗 相关链接

- JIRA 票据: [JIRA-789](https://jira.company.com/browse/JIRA-789)
- 相关 PR: #123, #124
- 设计文档: [链接]

## 📸 截图（如适用）

添加相关截图或 GIF 以展示更改效果。

## ⚠️ 注意事项

列出审查者需要特别注意的地方。
```

### 4.2 代码审查检查清单

#### 功能性检查

- [ ] 代码是否实现了预期功能
- [ ] 边界条件是否处理正确
- [ ] 错误处理是否完善
- [ ] 性能是否满足要求

#### 代码质量检查

- [ ] 代码是否易于理解和维护
- [ ] 是否遵循命名规范
- [ ] 是否有适当的注释
- [ ] 是否存在重复代码

#### 安全性检查

- [ ] 输入验证是否充分
- [ ] 敏感信息是否安全处理
- [ ] 是否存在潜在的安全漏洞
- [ ] 权限控制是否正确

#### 测试检查

- [ ] 单元测试是否覆盖关键逻辑
- [ ] 集成测试是否通过
- [ ] 测试用例是否充分
- [ ] 代码覆盖率是否达标

---

## 5. 版本发布管理

### 5.1 版本号管理

#### Semantic Versioning (语义化版本)

```
版本格式: MAJOR.MINOR.PATCH

MAJOR: 不兼容的 API 更改
MINOR: 向下兼容的功能性新增
PATCH: 向下兼容的问题修正

示例:
v1.0.0 - 初始稳定版本
v1.1.0 - 添加新功能
v1.1.1 - 修复 bug
v2.0.0 - 不兼容的 API 更改
```

#### 发布分支管理

```bash
# 1. 从 develop 分支创建发布分支
git checkout develop
git pull origin develop
git checkout -b release/v2.1.0

# 2. 更新版本号并提交
echo "2.1.0" > VERSION
git add VERSION
git commit -m "chore: bump version to 2.1.0"

# 3. 进行发布前的最终测试和修复
# ... 测试和修复 ...

# 4. 合并到 master 分支
git checkout master
git merge --no-ff release/v2.1.0
git tag -a v2.1.0 -m "Release version 2.1.0"

# 5. 合并回 develop 分支
git checkout develop
git merge master
git branch -d release/v2.1.0
```

### 5.2 标签管理

#### 创建标签

```bash
# 轻量标签
git tag v1.0.0

# 附注标签（推荐）
git tag -a v1.0.0 -m "Release version 1.0.0

- Add user authentication
- Implement payment processing
- Add admin dashboard
- Performance optimizations"

# 签署标签（高安全性要求）
git tag -s v1.0.0 -m "Signed release version 1.0.0"
```

#### 标签操作

```bash
# 查看标签
git tag -l "v1.*"
git show v1.0.0

# 推送标签到远程
git push origin v1.0.0
git push origin --tags

# 删除标签
git tag -d v1.0.0
git push origin :refs/tags/v1.0.0
```

---

## 6. 协作最佳实践

### 6.1 团队协作风范

#### 提交前自检

```bash
# 1. 检查代码格式和语法
npm run lint
npm run test

# 2. 确保构建成功
npm run build

# 3. 检查提交信息格式
git log --oneline -5  # 参考最近的提交格式

# 4. 运行代码质量检查
npm run quality-check
```

#### 保持历史整洁

```bash
# 使用交互式 rebase 整理提交历史
git rebase -i HEAD~3

# 压缩多个小的提交
git rebase -i HEAD~5
# 在编辑器中将 "pick" 改为 "squash" 或 "fixup"

# 推送到远程前整理分支
git push origin feature/JIRA-789-new-dashboard --force-with-lease
```

### 6.2 冲突解决策略

#### 预防冲突

```bash
# 1. 经常同步主分支
git checkout develop
git pull origin develop

# 2. 小而频繁的提交
# 避免长时间不提交的大量更改

# 3. 及时沟通
# 在开始大功能前告知团队
# 定期更新任务状态
```

#### 解决冲突

```bash
# 1. 同步最新代码
git checkout feature/JIRA-789-new-dashboard
git fetch origin
git merge origin/develop

# 2. 如果出现冲突，Git 会标记冲突文件
# 手动编辑冲突文件，解决冲突

# 3. 标记冲突已解决
# 对于每个冲突文件：
git add <resolved-file>

# 4. 完成合并
git commit -m "resolve: merge conflicts with develop branch

- Resolved conflicts in user.service.js
- Updated API endpoints to match new specification
- Fixed integration tests"

# 5. 继续开发或推送
git push origin feature/JIRA-789-new-dashboard
```

---

## 7. 故障排除指南

### 7.1 常见错误及解决方案

#### 提交相关错误

```bash
# 错误：提交信息格式错误
# 解决：使用正确的提交信息格式
git commit --amend -m "feat: add user authentication feature"

# 错误：提交了敏感信息
# 解决：使用 filter-branch 移除敏感信息
git filter-branch --force --index-filter \
'git rm --cached --ignore-unmatch path/to/sensitive/file' \
--prune-empty --tag-name-filter cat -- --all

# 错误：提交了过大的文件
# 解决：使用 Git LFS 或移除文件
git reset HEAD~1  # 撤销最后一次提交
git rm --cached large-file.zip
echo "*.zip" >> .gitignore
git commit -m "fix: remove large file and update .gitignore"
```

#### 分支相关错误

```bash
# 错误：误删分支
# 解决：恢复删除的分支
git reflog  # 查找分支的最后一次提交
git checkout -b recovered-branch <commit-hash>

# 错误：错误的分支合并
# 解决：回退合并
git reset --hard HEAD~1  # 回退到合并前状态
# 或者创建新的修复分支
git checkout -b hotfix/wrong-merge-fix
```

#### 远程仓库错误

```bash
# 错误：推送被拒绝
# 解决：先拉取最新更改
git pull origin develop --rebase
git push origin feature/JIRA-789-new-dashboard

# 错误：远程分支不存在
# 解决：创建并推送新分支
git push -u origin feature/JIRA-789-new-dashboard

# 错误：权限不足
# 解决：检查 SSH 密钥和用户权限
ssh -T git@gitlab.company.com  # 测试 SSH 连接
```

### 7.2 数据恢复

#### 恢复丢失的提交

```bash
# 1. 使用 reflog 查找丢失的提交
git reflog

# 2. 创建新分支恢复提交
git checkout -b recovery-branch <lost-commit-hash>

# 3. 或者重置当前分支到丢失的提交
git reset --hard <lost-commit-hash>
```

#### 恢复删除的文件

```bash
# 1. 查找文件的最后存在状态
git log --all --full-history -- "**/deleted-file.js"

# 2. 恢复文件到最后存在状态
git checkout <commit-hash>^ -- path/to/deleted-file.js

# 3. 提交恢复操作
git commit -m "restore: recover accidentally deleted file"
```

---

## 8. 安全与权限管理

### 8.1 分支保护规则

#### 设置分支保护（GitLab/GitHub）

```bash
# 主分支保护规则示例
# 在 GitLab/GitHub 设置中配置：

# 1. master/main 分支保护
# - 需要合并请求才能推送
# - 需要至少 2 个审查者批准
# - 需要通过 CI/CD 管道
# - 需要签署提交

# 2. develop 分支保护
# - 需要合并请求
# - 需要至少 1 个审查者批准
# - 需要通过自动化测试
```

### 8.2 提交签名

#### 配置 GPG 签名

```bash
# 1. 生成 GPG 密钥
gpg --full-generate-key

# 2. 配置 Git 使用 GPG 签名
git config --global user.signingkey <GPG-KEY-ID>
git config --global commit.gpgsign true

# 3. 签署提交
git commit -S -m "feat: add secure authentication"

# 4. 验证签名
git log --show-signature --oneline
```

### 8.3 敏感信息管理

#### 防止敏感信息泄露

```bash
# 1. 使用 .gitignore 排除敏感文件
echo "config/secrets.json" >> .gitignore
echo "*.env" >> .gitignore
echo "credentials/" >> .gitignore

# 2. 使用 Git 钩子进行预提交检查
# 在 .git/hooks/pre-commit 中添加：
#!/bin/sh
if git diff --cached --name-only | grep -E "(password|secret|key|token)"; then
    echo "Error: Potential sensitive information detected!"
    exit 1
fi

# 3. 使用 git-secrets 工具
# 安装 git-secrets 并配置规则
git secrets --install
git secrets --add 'password\s*=\s*.+'
git secrets --add 'api[_-]?key\s*=\s*.+'
```

---

## 📊 企业级 Git 统计与监控

### 代码贡献统计

```bash
# 查看项目统计
git shortlog -sn --all  # 按作者统计提交数
git log --pretty=format:"%h %an %ad %s" --date=short --since="1 month ago"  # 最近一个月提交
git log --author="张三" --oneline --since="1 week ago"  # 个人贡献统计
```

### 代码质量分析

```bash
# 分析代码变更
git diff --stat HEAD~10..HEAD  # 最近10次提交的统计
git log --pretty=format:"%h %s" --graph  # 分支图展示
git blame filename.js  # 代码行级贡献分析
```

---

## 🔗 相关资源

### 推荐工具

- **SourceTree**: 图形化 Git 客户端
- **GitKraken**: 跨平台 Git 客户端
- **GitHub Desktop**: GitHub 官方客户端
- **GitLens**: VS Code Git 插件
- **git-flow**: Git Flow 自动化工具

### 学习资源

- [Pro Git 中文版](https://git-scm.com/book/zh/v2)
- [GitHub Flow](https://guides.github.com/introduction/flow/)
- [GitLab Flow](https://docs.gitlab.com/ee/topics/gitlab_flow.html)
- [Conventional Commits](https://www.conventionalcommits.org/zh-hans/v1.0.0/)

### 企业级平台

- **GitLab Enterprise**: 企业级 Git 平台
- **GitHub Enterprise**: 企业版 GitHub
- **Azure DevOps**: 微软开发运维平台
- **Bitbucket Server**: Atlassian Git 解决方案

---

## 📋 快速参考卡片

### 常用命令速查

```bash
# 配置
git config --global user.name "姓名"
git config --global user.email "邮箱@company.com"

# 克隆与创建
git clone <repository-url>
git init
git remote add origin <url>

# 基本操作
git status
git add <file>
git commit -m "提交信息"
git push origin <branch>
git pull origin <branch>

# 分支管理
git branch -a
git checkout -b <new-branch>
git merge <branch>
git branch -d <branch>

# 历史查看
git log --oneline
git log --graph --all
git diff
git show <commit>

# 撤销操作
git checkout -- <file>
git reset HEAD <file>
git revert <commit>
```

### 提交信息模板

```
<type>(<scope>): <subject>

<body>

<footer>
```

### 分支命名模板

```
feature/JIRA-123-short-description
hotfix/fix-critical-bug
release/v1.2.0
```

---

**文档版本:** v1.0  
**最后更新:** 2025年12月14日  
**维护团队:** 企业开发规范团队  
**审核状态:** ✅ 已审核批准