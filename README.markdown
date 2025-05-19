# Hysteria 2 一键安装脚本（Alpine Linux 移植版）

![Hysteria Logo](https://raw.githubusercontent.com/apernet/hysteria/main/docs/hysteria-logo.png)

这是 [MisakaNo 的 Hysteria 2 一键安装脚本](https://github.com/Misaka-blog) 的移植版本，专为 **Alpine Linux** 和低内存环境（128MB）优化。原脚本针对通用 Linux 发行版设计，而此版本适配了轻量级 Alpine Linux，常用于资源受限的 VPS 或嵌入式系统。

## 项目信息

- **原作者**：MisakaNo の 小破站
- **原博客**：[https://blog.misaka.cyou](https://blog.misaka.cyou)
- **原 GitHub**：[https://github.com/Misaka-blog](https://github.com/Misaka-blog)
- **移植作者**：TheX
- **移植 GitHub**：[https://github.com/MEILOI/HYTWOALPINE](https://github.com/MEILOI/HYTWOALPINE)
- **移植版本**：v1.0.4
- **许可证**：MIT

## 移植目的

原 Hysteria 2 脚本因 Alpine Linux 的独特包管理器（`apk`）、OpenRC 初始化系统和极简环境而不兼容。此移植旨在：
- 在 Alpine Linux 上启用 Hysteria 2 部署，特别针对低内存设备（128MB）。
- 保留原脚本的交互式菜单和功能。
- 优化资源占用，适配内存受限环境。
- 确保与 BusyBox 系统的兼容性（Alpine Linux 常见）。

## 与原版的差异

| 功能/方面                     | 原版                                         | Alpine 移植版 (v1.0.4)                        |
|-------------------------------|---------------------------------------------|-----------------------------------------------|
| **支持系统**                 | Debian、Ubuntu、CentOS 等                   | Alpine Linux（及其他 BusyBox 系统）           |
| **系统检测**                 | 检查特定 Linux 发行版                       | 移除系统检测，支持通用 Linux                  |
| **初始化系统**               | Systemd                                    | 替换为 `nohup`（移除 OpenRC）                 |
| **包管理器**                 | `apt`、`yum`、`dnf`                        | `apk`（支持 `apt`、`yum` 回退）               |
| **依赖安装**                 | 需要手动安装                                | 自动安装 `bash`、`openssl`、`iptables` 等，`qrencode` 可选 |
| **内存优化**                 | 未针对低内存设备优化                        | QUIC 窗口减小（8388608），占用 ~15-20MB       |
| **默认伪装网站**             | `maimai.sega.jp`                           | 改为 `www.bing.com`                           |
| **防火墙管理**               | 假设 `iptables` 存在                        | 检查 `iptables`，缺失时提示手动配置           |
| **进程检查**                 | 使用 `ps -p`                                | 使用 `ps | grep`，兼容 BusyBox                |
| **证书生成**                 | 假设 `openssl` 存在                         | 显式检查 `openssl`，自动安装                  |
| **端口跳跃**                 | 支持                                        | 移除以简化并降低资源占用                      |
| **ACME 证书**                | 支持                                        | 移除以减少依赖                                |

## 主要优化

- **低内存占用**：QUIC 窗口大小减小（`initStreamReceiveWindow: 8388608`, `maxStreamReceiveWindow: 8388608`），Hysteria 2 在 128MB 设备上通常占用 15-20MB 内存。
- **BusyBox 兼容性**：调整命令（如 `ps`）以适配 BusyBox 的精简工具集。
- **简化依赖**：移除复杂功能（端口跳跃、ACME 证书），减少依赖和内存占用。
- **通用 Linux 支持**：移除严格的系统检查，允许脚本在任何 Linux 系统上运行（需基本工具：`bash`、`curl`、`wget`、`openssl`、`iptables`、`qrencode`）。
- **改进错误处理**：显式检查 `openssl` 和 `iptables`，自动安装核心依赖，`qrencode` 失败不中断脚本。

## 修复的 Bug 和变更

### v1.0.4 (2025-05-19)
- **改进依赖安装**：
  - **变更**：分步安装核心依赖（`curl`, `wget`, `bash`, `openssl`, `iptables`, `ip6tables`）和可选依赖（`qrencode`）。
  - **影响**：解决 `qrencode` 缺失导致整个安装失败的问题，`qrencode` 失败时仅警告，不中断脚本。
  - **细节**：添加 `apk cache clean`，强制更新仓库，提供备用镜像源（`mirrors.tuna.tsinghua.edu.cn`）提示。
- **增强仓库管理**：
  - 动态检测 Alpine 版本，确保 `main` 和 `community` 仓库正确配置。
  - 提供详细的故障排除命令。

### v1.0.3 (2025-05-19)
- **集成所有依赖安装**：
  - 自动添加 `community` 仓库，尝试安装 `bash`, `curl`, `wget`, `openssl`, `iptables`, `ip6tables`, `qrencode`。
  - 提供手动配置仓库的提示。

### v1.0.2 (2025-05-19)
- **集成 `openssl` 安装**：
  - 自动运行 `apk add --no-cache openssl`（及其他依赖）。
  - 增强“一键”体验。

### v1.0.1 (2025-05-19)
- **修复 `check_dependencies` 语法错误**：
  - 修复 `yum` 分支缺少 `then` 的问题。
- **修复 `menu` 函数笔误**：
  - 更正 `inst_*\insthysteria` 为 `insthysteria`。

### v1.0 (初始移植)
1. **系统检测失败**：移除系统检测，支持任意 Linux。
2. **OpenRC 不兼容**：用 `nohup` 替换 OpenRC。
3. **BusyBox `ps` 不兼容**：用 `ps | grep` 替换 `ps -p`。
4. **缺少 `openssl`**：添加检查。
5. **缺少 `iptables`**：添加检查，提示手动放行。
6. **BusyBox 端口检查**：简化以适配 BusyBox 的 `awk`。

## 前置条件

- **系统**：Alpine Linux（建议 3.18 或更高版本）或任何 BusyBox 系统。
- **内存**：最低 128MB（Hysteria 2 占用 ~15-20MB）。
- **权限**：需要 root 权限。
- **架构**：默认 x86_64。若为 arm64/armv7，需修改 `insthysteria` 中的二进制 URL。
- **网络**：需要公网 IP 或 NAT，且 UDP 端口已开放。
- **依赖**：`bash`、`curl`、`wget`、`openssl`、`iptables`、`ip6tables`（自动安装），`qrencode`（可选，自动尝试安装）。

## 安装

### 一键安装
运行以下命令，自动下载并执行脚本：
```bash
curl -o hysteria.sh -fsSL https://raw.githubusercontent.com/MEILOI/HYTWOALPINE/main/hysteria.sh && chmod +x hysteria.sh && ./hysteria.sh
```

### 手动安装
```bash
curl -o hysteria.sh -fsSL https://raw.githubusercontent.com/MEILOI/HYTWOALPINE/main/hysteria.sh
chmod +x hysteria.sh
./hysteria.sh
```

### 依赖安装（若自动安装失败）
如果脚本提示依赖安装失败，运行：
```bash
echo 'https://dl-cdn.alpinelinux.org/alpine/v3.21/main' > /etc/apk/repositories
echo 'https://dl-cdn.alpinelinux.org/alpine/v3.21/community' >> /etc/apk/repositories
apk update
apk add --no-cache bash curl wget openssl iptables ip6tables qrencode
```
替换 `v3.21` 为你的 Alpine 版本（查看：`cat /etc/alpine-release`）。

#### 更换镜像源
如果默认镜像源（`dl-cdn.alpinelinux.org`）不可用，尝试：
```bash
sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories
apk update
apk add --no-cache bash curl wget openssl iptables ip6tables qrencode
```

### 防火墙
- 若无 `iptables`，需在 VPS 控制面板手动放行 UDP 端口（例如 55555）。
- 使用 `nftables` 示例：
  ```bash
  nft add rule ip filter input udp dport 55555 accept
  ```

## 使用方法

1. 运行 `./hysteria.sh`，选择选项 `1` 安装。
2. 配置：
   - **端口**：输入 UDP 端口（1-65535）或回车随机分配。
   - **密码**：设置密码或回车生成随机密码。
   - **伪装网站**：输入网站（如 `www.bing.com`）或回车使用默认。
3. 脚本生成：
   - 客户端配置文件：`/root/hy/hy-client.yaml`
   - 分享链接：`/root/hy/url.txt`
4. 将配置文件或链接导入 Hysteria 2 客户端，确保启用 `insecure: true`（自签名证书）。
5. 通过菜单（选项 3-6）管理服务：启动/停止、修改配置、更新内核。

## 安装后操作

- **验证服务**：
  ```bash
  ps | grep hysteria
  cat /var/log/hysteria.log
  netstat -tunlp | grep <port>
  ```
- **添加开机启动**：
  ```bash
  crontab -e
  @reboot nohup /usr/local/bin/hysteria server --config /etc/hysteria/config.yaml > /var/log/hysteria.log 2>&1 &
  ```
- **故障排除**：
  - 查看 `/var/log/hysteria.log` 检查错误。
  - 确保 UDP 端口已放行。
  - 验证依赖：`command -v bash curl wget openssl iptables ip6tables qrencode`。

## 故障排除

1. **依赖安装失败**：
   - **问题**：`apk` 提示 `no such package`（如 `qrencode`）。
   - **解决**：
     ```bash
     echo 'https://dl-cdn.alpinelinux.org/alpine/v3.21/main' > /etc/apk/repositories
     echo 'https://dl-cdn.alpinelinux.org/alpine/v3.21/community' >> /etc/apk/repositories
     apk update
     apk add --no-cache bash curl wget openssl iptables ip6tables qrencode
     ```
     或更换镜像源：
     ```bash
     sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories
     apk update
     apk add --no-cache bash curl wget openssl iptables ip6tables qrencode
     ```
   - 检查 Alpine 版本：`cat /etc/alpine-release`。
2. **网络问题**：
   - **问题**：无法下载 Hysteria 二进制或获取 IP。
   - **解决**：确保系统能访问 `github.com` 和 `ip.gs`：
     ```bash
     ping dl-cdn.alpinelinux.org
     curl -I https://github.com
     ```
3. **端口未放行**：
   - **问题**：客户端无法连接。
   - **解决**：在 VPS 控制面板或使用 `nftables` 放行 UDP 端口：
     ```bash
     nft add rule ip filter input udp dport 55555 accept
     ```
4. **qrencode 不可用**：
   - **问题**：二维码生成功能缺失。
   - **解决**：手动安装 `qrencode` 或忽略（不影响核心功能）。

## 贡献

欢迎提交问题或拉取请求至 [https://github.com/MEILOI/HYTWOALPINE](https://github.com/MEILOI/HYTWOALPINE)。

## 致谢

- 感谢 MisakaNo 提供的原脚本和灵感。
- 感谢 Hysteria 团队开发的 [Hysteria 2](https://github.com/apernet/hysteria) 代理。

## 许可证

本项目采用 MIT 许可证，详情见 [LICENSE](LICENSE)。