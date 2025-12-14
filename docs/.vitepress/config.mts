import {defineConfig} from 'vitepress'

// 路径配置 - 根据实际GitHub仓库名配置
const BASE_PATH = '/hycj-docs'

// https://vitepress.dev/reference/site-config
export default defineConfig({
    // 网站名称
    title: "个人知识库",
    // 网站描述
    description: "个人开发中一些常用的代码或者技术栈、知识点汇总",
    // 源代码目录
    srcDir: "src",
    // 语言
    lang: "zh-CN",
    // GitHub Pages 部署配置
    base: BASE_PATH,
    // Vite 配置
    vite: {
        publicDir: '../public'
    },

    // 自定义页面头部
    head: [
        // 现代浏览器 SVG favicon - VitePress会自动处理base路径
        ['link', {rel: 'icon', href: '/favicon.svg', type: 'image/svg+xml'}],
        // 传统浏览器 fallback
        ['link', {rel: 'icon', href: '/favicon.ico', type: 'image/x-icon'}],
        // 强制刷新favicon缓存
        ['link', {rel: 'shortcut icon', href: '/favicon.ico', type: 'image/x-icon'}],
        // Apple Touch Icon
        ['link', {rel: 'apple-touch-icon', href: '/favicon-32x32.svg', sizes: '180x180'}],
        // 不同尺寸的图标
        ['link', {rel: 'icon', href: '/favicon-16x16.svg', sizes: '16x16', type: 'image/svg+xml'}],
        ['link', {rel: 'icon', href: '/favicon-32x32.svg', sizes: '32x32', type: 'image/svg+xml'}],
        ['meta', {name: 'viewport', content: 'width=device-width,initial-scale=1'}],
        ['meta', {name: 'keywords', content: 'VitePress, 文档, Kapok, 开发文档'}],
        ['meta', {name: 'theme-color', content: '#ff6b35'}]
    ],
    // 是否开启最后更新时间
    lastUpdated: true,
    // 主题配置
    themeConfig: {
        // https://vitepress.dev/reference/default-theme-config

        // 网站logo
        logo: "/logo.svg",

        lastUpdated: {
            text: '最后更新时间',
        },

        docFooter: {
            prev: '上一页',
            next: '下一页'
        },

        outline: {
            level: "deep",
            label: '页面导航',
            position: 'right'
        },

        // 导航栏
        nav: [
            {text: '首页', link: '/'},
            {text: 'Windows', link: '/windows-configuration/index'},
            {text: 'Ubuntu', link: '/ubuntu-configuration/index'},
            {text: 'Docker', link: '/docker-tutorial/index'},
            {text: '主题切换', link: '/theme-switcher'},
        ],

        // 侧边栏
        sidebar: [

            {
                text: 'Windows开发环境配置',
                items: [
                    {text: 'Windows 配置', link: '/windows-configuration/index'}
                ]
            },
            {
                text: 'Ubuntu开发环境配置',
                items: [
                    {text: 'Ubuntu 配置', link: '/ubuntu-configuration/index'},
                    {
                        text: 'Ubuntu 企业级文件系统详解',
                        link: '/ubuntu-configuration/ubuntu-enterprise-file-system-base'
                    },
                    {text: 'SSH 密钥认证配置', link: '/ubuntu-configuration/ssh-config'}
                ]
            },
            {
                text: 'Docker教程',
                items: [
                    {text: 'Ubuntu 使用 Docker 教程', link: '/docker-tutorial/docker-ubuntu-install'},
                    {text: 'Ubuntu 24.04 Docker 企业级安装教程', link: '/docker-tutorial/ubuntu-24.04-docker-install'},
                    {text: 'Docker 常用命令', link: '/docker-tutorial/docker-command-base'},
                    {text: 'Docker Compose 环境变量优先级', link: '/docker-tutorial/docker-compose-env-base'},
                    {text: 'Docker Compose 模板', link: '/docker-tutorial/docker-compose-template'},
                    {text: 'Docker 企业级数据库卷挂载目录创建脚本', link: '/docker-tutorial/docker-volumes-setup'},
                    {text: 'Docker 镜像构建基础', link: '/docker-tutorial/docker-build-base'}

                ]
            },
            {
                text: 'Docker 常用镜像',
                items: [
                    {text: 'Docker 常用镜像列表', link: '/docker-tutorial/common/docker-images-list'},
                    {text: 'RustFS 常用镜像', link: '/docker-tutorial/common/rustfs-docker-usage'},
                    {text: 'MySQL 企业级安装', link: '/docker-tutorial/common/docker-mysql-enterprise-install'},
                    {text: 'MySQL 企业级命令', link: '/docker-tutorial/common/docker-mysql-all-command'}
                ]
            },
            {
                text: '项目信息',
                items: [
                    {text: '项目许可协议', link: '/license'}
                ]
            },
        ],

        // 编辑链接配置
        editLink: {
            pattern: 'https://github.com/hycj/hycj-docs/edit/main/docs/src/:path',
            text: '在 GitHub 上编辑此页'
        },

        // 大纲标题
        outlineTitle: '页面导航',

        // 返回顶部
        returnToTopLabel: '回到顶部',

        // 外部链接图标
        externalLinkIcon: true,

        // 侧边栏菜单标签
        sidebarMenuLabel: '菜单',

        // 深色模式切换标签
        darkModeSwitchLabel: '主题',
        lightModeSwitchTitle: '切换到浅色模式',
        darkModeSwitchTitle: '切换到深色模式',

        // 搜索功能中文配置
        search: {
            provider: 'local',
            options: {
                locales: {
                    root: {
                        translations: {
                            button: {
                                buttonText: '搜索文档',
                                buttonAriaLabel: '搜索文档'
                            },
                            modal: {
                                noResultsText: '无法找到相关结果',
                                resetButtonTitle: '清除查询条件',
                                footer: {
                                    selectText: '选择',
                                    navigateText: '切换',
                                    closeText: '关闭'
                                }
                            }
                        }
                    }
                }
            }
        },

        // 页脚
        socialLinks: [
            {
                icon: 'github',
                link: 'https://github.com/vuejs/vitepress'
            }
        ],

        footer: {
            message: 'Released under the MIT License.',
            copyright: 'Copyright © 2022-present hycj'
        }
    }
})
