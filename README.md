# Obscura Termux Installer

[Obscura](https://github.com/h4ckf0r0day/obscura) — 一个面向 AI Agent 和网页抓取的无头浏览器，本脚本将其打包适配为 Termux 环境。

本安装器直接使用 **Obscura 官方仓库的 glibc 预编译二进制**，通过 glibc wrapper 脚本解决 Termux Bionic 兼容性问题。

## 安装

```bash
bash -c "$(curl -L https://raw.githubusercontent.com/zexjpg/obscura-termux-install/main/install-obscura.sh)"
```

## 卸载

```bash
bash -c "$(curl -L https://raw.githubusercontent.com/zexjpg/obscura-termux-install/main/install-obscura.sh)" remove
```

## 工作原理

Termux 使用 Android 的 Bionic C 库，而 Obscura 官方预编译二进制基于 glibc 编译，两者不兼容。本脚本的解决方案：

1. 从 GitHub Releases 下载官方 `obscura-aarch64-linux.tar.gz`
2. 将二进制安装到 `$PREFIX/opt/obscura/`
3. 创建 glibc wrapper 脚本，使用 `ld-linux-aarch64.so.1` 作为动态链接器
4. 在 `$PREFIX/bin/` 创建 symlink，使 `obscura` 和 `obscura-worker` 可直接调用

## 环境要求

- Android 设备上的 **Termux**（aarch64 / ARM64 架构）
- 已安装 **glibc** 包：

```bash
pkg install glibc-repo
pkg install glibc
```

## 功能特性

- **自动更新**：检测已安装版本与最新版本，已是最新则跳过
- **一键安装**：单脚本完成，仅依赖 `curl` 和 `tar`
- **彻底卸载**：`remove` 参数清理所有文件

## 使用示例

```bash
# 查看版本
obscura -V

# 抓取页面并导出为文本
obscura fetch https://example.com --dump text

# 启动 CDP 服务器（兼容 Puppeteer / Playwright）
obscura serve --port 9222

# 隐身模式
obscura --stealth fetch https://example.com
```

## 许可

本安装脚本按原样提供。Obscura 本身由 [h4ckf0r0day](https://github.com/h4ckf0r0day/obscura) 开发。
