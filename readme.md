# SnowDice Build

## 简介

SnowDice 工程代码合并仓库，用于实现全平台自动出包!

使用 git submodule 机制整合以下四个仓库的代码
- [snowdice](https://github.com/pinenut666/snowdice)：SnowDice 核心，即 SnowDice 的后端工程代码；
- [snowdice-ui](https://github.com/pinenut666/snowdice-ui)：SnowDice 的前端工程代码；
- [sealdice-android](https://github.com/sealdice/sealdice-android)：海豹的 Android 工程代码；
- [sealdice-builtins](https://github.com/sealdice/sealdice-builtins)：其他海豹骰子所需的资源文件仓库，包括牌堆、helpdoc 等；
- [go-cqhttp](https://github.com/sealdice/go-cqhttp)：go-cqhttp 的 fork。

克隆该项目时建议先普通克隆，再只初始化顶层子模块，避免递归拉取 `sealdice-core` 内部的嵌套子模块：

```bash
git clone git@github.com:pinenut666/snowdice-build.git
cd snowdice-build
git submodule update --init
```

当前仓库已将以下子模块源切换到 SnowDice：

- `sealdice-core -> pinenut666/snowdice`
- `sealdice-ui -> pinenut666/snowdice-ui`

如果你是从旧的 clone 继续使用，请执行一次：

```bash
git submodule sync
git submodule update --init --remote
```

## 细节

### 自动构建

工作流为 [auto-build.yml](.github/workflows/auto-build.yml)，相关 jobs 功能：
- `commit-num-check`：用于检查 24 小时内是否有新 commit，没有则每天自动触发的构建不打包；
- `ui-build`：ui自动构建；
- `core-build`,`core-darwin-build`,`core-android-build`：core 的自动构建，分别为 windows&linux、macos 和 android core；
- `pc-pack`：windows、linux、macos 三端的纯 core 打包；
- `prerelease`：将 PC 压缩包发布到 `pre-release`；
- `docker-push`：构建并推送基础 Docker 镜像，仅包含 core；
- `docker-push-ai`：基于 `sealdice-core/ai` 构建并推送 AI 服务镜像；
- `clear-temp-artifact`：清理产物，保证 artifacts 整洁。

当前构建链路已移除：

- `documents`
- `lagrange`
- `lagrangeV2`
- `yogurt`
- Android APK 组装
- Docker full 镜像

这意味着：

- PC 压缩包中只包含 core 可执行文件
- Android 仅产出 `core-android` 二进制 artifact
- Docker 镜像不再内置 `data`、`lagrange`、`milky`
- 当前会产出两个 Docker 镜像：
  - `ghcr.io/<owner>/sealdice`
  - `ghcr.io/<owner>/sealdice-ai`

## 关于 issue 和 pull request

你可以通过 fork 本项目并提交 pull request 的形式贡献代码
