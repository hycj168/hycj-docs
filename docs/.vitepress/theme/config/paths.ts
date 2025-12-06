// 路径配置文件 - VitePress会自动处理base路径
// 这里只需要相对于public目录的路径

// 生成资源路径的辅助函数
export const getAssetPath = (path: string): string => {
    // 确保路径以 / 开头，VitePress会自动添加base路径
    return path.startsWith('/') ? path : `/${path}`
}

// 预定义的资源路径 - 相对于public目录
export const ASSETS = {
    // Logo 路径
    LOGO_DEFAULT: '/logo.svg',
    LOGO_GEOMETRIC: '/logos/logo-geometric.svg',
    LOGO_TECH: '/logos/logo-tech.svg',
    LOGO_NATURE: '/logos/logo-nature.svg',
    LOGO_MINIMAL: '/logos/logo-minimal.svg',
    LOGO_GRADIENT: '/logos/logo-gradient.svg',
    LOGO_NEON: '/logos/logo-neon.svg',
    LOGO_GLASS: '/logos/logo-glass.svg',

    // 背景图片路径
    BG_HERO: '/hero-animation.svg',
    BG_PARTICLES: '/backgrounds/bg-particles.svg',
    BG_WAVES: '/backgrounds/bg-waves.svg',
    BG_CODE_MATRIX: '/backgrounds/bg-code-matrix.svg',
    BG_ABSTRACT: '/backgrounds/bg-abstract.svg',
    BG_OCEAN: '/backgrounds/bg-gradient-ocean.svg',
    BG_SUNSET: '/backgrounds/bg-gradient-sunset.svg',
    BG_SPACE: '/backgrounds/bg-gradient-space.svg',
    BG_AURORA: '/backgrounds/bg-gradient-aurora.svg',
    BG_GLOW_ORBS: '/backgrounds/bg-glow-orbs.svg',
    BG_GEOMETRIC: '/backgrounds/bg-geometric.svg',
    BG_FLOWING_LINES: '/backgrounds/bg-flowing-lines.svg',
    BG_CODE_FLOW: '/backgrounds/bg-code-flow.svg',

    // 其他资源
    FAVICON: '/favicon.ico'
}

// Logo 配置数组
export const LOGO_OPTIONS = [
    {name: '原版', path: ASSETS.LOGO_DEFAULT},
    {name: '几何', path: ASSETS.LOGO_GEOMETRIC},
    {name: '科技', path: ASSETS.LOGO_TECH},
    {name: '自然', path: ASSETS.LOGO_NATURE},
    {name: '极简', path: ASSETS.LOGO_MINIMAL},
    {name: '渐变', path: ASSETS.LOGO_GRADIENT},
    {name: '霓虹', path: ASSETS.LOGO_NEON},
    {name: '玻璃', path: ASSETS.LOGO_GLASS}
]

// 背景配置数组
export const BACKGROUND_OPTIONS = [
    {name: '文档', path: ASSETS.BG_HERO},
    {name: '粒子', path: ASSETS.BG_PARTICLES},
    {name: '波浪', path: ASSETS.BG_WAVES},
    {name: '代码', path: ASSETS.BG_CODE_MATRIX},
    {name: '抽象', path: ASSETS.BG_ABSTRACT},
    {name: '海洋', path: ASSETS.BG_OCEAN},
    {name: '日落', path: ASSETS.BG_SUNSET},
    {name: '太空', path: ASSETS.BG_SPACE},
    {name: '极光', path: ASSETS.BG_AURORA},
    {name: '光晕', path: ASSETS.BG_GLOW_ORBS},
    {name: '几何', path: ASSETS.BG_GEOMETRIC},
    {name: '流线', path: ASSETS.BG_FLOWING_LINES},
    {name: '代码流', path: ASSETS.BG_CODE_FLOW}
]