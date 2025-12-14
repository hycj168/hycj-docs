# 企业级 Markdown 写作规范

## 前言

本规范基于 VitePress 的 Markdown 扩展功能制定，旨在统一企业技术文档的写作标准，提升文档质量和可维护性。所有技术文档、API
文档、用户手册等均应遵循此规范。

## 目录

1. [基础语法规范](#基础语法规范)
2. [VitePress 扩展语法](#vitepress-扩展语法)
3. [专业字符和符号规范](#专业字符和符号规范)
4. [文档结构规范](#文档结构规范)
5. [排版和格式规范](#排版和格式规范)
6. [最佳实践](#最佳实践)
7. [示例集合](#示例集合)

## 基础语法规范

### 标题规范

#### 标题层级

- 使用 `#` 符号表示标题层级，最多支持 6 级
- 文档主标题使用一级标题 `#`，章节标题使用二级标题 `##`
- 保持标题层级连贯，避免跳级使用

```markdown
# 文档标题

## 一级章节

### 二级章节

#### 三级章节
```

#### 标题锚点

- VitePress 会自动为标题生成锚点
- 自定义锚点语法：`## 标题名称 {#custom-anchor}`
- 锚点命名使用小写字母、数字和连字符，避免使用中文

```markdown
## 用户认证机制 {#user-authentication}

## API 接口规范 {#api-specification}
```

### 段落和换行

#### 段落规范

- 段落之间使用一个空行分隔
- 每行文本长度不超过 80 个字符，便于版本控制
- 段落开头不要添加空格或制表符

#### 强制换行

- 在行尾添加两个空格实现强制换行
- 适用于地址、诗歌等需要精确换行的场景

### 文本格式化

#### 强调文本

```markdown
*斜体文本* 或 _斜体文本_
**粗体文本** 或 __粗体文本__
***粗斜体文本*** 或 ___粗斜体文本___
```

#### 删除线和下划线

```markdown
~~删除线文本~~
<u>下划线文本</u>
```

### 列表规范

#### 无序列表

- 使用 `-`、`*` 或 `+` 作为列表标记
- 同一文档中保持使用同一种标记符号
- 子列表缩进 2 个空格

```markdown
- 列表项 1
- 列表项 2
    - 子项 2.1
    - 子项 2.2
- 列表项 3
```

#### 有序列表

- 使用数字加英文句点 `1.` 作为标记
- 数字序列可以不必连续，Markdown 会自动编号
- 子列表缩进 2 个空格

```markdown
1. 第一步操作
2. 第二步操作
    1. 子步骤 2.1
    2. 子步骤 2.2
3. 第三步操作
```

#### 任务列表

```markdown
- [x] 已完成的任务
- [ ] 未完成的任务
- [ ] 另一个未完成任务
```

### 链接规范

#### 内部链接

- 使用相对路径链接到文档内部页面
- 链接文本要清晰描述目标内容
- 避免使用"点击这里"等无意义的链接文本

```markdown
[用户认证文档](./authentication.md)
[API 参考](../api/reference.md)
```

#### 外部链接

- 外部链接会自动添加 `target="_blank" rel="noreferrer"`
- 链接文本应包含目标网站或页面的关键信息

```markdown
[VitePress 官方文档](https://vitepress.dev)
[MDN Web 文档](https://developer.mozilla.org)
```

#### 锚点链接

```markdown
[跳转到用户认证章节](#user-authentication)
[查看 API 规范](#api-specification)
```

### 图片规范

#### 基本语法

```markdown
![替代文本](图片地址)
![替代文本](图片地址 "图片标题")
```

#### 图片属性

```markdown
![替代文本](图片地址){width="300" height="200"}
![替代文本](图片地址){loading="lazy"}
```

### 代码规范

#### 行内代码

- 使用反引号 `` ` `` 包围行内代码
- 适用于变量名、函数名、命令等

```markdown
使用 `console.log()` 函数输出调试信息
变量 `userName` 存储用户名称
```

#### 代码块

- 使用三个反引号 ``` 或四个空格缩进
- 指定语言类型以获得语法高亮
- 代码块前后各空一行

```markdown
```javascript
function greet(name) {
  return `Hello, ${name}!`;
}
```

```

## VitePress 扩展语法

### Frontmatter 配置

#### 基本配置
```markdown
---
title: 文档标题
description: 文档描述
lang: zh-CN
---
```

#### 完整配置示例

```markdown
---
title: API 文档规范
description: 企业级 API 文档写作标准
lang: zh-CN
sidebar: true
editLink: true
lastUpdated: true
---
```

### 自定义容器

#### 标准容器类型

```markdown
::: info
这是一个信息提示框。
:::

::: tip
这是一个建议提示框。
:::

::: warning
这是一个警告提示框。
:::

::: danger
这是一个危险警告框。
:::

::: details
这是一个可折叠的详情块。
:::
```

#### 自定义标题容器

```markdown
::: danger STOP
危险区域，请勿继续操作！
:::

::: details 点击查看代码示例

```javascript
console.log('Hello, VitePress!');
```

:::

```

### GitHub 风格警报

#### 支持的警报类型
```markdown
> [!NOTE]
> 重要信息，用户不应忽略。

> [!TIP]
> 有助于用户更顺利完成任务的建议。

> [!IMPORTANT]
> 对用户达成目标至关重要的信息。

> [!WARNING]
> 因为可能存在风险，需要用户立即关注的内容。

> [!CAUTION]
> 行为可能带来的负面影响。
```

### 表格扩展

#### 基础表格

```markdown
| 名称 | 类型 | 描述 |
|------|------|------|
| id | number | 用户ID |
| name | string | 用户名 |
| email | string | 邮箱地址 |
```

#### 对齐方式

```markdown
| 左对齐 | 居中对齐 | 右对齐 |
|:-------|:--------:|-------:|
| 内容1 | 内容2 | 内容3 |
```

### 目录生成

#### 自动目录

```markdown
[[toc]]
```

#### 目录配置

```markdown
<!-- 在 frontmatter 中配置 -->
---
markdown: {
toc: {
includeLevel: [2, 3, 4]
}
}
---
```

### 代码块增强

#### 行高亮

```markdown
```javascript {1,3-5}
function highlight() {
  console.log('这一行会被高亮');
  console.log('这一行也会被高亮');
  console.log('这一行同样会被高亮');
  console.log('这一行还是会被高亮');
}
```

```

#### 焦点代码
```markdown
```javascript // [!code focus]
function focused() {
  console.log('这一行会被聚焦显示');
}
```

```

#### 错误和警告
```markdown
```javascript // [!code error]
console.log('这一行显示为错误');

// [!code warning]
console.log('这一行显示为警告');
```

```

### 导入代码片段

#### 从文件导入
```markdown
<<< @/snippets/example.js

<<< @/snippets/example.js#highlight{1,3}
```

#### 指定语言

```markdown
<<< @/snippets/config.json{json}
```

### 代码组

#### 多语言示例

```markdown
::: code-group

```bash [npm]
npm install vitepress
```

```bash [yarn]
yarn add vitepress
```

```bash [pnpm]
pnpm add vitepress
```

:::

```

### 数学公式

#### 行内公式
```markdown
质能方程：$E = mc^2$
```

#### 块级公式

```markdown
$$
\sum_{i=1}^{n} x_i = x_1 + x_2 + \cdots + x_n
$$
```

### 图片懒加载

#### 基础用法

```markdown
![描述文本](图片地址){loading="lazy"}
```

#### 结合属性

```markdown
![描述文本](图片地址){loading="lazy" width="300" height="200"}
```

## 专业字符和符号规范

### 标点符号使用

#### 中文标点

- 中文文档使用中文标点符号
- 引号使用中文引号："" ''
- 括号使用中文括号：（）【】
- 省略号使用中文省略号：……

#### 英文标点

- 英文文档或与英文混排时使用英文标点
- 技术术语、代码、变量名等使用英文标点
- 数学公式中的标点使用英文标点

### 特殊符号

#### 数学符号

```markdown
≠ ≠ 不等于
≤ ≤ 小于等于
≥ ≥ 大于等于
± ± 正负号
× × 乘号
÷ ÷ 除号
∑ ∑ 求和符号
∏ ∏ 求积符号
∫ ∫ 积分符号
∞ ∞ 无穷大
```

#### 单位符号

```markdown
°C 摄氏度
°F 华氏度
% 百分比
‰ 千分比
㎎ 毫克
㎏ 千克
㎞ 千米
㎝ 厘米
㎜ 毫米
```

#### 货币符号

```markdown
¥ 人民币
$ 美元
€ 欧元
£ 英镑
₩ 韩元
₹ 印度卢比
```

#### 版权和商标

```markdown
© 版权所有
® 注册商标
™ 商标
℠ 服务商标
```

### 技术专用符号

#### 编程符号

```markdown
&amp; & 和号
&lt; < 小于号
&gt; > 大于号
&quot; " 双引号
&apos; ' 单引号
```

#### 正则表达式符号

```markdown
. 任意字符

* 零次或多次

+ 一次或多次
  ? 零次或一次
  ^ 开始位置
  $ 结束位置
  | 或者
  [] 字符集
  () 分组
```

#### 路径和URL符号

```markdown
/ 路径分隔符
\ 反斜杠
~ 主目录
. 当前目录
.. 上级目录

# 锚点

? 查询参数
& 参数分隔符
```

### 引号使用规范

#### 中文引号

```markdown
"双引号用于引用话语"
'单引号用于引用中的引用'
```

#### 英文引号

```markdown
"Double quotes for emphasis"
'Single quotes for nested quotes'
```

#### 技术文档中的引号

```markdown
变量名使用 `code` 格式： `userName`
文件路径使用代码格式： `/path/to/file`
URL 使用链接格式： `https://example.com`
```

### 数字和数值格式

#### 整数和小数

```markdown
1,000 千位分隔符（英文）
1000 千位分隔符（中文）
3.14 小数点（英文）
3.14 小数点（中文）
```

#### 科学计数法

```markdown
1.23 × 10^6 中文格式
1.23e6 编程格式
1.23E6 科学格式
```

#### 百分比和比率

```markdown
50% 百分比
3:2 比率
1/3 分数
0.333... 小数
```

## 文档结构规范

### 文档层次结构

#### 标准文档结构

```markdown
# 文档标题

## 概述

简要介绍文档内容和目的

## 主要内容

### 子章节 1

具体内容

### 子章节 2

具体内容

## 总结

文档总结和后续建议

## 参考资料

相关文档和链接
```

#### 技术文档结构

```markdown
# 技术方案标题

## 项目背景

项目背景和问题描述

## 技术方案

### 方案概述

整体技术架构

### 详细设计

具体实现细节

### 技术选型

技术栈选择和原因

## 实施计划

实施步骤和时间安排

## 风险评估

潜在风险和应对措施

## 总结

方案总结和建议
```

### 章节命名规范

#### 标题命名原则

- 简洁明了，准确描述内容
- 避免使用模糊词汇
- 保持命名一致性
- 使用动词或动名词结构

#### 推荐的章节名称

```markdown
## 快速开始

## 安装配置

## 基础概念

## 核心功能

## 高级用法

## API 参考

## 最佳实践

## 常见问题

## 更新日志
```

### 内容组织原则

#### 信息架构

- 从整体到局部
- 从简单到复杂
- 从常用到罕见
- 保持逻辑连贯性

#### 内容块划分

```markdown
## 主要功能

### 功能 A

功能 A 的详细介绍

#### 基本用法

最常用的使用方式

#### 高级配置

复杂的配置选项

#### 注意事项

使用时需要特别注意的点

### 功能 B

功能 B 的详细介绍
...
```

## 排版和格式规范

### 文本排版

#### 行长和换行

- 每行文本长度不超过 80 个字符
- 段落之间使用一个空行
- 列表项之间根据内容密度决定是否空行

#### 空格使用

```markdown
# 中文和英文之间加空格

使用 JavaScript 编写代码

# 数字和单位之间加空格

容量为 16 GB

# 中文和数字之间加空格

第 1 步操作

# 例外情况

100% 正确（百分号前不加空格）
温度 20°C（单位符号前不加空格）
```

### 代码格式规范

#### 代码块格式

- 代码块前后各空一行
- 指定正确的编程语言
- 代码块内部保持一致的缩进

```markdown
# 好的示例

```javascript
function example() {
  console.log('Hello World');
}
```

# 不好的示例

```javascript
function example() {
    console.log('Hello World');
}
```

```

#### 行内代码
- 变量名、函数名、文件名使用行内代码
- 代码术语与普通文本之间加空格

```markdown
使用 `console.log()` 函数输出调试信息
`userName` 变量存储用户名称
```

### 表格格式规范

#### 表格对齐

```markdown
| 左对齐列 | 居中对齐列 | 右对齐列 |
|:---------|:----------:|---------:|
| 内容1    |   内容2    |     内容3 |
```

#### 表格内容

- 表头使用清晰的中文描述
- 内容简洁明了
- 保持表格宽度适中

### 图片和图表

#### 图片格式

- 使用清晰的替代文本
- 必要时添加图片说明
- 控制图片尺寸，避免过大

```markdown
![系统架构图](./images/architecture.png)

*图 1：系统整体架构*
```

#### 图表规范

- 使用专业的图表工具制作
- 保持风格一致性
- 添加必要的图例和说明

### 链接规范

#### 内部链接

```markdown
[用户认证](./authentication.md)
[API 文档](../api/index.md)
```

#### 外部链接

```markdown
[VitePress 官方文档](https://vitepress.dev)
[MDN Web 文档](https://developer.mozilla.org)
```

#### 链接文本

- 链接文本要清晰描述目标内容
- 避免使用"点击这里"等无意义文本
- 保持链接文本简洁

## 最佳实践

### 写作原则

#### 清晰性原则

- 使用简单直接的语言
- 避免使用模糊词汇
- 提供具体的示例

#### 一致性原则

- 保持术语使用一致
- 保持格式风格一致
- 保持命名规范一致

#### 完整性原则

- 提供完整的信息
- 包含必要的背景知识
- 给出相关的参考资料

### 内容质量

#### 准确性

- 确保技术信息的准确性
- 及时更新过时内容
- 验证示例代码的正确性

#### 可读性

- 使用合适的标题层级
- 合理使用列表和表格
- 添加必要的视觉元素

#### 实用性

- 提供实际的使用场景
- 包含常见问题的解决方案
- 给出最佳实践建议

### 协作规范

#### 版本控制

- 使用有意义的提交信息
- 定期更新和维护文档
- 记录重要的修改历史

#### 审查流程

- 建立文档审查机制
- 确保内容的准确性
- 保持风格的一致性

#### 反馈机制

- 提供反馈渠道
- 及时响应用户问题
- 持续改进文档质量

## 示例集合

### 完整文档示例

#### API 文档示例

```markdown
---
title: 用户管理 API
description: 用户管理相关接口文档
lang: zh-CN
---

# 用户管理 API

## 概述

本文档描述了用户管理模块的所有 API 接口，包括用户注册、登录、信息修改等功能。

## 基础信息

- **Base URL**: `https://api.example.com/v1`
- **认证方式**: Bearer Token
- **内容类型**: `application/json`

## 接口列表

### 用户注册

#### 基本信息

- **接口地址**: `/users/register`
- **请求方法**: `POST`
- **接口描述**: 新用户注册接口

#### 请求参数

| 参数名 | 类型 | 必填 | 描述 |
|--------|------|------|------|
| username | string | 是 | 用户名，3-20个字符 |
| email | string | 是 | 邮箱地址 |
| password | string | 是 | 密码，至少8个字符 |

#### 请求示例

```json
{
  "username": "john_doe",
  "email": "john@example.com",
  "password": "securepassword123"
}
```

#### 响应示例

::: code-group

```json [成功响应]
{
  "code": 200,
  "message": "注册成功",
  "data": {
    "userId": 12345,
    "username": "john_doe",
    "email": "john@example.com"
  }
}
```

```json [错误响应]
{
  "code": 400,
  "message": "用户名已存在",
  "error": "USERNAME_EXISTS"
}
```

:::

#### 错误码说明

| 错误码               | 描述     |
|-------------------|--------|
| USERNAME_EXISTS   | 用户名已存在 |
| EMAIL_EXISTS      | 邮箱已被注册 |
| INVALID_PARAMETER | 参数格式错误 |

> [!WARNING]
> 密码必须包含大小写字母、数字和特殊字符，长度至少8位。

::: tip 最佳实践
建议使用 HTTPS 协议进行注册，确保数据传输安全。
:::

### 用户登录

#### 基本信息

- **接口地址**: `/users/login`
- **请求方法**: `POST`
- **接口描述**: 用户登录接口

#### 请求参数

| 参数名      | 类型     | 必填 | 描述     |
|----------|--------|----|--------|
| username | string | 是  | 用户名或邮箱 |
| password | string | 是  | 密码     |

#### 响应示例

```json
{
  "code": 200,
  "message": "登录成功",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "userId": 12345,
      "username": "john_doe",
      "email": "john@example.com"
    }
  }
}
```

## 总结

本文档涵盖了用户管理的核心 API 接口。如需更多功能，请参考[扩展 API 文档](./extended-api.md)。

## 更新日志

- **2024-01-15**: 添加用户注册接口
- **2024-01-20**: 添加用户登录接口
- **2024-02-01**: 更新错误码说明

```

#### 技术方案示例
```markdown
---
title: 微服务架构设计方案
description: 系统微服务化改造技术方案
lang: zh-CN
---

# 微服务架构设计方案

## 项目背景

随着业务规模的扩大，单体应用架构已经无法满足系统的高并发、高可用需求。本次改造旨在将现有单体应用拆分为微服务架构，提升系统的可扩展性和维护性。

## 技术方案

### 架构概述 {#architecture-overview}

采用 Spring Cloud 微服务框架，整体架构如下：

![微服务架构图](./images/microservices-arch.png)

*图 1：微服务整体架构*

### 服务拆分策略

#### 业务边界划分
按照业务领域进行服务拆分：

1. **用户服务** (`user-service`)
   - 用户注册、登录
   - 用户信息管理
   - 权限管理

2. **订单服务** (`order-service`)
   - 订单创建、查询
   - 订单状态管理
   - 订单统计分析

3. **商品服务** (`product-service`)
   - 商品信息管理
   - 商品分类
   - 库存管理

#### 数据一致性

> [!IMPORTANT]
> 采用最终一致性模型，通过事件驱动保证数据同步。

使用分布式事务解决方案：

| 方案 | 优点 | 缺点 | 适用场景 |
|------|------|------|----------|
| 2PC | 强一致性 | 性能较差 | 金融交易 |
| TCC | 性能较好 | 实现复杂 | 电商订单 |
| 消息队列 | 解耦性好 | 一致性弱 | 日志记录 |

### 技术选型

#### 核心框架
```yaml
spring-cloud: 2023.0.0
spring-boot: 3.2.0
java: 17
```

#### 基础设施

- **注册中心**: Nacos 2.3.0
- **配置中心**: Nacos Config
- **网关**: Spring Cloud Gateway
- **熔断**: Sentinel 1.8.6

::: code-group

```yaml [Nacos 配置]
server:
  port: 8848
spring:
  application:
    name: nacos-server
  cloud:
    nacos:
      discovery:
        server-addr: localhost:8848
```

```yaml [Gateway 配置]
server:
  port: 8080
spring:
  cloud:
    gateway:
      routes:
        - id: user-service
          uri: lb://user-service
          predicates:
            - Path=/api/user/**
```

:::

## 实施计划

### 第一阶段（1-2个月）

- [x] 基础设施搭建
- [x] 服务注册中心部署
- [x] 配置中心搭建
- [ ] 网关服务开发

### 第二阶段（2-3个月）

- [ ] 用户服务拆分
- [ ] 订单服务拆分
- [ ] 商品服务拆分
- [ ] 服务间通信测试

### 第三阶段（1个月）

- [ ] 性能测试
- [ ] 安全测试
- [ ] 生产环境部署
- [ ] 监控告警配置

> [!CAUTION]
> 服务拆分过程需要充分考虑数据依赖关系，避免循环依赖。

## 风险评估

### 技术风险

| 风险点      | 影响程度 | 应对措施          |
|----------|------|---------------|
| 分布式事务复杂性 | 高    | 采用成熟框架，充分测试   |
| 服务调用链路过长 | 中    | 优化服务设计，减少调用层级 |
| 数据一致性问题  | 高    | 建立完善的补偿机制     |

### 业务风险

::: warning 业务连续性风险
服务拆分期间可能影响业务正常运行，需要制定详细的迁移计划。
:::

## 总结

本方案采用主流的 Spring Cloud 技术栈，能够有效解决当前系统面临的问题。建议分阶段实施，确保系统稳定性。

::: tip 后续规划
建议后续考虑容器化部署，进一步提升系统的可扩展性和维护性。
:::

```

### 常用组件示例

#### 提示框组合
```markdown
::: info ℹ️ 信息提示
这是一个重要的信息提示，帮助用户了解相关背景知识。
:::

::: tip 💡 实用技巧
这是一个实用技巧，可以帮助用户更高效地完成任务。
:::

::: warning ⚠️ 注意事项
这是一个警告信息，提醒用户注意潜在的问题。
:::

::: danger 🚨 重要警告
这是一个重要警告，错误操作可能导致严重后果。
:::
```

#### 复杂表格示例

```markdown
| 功能模块 | 技术栈 | 版本要求 | 部署方式 | 监控指标 |
|----------|--------|----------|----------|----------|
| 用户服务 | Spring Boot + MyBatis | ≥ 3.2.0 | Docker 容器 | CPU、内存、QPS |
| 订单服务 | Spring Boot + JPA | ≥ 3.2.0 | Kubernetes | 响应时间、错误率 |
| 商品服务 | Spring Boot + MongoDB | ≥ 3.2.0 | Docker 容器 | 连接数、查询性能 |
| 网关服务 | Spring Cloud Gateway | ≥ 4.0.0 | 集群部署 | 吞吐量、延迟 |
```

#### 代码对比示例

```markdown
::: code-group

```javascript [传统写法]
function getUser(id) {
  return fetch('/api/users/' + id)
    .then(response => response.json())
    .then(data => {
      console.log('User:', data);
      return data;
    });
}
```

```javascript [现代写法]
const getUser = async (id) => {
    const response = await fetch(`/api/users/${id}`);
    const data = await response.json();
    console.log('User:', data);
    return data;
};
```

:::

```

### 错误处理示例

#### 常见错误和解决方案
```markdown
## 常见问题排查

### 404 错误

> [!CAUTION]
> 如果遇到 404 错误，请检查以下配置：

1. **路由配置错误**
   ```javascript
   // 错误配置
   { path: '/user', component: User }
   
   // 正确配置
   { path: '/users', component: Users }
   ```

2. **文件路径错误**
   ```markdown
   <!-- 错误路径 -->
   ![图片](./img/photo.png)
   
   <!-- 正确路径 -->
   ![图片](./images/photo.png)
   ```

### 内存泄漏

::: danger 内存泄漏风险
以下代码可能导致内存泄漏：

```javascript
// 错误示例
componentDidMount()
{
    setInterval(() => {
        this.setState({count: this.state.count + 1});
    }, 1000);
}
```

正确做法是及时清理定时器：

```javascript
// 正确示例
componentDidMount()
{
    this.interval = setInterval(() => {
        this.setState({count: this.state.count + 1});
    }, 1000);
}

componentWillUnmount()
{
    clearInterval(this.interval);
}
```

:::

```

---

## 附录

### 快速参考

#### 基础语法速查
```markdown
# 标题
**粗体** *斜体* `代码`
[链接](url) ![图片](url)

# 列表
- 无序列表
1. 有序列表
- [x] 任务列表

# 表格
| 列1 | 列2 |
|-----|-----|
| 内容1 | 内容2 |
```

#### VitePress 扩展速查

```markdown
# 自定义容器

::: tip
提示内容
:::

# GitHub 警报

> [!NOTE]
> 注意内容

# 代码高亮

```js {1,3-5}
代码内容
```

# 代码组

::: code-group

```js [标题]
代码
```

:::

```

### 相关资源

- [VitePress 官方文档](https://vitepress.dev)
- [Markdown 语法指南](https://markdown.com.cn)
- [技术写作最佳实践](https://www.writethedocs.org)

---

*最后更新：2024年12月*
*版本：v1.0.0*