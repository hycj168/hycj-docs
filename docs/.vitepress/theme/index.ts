/*
 * Copyright 2025 hycj Docs Contributors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import type {Theme} from 'vitepress'
import DefaultTheme from 'vitepress/theme'
import Layout from './layout/Layout.vue'
import ThemeSwitcher from './components/ThemeSwitcher.vue'
import HeroImage from './components/HeroImage.vue'
import './custom.css'

const theme: Theme = {
    extends: DefaultTheme,
    Layout,
    enhanceApp({app}) {
        app.component('ThemeSwitcher', ThemeSwitcher)
        app.component('HeroImage', HeroImage)
    }
}

export default theme