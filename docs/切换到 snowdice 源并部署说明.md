# 切换到 SnowDice 源并部署说明

本文档说明 `snowdice-build` 仓库中与 SnowDice 部署直接相关的改动，以及后续如何继续维护。

## 本次修改了什么

### 1. 切换 core / ui 子模块源

修改文件：

- `.gitmodules`

修改结果：

- `sealdice-core` 改为 `git@github.com:pinenut666/snowdice.git`
- `sealdice-ui` 改为 `git@github.com:pinenut666/snowdice-ui.git`

这样 GitHub Actions 和本地 `git submodule update --remote` 拉到的就是你自己的 core / ui 仓库，而不是官方 `sealdice`。

### 2. 修正本地更新脚本

修改文件：

- `update-submodules.sh`
- `update-submodules.cmd`

修改内容：

- 增加 `git submodule sync`
- 改为使用 `git submodule update --init --remote`
- 没有变更时不再强行 commit

这样做的原因是：

- 旧脚本会把子模块硬重置到 `origin/master`
- 当 `.gitmodules` 里的源地址变更后，先 `sync` 才能确保本地配置跟上
- `update --remote` 会按 `.gitmodules` 中的分支设置更新子模块，行为更稳定

### 3. 修正自动构建工作流的子模块 checkout

修改文件：

- `.github/workflows/auto-build.yml`

修改内容：

- 在需要读取子模块的 job 中显式拉取顶层子模块

原因：

- 原工作流在没有拉取子模块的情况下直接执行 `cd sealdice-ui` / `cd sealdice-core`
- 同时递归拉取会继续进入 `sealdice-core` 内部的嵌套子模块，容易把构建重新拖回旧源
- 现在改为只处理顶层子模块，既能读取 core / ui，又能避免递归失败

### 4. 修正 `scripts/bump.sh` 的仓库硬编码

修改文件：

- `scripts/bump.sh`

修改内容：

- 不再写死 `sealdice/sealdice-build`
- 改为从当前仓库的 `origin` 自动推导 `owner/repo`

这样你 fork 之后直接用自己的构建仓库，也能正确 watch 自己的 GitHub Actions。

### 5. 精简自动构建范围

当前 `Auto Build` 只保留这些输出链路：

- `ui-build`
- `core-build`
- `core-darwin-build`
- `core-android-build`
- `pc-pack`
- `prerelease`
- `docker-push`
- `docker-push-ai`

已经移除这些额外装配步骤：

- `documents`
- `lagrange`
- `lagrangeV2`
- `yogurt`
- Android APK 打包
- Docker full 镜像

现在的结果是：

- PC 预发布包只包含 core 可执行文件
- Android 只产出 core 二进制 artifact
- Docker 镜像只包含 core，不再拷入 `data`、`lagrange`、`milky`
- 同时会额外从 `sealdice-core/ai` 目录构建并推送 AI 服务镜像

### 6. 增加 AI Docker 镜像推送

修改文件：

- `.github/workflows/auto-build.yml`

修改内容：

- 增加 `docker-push-ai` job
- 使用 `sealdice-core/ai/Dockerfile` 直接构建
- 推送到 `ghcr.io/<owner>/sealdice-ai`

这样做的原因是：

- `sealdice-core/ai` 已经自带独立 `Dockerfile`
- 该目录本身就包含运行 AI 服务需要的 `requirements.txt`、字体和运行时目录初始化
- 不需要再额外经过 core 编译产物装配，就可以并行产出第二个镜像

## 当前应当跟踪的仓库

本仓库现在的核心依赖关系是：

- `sealdice-core` 子模块实际跟踪 `pinenut666/snowdice`
- `sealdice-ui` 子模块实际跟踪 `pinenut666/snowdice-ui`
- `sealdice-builtins` 继续跟踪官方资源仓库
- `sealdice-android` 继续跟踪官方 Android 仓库

这意味着你只需要维护：

- SnowDice core
- SnowDice UI
- snowdice-build 本身

## 现有 clone 如何切换到新源

如果你已经有旧的 `snowdice-build` 工作目录，需要执行：

```bash
git pull --ff-only
git submodule sync
git submodule update --init --remote
```

执行后可用下面的命令确认：

```bash
git config -f .gitmodules --get submodule.sealdice-core.url
git config -f .gitmodules --get submodule.sealdice-ui.url
git submodule status
```

如果你是新 clone，建议不要使用 `git clone --recursive`，而是：

```bash
git clone git@github.com:pinenut666/snowdice-build.git
cd snowdice-build
git submodule update --init
```

## 日常更新方式

以后更新子模块，直接运行：

Linux / macOS：

```bash
./update-submodules.sh
```

Windows：

```bat
update-submodules.cmd
```

它们会做这些事：

1. 拉取当前构建仓库最新代码
2. 同步子模块 URL 配置
3. 将子模块更新到各自跟踪分支的最新提交
4. 如果 gitlink 有变化，就自动提交并推送

## 部署与构建建议

如果你要通过 GitHub Actions 持续出包，建议确认以下几点：

1. 仓库默认工作分支仍为 `dev`
2. `Auto Build` 工作流监听的仍是 `dev`
3. 你的 `snowdice` 和 `snowdice-ui` 目标提交已经推到远端
4. 仓库 Actions Secrets 已按原流程配置完整

常用操作：

```bash
git checkout dev
./update-submodules.sh
git push origin dev
```

推到 `dev` 后，`Auto Build` 会按当前子模块指针拉取对应的 SnowDice core / ui 代码并开始构建。

## 这次修改后的维护原则

以后如果你还要继续切源，只需要优先检查这几个位置：

- `.gitmodules`
- `update-submodules.sh`
- `update-submodules.cmd`
- `.github/workflows/auto-build.yml`
- `scripts/bump.sh`

其中真正决定 core / ui 来源的是 `.gitmodules`，其余文件是为了保证本地更新和 CI 不会继续指回旧源或因为子模块未初始化而失败。
