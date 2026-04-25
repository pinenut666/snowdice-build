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

- 增加 `git submodule sync --recursive`
- 改为使用 `git submodule update --init --recursive --remote`
- 没有变更时不再强行 commit

这样做的原因是：

- 旧脚本会把子模块硬重置到 `origin/master`
- 当 `.gitmodules` 里的源地址变更后，先 `sync` 才能确保本地配置跟上
- `update --remote` 会按 `.gitmodules` 中的分支设置更新子模块，行为更稳定

### 3. 修正自动构建工作流的子模块 checkout

修改文件：

- `.github/workflows/auto-build.yml`

修改内容：

- 在 `commit-num-check` 的 checkout 中加入 `submodules: recursive`

原因：

- 原工作流在没有拉取子模块的情况下直接执行 `cd sealdice-ui` / `cd sealdice-core`
- 这会导致工作流在检查 commit ID 阶段就失败

### 4. 修正 `scripts/bump.sh` 的仓库硬编码

修改文件：

- `scripts/bump.sh`

修改内容：

- 不再写死 `sealdice/sealdice-build`
- 改为从当前仓库的 `origin` 自动推导 `owner/repo`

这样你 fork 之后直接用自己的构建仓库，也能正确 watch 自己的 GitHub Actions。

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
git submodule sync --recursive
git submodule update --init --recursive --remote
```

执行后可用下面的命令确认：

```bash
git config -f .gitmodules --get submodule.sealdice-core.url
git config -f .gitmodules --get submodule.sealdice-ui.url
git submodule status
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
