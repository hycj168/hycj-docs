import {ref, watch} from 'vue'
import {withBase} from 'vitepress'
import {ASSETS} from '../config/paths'

// 全局状态
export const currentLogo = ref(ASSETS.LOGO_DEFAULT)
export const currentBackground = ref(ASSETS.BG_HERO)

// 初始化主题设置
export const initTheme = () => {
    // 检查是否在浏览器环境
    if (typeof window === 'undefined' || typeof localStorage === 'undefined') {
        // console.log('Not in browser environment, skipping localStorage')
        return
    }

    try {
        // 从localStorage恢复设置
        const savedLogo = localStorage.getItem('kapok-logo')
        const savedBackground = localStorage.getItem('kapok-background')

        if (savedLogo) {
            currentLogo.value = savedLogo
            // console.log('Restored logo from localStorage:', savedLogo)
        }

        if (savedBackground) {
            currentBackground.value = savedBackground
            // console.log('Restored background from localStorage:', savedBackground)
        }

        // console.log('Theme initialized successfully:', {
        //     logo: currentLogo.value,
        //     background: currentBackground.value
        // })
    } catch (error) {
        console.error('Error initializing theme:', error)
    }
}

// Logo切换函数
export const switchLogo = (logoPath: string) => {
    currentLogo.value = logoPath

    // 更新导航栏Logo - 使用withBase处理路径
    if (typeof document !== 'undefined') {
        const logoElement = document.querySelector('.VPNavBarTitle .logo') as HTMLImageElement
        if (logoElement) {
            logoElement.src = withBase(logoPath)
        }
    }

    // 保存到localStorage
    if (typeof localStorage !== 'undefined') {
        try {
            localStorage.setItem('kapok-logo', logoPath)
        } catch (error) {
            console.error('Error saving logo to localStorage:', error)
        }
    }
}

// 背景切换函数
export const switchBackground = (bgPath: string) => {
    currentBackground.value = bgPath

    // 保存到localStorage
    if (typeof localStorage !== 'undefined') {
        try {
            localStorage.setItem('kapok-background', bgPath)
        } catch (error) {
            console.error('Error saving background to localStorage:', error)
        }
    }

    // console.log(`Background switched to: ${bgPath}`)
}

// 监听背景变化
watch(currentBackground, (newBg) => {
    // 检查是否在浏览器环境
    if (typeof document === 'undefined') {
        return
    }

    // 使用withBase处理路径后更新CSS变量
    const bgUrl = withBase(newBg)
    document.documentElement.style.setProperty('--hero-bg-image', `url('${bgUrl}')`)

    // 尝试直接更新DOM元素 - 使用withBase处理路径
    const updateHeroImage = () => {
        const selectors = [
            '.VPHero .image img',
            '.VPHero .VPImage img',
            '.VPHero img',
            '.vp-hero .image img',
            '.custom-hero-image img',
            '.hero-bg-image',
            'img[alt="Kapok Docs Animation"]'
        ]

        let heroImage: HTMLImageElement | null = null

        for (const selector of selectors) {
            const elements = document.querySelectorAll(selector) as NodeListOf<HTMLImageElement>
            elements.forEach(img => {
                img.src = bgUrl
                // console.log(`Updated hero image via selector: ${selector}`)
            })
            if (elements.length > 0) {
                heroImage = elements[0]
            }
        }

        // 如果还是找不到，尝试通过父元素查找
        if (!heroImage) {
            const heroContainer = document.querySelector('.VPHero')
            if (heroContainer) {
                const allImages = heroContainer.querySelectorAll('img') as NodeListOf<HTMLImageElement>
                allImages.forEach(img => {
                    img.src = bgUrl
                    // console.log(`Updated hero image via container search`)
                })
            }
        }
    }

    // 立即执行一次
    updateHeroImage()

    // 延迟执行，确保DOM更新完成
    setTimeout(updateHeroImage, 100)
    setTimeout(updateHeroImage, 500)
})

export const useTheme = () => {
    return {
        currentLogo,
        currentBackground,
        switchLogo,
        switchBackground,
        initTheme
    }
}