# 个人知识库 (Kapok Docs)

> 个人开发中常用的技术栈信息、代码片段、系统环境配置相关的知识点汇总

基于 [VitePress](https://vitepress.dev/) 构建的静态文档网站，用于记录和分享个人在 IT 学习和开发过程中积累的知识和经验。

## 📚 项目概述

这是一个个人知识库项目，主要用于整理和归档在日常开发工作中遇到的各种技术点、配置方法和最佳实践。内容涵盖：

- Windows 系统开发环境配置
- Ubuntu 系统开发环境配置
- 常用技术栈和工具使用方法
- 项目开发经验和技巧总结

## 🚀 技术栈

- [VitePress](https://vitepress.dev/) - 基于 Vite 的静态站点生成器
- [Vue 3](https://vuejs.org/) - 渐进式 JavaScript 框架
- [TypeScript](https://www.typescriptlang.org/) - JavaScript 的超集，添加静态类型定义

## 🎯 主要特性

- **高性能**: 基于 VitePress 构建，享受极速的开发体验和构建速度
- **Markdown 优先**: 专注内容创作，使用 Markdown 语法轻松编写文档
- **主题定制**: 支持深度定制，打造符合个人喜好的文档风格
- **智能搜索**: 内置全文搜索功能，快速定位所需内容
- **响应式设计**: 完美适配各种设备，随时随地查阅文档
- **现代化**: 采用最新的前端技术栈，提供流畅的用户体验

## 📁 项目结构

```
.
├── docs/                    # 文档主目录
│   ├── .vitepress/         # VitePress 配置目录
│   │   └── config.mts      # 主配置文件
│   ├── public/             # 静态资源目录
│   └── src/                # 文档源文件目录
│       ├── windows-configuration/  # Windows 配置相关文档
│       ├── ubuntu-configuration/   # Ubuntu 配置相关文档
│       └── *.md            # 其他文档文件
├── .github/                 # GitHub 相关配置
└── package.json            # 项目配置文件
```

## 🛠️ 开发环境搭建

### 前置要求

- Node.js >= 18
- npm 或 yarn 包管理器

### 安装依赖

```bash
npm install
```

### 本地开发

```bash
# 启动开发服务器
npm run docs:dev

# 构建生产版本
npm run docs:build

# 预览构建结果
npm run docs:preview
```

## 📖 文档内容

文档主要包括以下几个部分：

1. **首页** - 项目介绍和快速入门指引
2. **Windows 配置** - Windows 系统开发环境配置指南
3. **Ubuntu 配置** - Ubuntu 系统开发环境配置指南
4. **主题切换** - 实时切换网站 Logo 和背景动画样式的功能演示
5. **许可证信息** - 项目许可证和相关说明

## 🎨 定制化功能

### 主题切换器

项目内置了一个主题切换器组件，可以实时切换 Logo 样式和背景动画效果：

- **Logo 样式**: 原版、几何、科技、自然、极简等多种风格
- **背景动画**: 文档、粒子、波浪、代码矩阵、抽象艺术等多种效果

所有设置会自动保存到本地存储中，下次访问时会恢复之前的设置。

## 🔧 配置说明

项目的主要配置位于 `docs/.vitepress/config.mts` 文件中，包括：

- 站点基本信息（标题、描述等）
- 导航栏和侧边栏配置
- 主题定制选项
- 搜索功能配置
- 社交链接和页脚信息

## 📄 许可证

本项目基于 Apache License 2.0 开源协议发布。

Apache License 2.0 是一个宽松的开源许可证，允许商业使用、修改、分发等，同时提供了专利保护和免责条款。

详细信息请参阅 [LICENSE](./LICENSE) 文件和文档中的 [许可证信息](./docs/src/license.md) 页面。

## 🤝 贡献

欢迎提交 Issue 和 Pull Request 来帮助改进这个知识库。

在提交 Pull Request 时，请参考项目提供的 [PR 模板](./.github/PULL_REQUEST_TEMPLATE.md)，确保包含足够的信息来描述你的变更。

## 🔗 相关资源

- [VitePress 官方文档](https://vitepress.dev/)
- [Vue 3 官方文档](https://vuejs.org/)
- [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0)