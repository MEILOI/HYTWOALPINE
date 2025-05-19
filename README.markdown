# Hysteria 2 一键安装脚本（Alpine Linux 移植版） 🚀  
# Hysteria 2 One-Click Install Script (Alpine Linux Port)  

![Hysteria Logo](https://raw.githubusercontent.com/apernet/hysteria/main/docs/hysteria-logo.png)

🎉 这是一个为 **Alpine Linux** 和低内存环境（最低 128MB）优化的 [MisakaNo Hysteria 2 一键安装脚本](https://github.com/Misaka-blog) 移植版，**运行时仅需约 20MB 内存**！专为资源受限的 VPS 或嵌入式系统设计，完美适配轻量级 Alpine Linux，支持**端口跳跃**等高级功能！当前版本为 **V1.0.5**，带来 NAT VPS 支持和灵活的证书选择！🔥  

🎉 This is a port of [MisakaNo's Hysteria 2 one-click install script](https://github.com/Misaka-blog), optimized for **Alpine Linux** and low-memory environments (minimum 128MB), **requiring only ~20MB of memory to run**! Designed for resource-constrained VPS or embedded systems, it’s tailored for lightweight Alpine Linux with advanced features like **port hopping**! Current version: **V1.0.5**, introducing NAT VPS support and flexible certificate options! 🔥  

## 项目信息 / Project Info 📋  

- **原作者 / Original Author**: MisakaNo の 小破站  
- **原博客 / Original Blog**: [https://blog.misaka.cyou](https://blog.misaka.cyou)  
- **原 GitHub / Original GitHub**: [https://github.com/Misaka-blog](https://github.com/Misaka-blog)  
- **移植作者 / Port Author**: TheX  
- **移植 GitHub / Port GitHub**: [https://github.com/MEILOI/HYTWOALPINE](https://github.com/MEILOI/HYTWOALPINE)  
- **移植版本 / Port Version**: v1.0.5  
- **许可证 / License**: MIT 📜  

## 移植目的 / Port Purpose 🎯  

原 Hysteria 2 脚本因 Alpine Linux 的独特包管理器（`apk`）、OpenRC 初始化系统和极简环境而不兼容。此移植旨在：  
The original Hysteria 2 script was incompatible with Alpine Linux due to its unique package manager (`apk`), OpenRC init system, and minimal environment. This port aims to:  

- 在 Alpine Linux 上启用 Hysteria 2 部署，最低 128MB 内存，运行仅需 ~20MB！💾  
  Enable Hysteria 2 deployment on Alpine Linux with a minimum of 128MB memory, requiring only ~20MB to run! 💾  
- 保留交互式菜单，新增**端口跳跃**支持，提升网络灵活性和安全性！🌐  
  Retain the interactive menu, with added **port hopping** support for enhanced network flexibility and security! 🌐  
- 优化资源占用，适配内存受限环境。  
  Optimize resource usage for memory-constrained environments.  
- 确保与 BusyBox 系统的兼容性。  
  Ensure compatibility with BusyBox systems.  
- **V1.0.5 新增 / New in V1.0.5**: 支持 NAT VPS 环境，新增证书选择（自签名、ACME 自动证书、自定义证书）。  
  Support for NAT VPS environments and new certificate options (self-signed, ACME auto-cert, custom cert).  

## 与原版的差异 / Differences from Original ⚖️  

| 功能/方面<br>Feature | 原版<br>Original | V1.0.4 移植版<br>V1.0.4 Port | V1.0.5 移植版<br>V1.0.5 Port |
|----------------------|---------------------------------------------|-----------------------------------------------|-----------------------------------------------|
| **支持系统**<br>Supported Systems | Debian、Ubuntu、CentOS 等 | Alpine Linux（及其他 BusyBox 系统） | Alpine Linux（及其他 BusyBox 系统） |
| **系统检测**<br>System Check | 检查特定 Linux 发行版 | 移除系统检测，支持通用 Linux | 移除系统检测，支持通用 Linux |
| **初始化系统**<br>Init System | Systemd | 替换为 `nohup`（移除 OpenRC） | 替换为 `nohup`（移除 OpenRC） |
| **包管理器**<br>Package Manager | `apt`、`yum`、`dnf` | 支持 `apk`，`apt`/`yum` 回退 | 仅支持 `apk`，移除 `apt`/`yum` 回退 |
| **依赖安装**<br>Dependency Install | 需要手动安装 | 自动安装 `bash`、`openssl`、`curl`、`wget`、`iptables`、`qrencode` | 自动安装 `bash`、`openssl`、`curl`、`wget` |
| **内存优化**<br>Memory Optimization | 未针对低内存优化 | QUIC 窗口减小，占用 ~15-20MB | QUIC 窗口减小，占用 ~20MB |
| **默认伪装网站**<br>Default Masquerade Site | `maimai.sega.jp` | 改为 `www.bing.com` | 改为 `www.bing.com` |
| **防火墙管理**<br>Firewall Management | 假设 `iptables` 存在 | 检查 `iptables`，缺失时提示 | NAT VPS 跳过 `iptables`，需手动放行 |
| **进程检查**<br>Process Check | 使用 `ps -p` | 使用 `ps | grep`，兼容 BusyBox | 使用 `ps | grep`，兼容 BusyBox |
| **证书生成**<br>Certificate Generation | 假设 `openssl` 存在 | 显式检查 `openssl`，自动安装 | 支持自签名、ACME、自定义证书 |
| **端口跳跃**<br>Port Hopping | 支持 | 移除以简化 | **强化支持**，通过配置启用 🌟 |
| **ACME 证书**<br>ACME Certificates | 支持 | 移除以减少依赖 | 重新引入 ACME 证书支持 |

## 主要优化 / Key Optimizations 🛠️  

- **超低内存占用 / Ultra-Low Memory Usage**: QUIC 窗口大小减小（`initStreamReceiveWindow: 8388608`, `maxStreamReceiveWindow: 8388608`），Hysteria 2 运行仅需 ~20MB 内存，最低支持 128MB 设备！💾  
- **BusyBox 兼容性 / BusyBox Compatibility**: 调整命令（如 `ps`）以适配 BusyBox 的精简工具集。  
- **端口跳跃支持 / Port Hopping Support**: **V1.0.5 强化**，通过配置文件启用端口跳跃，动态切换端口以提升安全性和抗封锁能力！🔄  
- **简化依赖 / Simplified Dependencies**: 移除复杂功能，仅需核心工具（`bash`、`curl`、`wget`、`openssl`）。  
- **通用 Linux 支持 / Universal Linux Support**: 移除严格的系统检查，脚本可在任何 Linux 系统上运行（需基本工具）。  
- **V1.0.5 新增 / New in V1.0.5**:  
  - 支持 NAT VPS 环境，跳过 `iptables`，提示手动放行端口。  
  - 灵活证书选择：必应自签名、ACME 自动证书、自定义证书路径。📜  
  - 改进错误提示和分享链接同步。  

## 修复的 Bug 和变更 / Bug Fixes and Changes 🐞  

### v1.0.5 (2025-05-19)  
- **新增 NAT VPS 支持 / NAT VPS Support** 🌐:  
  - **变更 / Change**: 移除 `iptables` 和 `ip6tables` 依赖，跳过防火墙配置。  
  - **影响 / Impact**: 用户需在 VPS 控制面板或主机防火墙手动放行 UDP 端口。  
  - **细节 / Details**: 安装和端口修改时提示 NAT VPS 用户确保端口映射。  
- **新增证书选择功能 / Certificate Selection** 📜:  
  - **变更 / Change**: 支持必应自签名（默认）、ACME 自动证书、自定义证书路径。  
  - **影响 / Impact**: 增强灵活性，适合需要正规证书或自定义证书的用户。  
  - **细节 / Details**: ACME 使用 `acme.sh` 自动申请，需提供域名；自定义证书需提供证书和私钥路径。  
- **强化端口跳跃 / Enhanced Port Hopping** 🔄:  
  - **变更 / Change**: 通过配置文件启用端口跳跃，动态切换端口以提升安全性。  
  - **影响 / Impact**: 增强抗封锁能力，适合复杂网络环境。  
  - **细节 / Details**: 在 `hy-client.yaml` 中配置 `transport.udp.hopInterval`（默认 30s）。  
- **优化依赖管理 / Optimized Dependency Management**:  
  - **变更 / Change**: 移除 `iptables`、`ip6tables`、`qrencode` 依赖，仅保留核心依赖。  
  - **影响 / Impact**: 简化安装流程，移除二维码生成功能。  
  - **细节 / Details**: 若 `apk update` 失败，提示更换镜像源（`mirrors.tuna.tsinghua.edu.cn`）。  
- **改进错误提示 / Improved Error Handling**:  
  - **变更 / Change**: 增强 root 权限检查，显示当前用户和 UID。  
  - **影响 / Impact**: 更清晰的错误信息，便于排查。  
- **改进配置更新 / Improved Config Update**:  
  - **变更 / Change**: 端口和密码修改时同步更新 `url.txt` 分享链接。  
  - **影响 / Impact**: 确保客户端配置文件和分享链接一致。  

### v1.0.4 (2025-05-19)  
- 改进依赖安装，分步处理核心（`curl`, `wget`, `bash`, `openssl`, `iptables`, `ip6tables`）和可选依赖（`qrencode`）。  
- 解决 `qrencode` 缺失导致安装失败的问题，失败时仅警告。  
- 添加 `apk cache clean`，提供备用镜像源提示。  

### v1.0.3 (2025-05-19)  
- 自动添加 `community` 仓库，尝试安装所有依赖。  

### v1.0.2 (2025-05-19)  
- 集成 `openssl` 安装，增强“一键”体验。  

### v1.0.1 (2025-05-19)  
- 修复 `check_dependencies` 语法错误和 `menu` 函数笔误。  

### v1.0 (初始移植 / Initial Port)  
- 移除系统检测，用 `nohup` 替换 OpenRC，适配 BusyBox。  

## 前置条件 / Prerequisites ⚙️  

- **系统 / System**: Alpine Linux（建议 3.18 或更高版本）或任何 BusyBox 系统。  
- **内存 / Memory**: 最低 128MB（Hysteria 2 运行仅需 ~20MB，64MB 内存不足以稳定运行）。  
- **权限 / Permissions**: 需要 root 权限。  
- **架构 / Architecture**: 默认 x86_64（arm64/armv7 需修改二进制 URL）。  
- **网络 / Network**: 需要公网 IP 或 NAT，UDP 端口已开放。  
- **依赖 / Dependencies**: `bash`、`curl`、`wget`、`openssl`（自动安装）。  
- **NAT VPS 注意 / NAT VPS Note**: 确保 UDP 端口已由 VPS 提供商映射到公网！🌍  

## 安装 / Installation 🚀  

### 一键安装 / One-Click Install  
```bash
curl -o hysteria.sh -fsSL https://raw.githubusercontent.com/MEILOI/HYTWOALPINE/main/hysteria.sh && chmod +x hysteria.sh && ./hysteria.sh
```

### 手动安装 / Manual Install  
```bash
curl -o hysteria.sh -fsSL https://raw.githubusercontent.com/MEILOI/HYTWOALPINE/main/hysteria.sh
chmod +x hysteria.sh
./hysteria.sh
```

### 依赖安装（若失败） / Dependency Install (If Failed)  
如果脚本提示依赖安装失败，运行以下命令：  
If the script reports dependency installation failure, run:  
```bash
echo 'https://dl-cdn.alpinelinux.org/alpine/v3.21/main' > /etc/apk/repositories
echo 'https://dl-cdn.alpinelinux.org/alpine/v3.21/community' >> /etc/apk/repositories
apk update
apk add --no-cache bash curl wget openssl
```
替换 `v3.21` 为你的 Alpine 版本（查看：`cat /etc/alpine-release`）。  
Replace `v3.21` with your Alpine version (check: `cat /etc/alpine-release`).  

#### 更换镜像源 / Change Mirror Source  
如果默认镜像源（`dl-cdn.alpinelinux.org`）不可用，尝试以下镜像：  
If the default mirror (`dl-cdn.alpinelinux.org`) is unavailable, try:  
```bash
sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories
apk update
apk add --no-cache bash curl wget openssl
```
其他可选镜像源 / Other mirror options:  
- `mirrors.aliyun.com`  
- `mirrors.ustc.edu.cn`  
运行以下命令切换：  
Run to switch:  
```bash
sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories
apk update
apk add --no-cache bash curl wget openssl
```

### 防火墙（NAT VPS） / Firewall (NAT VPS) 🔒  
- NAT VPS 用户需在 VPS 控制面板或主机防火墙手动放行 UDP 端口（例如 55555）。  
  NAT VPS users must manually open UDP ports (e.g., 55555) in the VPS control panel or host firewall.  
- 示例（使用 `nftables`） / Example (using `nftables`):  
  ```bash
  nft add rule ip filter input udp dport 55555 accept
  ```
- 或使用 `iptables`（若主机支持） / Or use `iptables` (if supported):  
  ```bash
  iptables -I INPUT -p udp --dport 55555 -j ACCEPT
  ```

## 使用方法 / Usage Guide 🎮  

1. 运行 `./hysteria.sh`，选择选项 `1` 安装。  
   Run `./hysteria.sh` and select option `1` to install.  
2. 配置 / Configure:  
   - **证书 / Certificate**: 选择必应自签名（默认）、ACME 自动证书或自定义证书路径。📜  
   - **端口 / Port**: 输入 UDP 端口（1-65535）或回车随机分配。  
   - **密码 / Password**: 设置密码或回车生成随机密码。  
   - **伪装网站 / Masquerade Site**: 输入网站（如 `www.bing.com`）或回车使用默认。  
   - **端口跳跃 / Port Hopping**: 默认启用，配置 `hopInterval`（如 30s）以动态切换端口！🔄  
3. 脚本生成 / Script Output:  
   - 客户端配置文件 / Client Config: `/root/hy/hy-client.yaml`  
   - 分享链接 / Share Link: `/root/hy/url.txt`  
4. 导入客户端 / Import to Client:  
   - 自签名证书需启用 `insecure: true`。  
   - ACME 或自定义证书需确保域名正确解析。  
5. 使用菜单（选项 3-6）管理服务：启动/停止、修改配置、更新内核。  
   Use the menu (options 3-6) to manage the service: start/stop, modify config, update core.  
6. **NAT VPS 注意 / NAT VPS Note**: 确保端口已映射到公网，否则客户端无法连接！🌐  
7. **端口跳跃提示 / Port Hopping Tip**: 检查 `hy-client.yaml` 中的 `transport.udp.hopInterval`，调整间隔（30s-60s）以优化性能！  

## 安装后操作 / Post-Installation Steps 🛠️  

- **验证服务 / Verify Service**:  
  ```bash
  ps | grep hysteria
  cat /var/log/hysteria.log
  netstat -tunlp | grep <port>
  ```
- **添加开机启动 / Add Auto-Start**:  
  ```bash
  crontab -e
  @reboot nohup /usr/local/bin/hysteria server --config /etc/hysteria/config.yaml > /var/log/hysteria.log 2>&1 &
  ```
- **故障排除 / Troubleshoot**:  
  - 查看 `/var/log/hysteria.log` 检查错误。  
  - 确保 UDP 端口已放行（NAT VPS 用户联系提供商）。  
  - 验证依赖：`command -v bash curl wget openssl`。  

## 故障排除 / Troubleshooting 🐞  

1. **依赖安装失败 / Dependency Installation Failure**:  
   - **问题 / Issue**: `apk` 提示 `no such package` 或网络超时。  
   - **解决 / Solution**:  
     - 确保网络正常，检查 `/etc/apk/repositories` 是否包含 `main` 和 `community` 仓库：  
       ```bash
       cat /etc/apk/repositories
       ```
     - 手动配置仓库：  
       ```bash
       echo 'https://dl-cdn.alpinelinux.org/alpine/v3.21/main' > /etc/apk/repositories
       echo 'https://dl-cdn.alpinelinux.org/alpine/v3.21/community' >> /etc/apk/repositories
       apk update
       apk add --no-cache bash curl wget openssl
       ```
     - 如果仍失败，切换镜像源：  
       ```bash
       sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories
       apk update
       apk add --no-cache bash curl wget openssl
       ```
     - 其他镜像源选项：`mirrors.aliyun.com`, `mirrors.ustc.edu.cn`。  
   - **验证 / Verify**:  
     ```bash
     command -v bash curl wget openssl
     ```
2. **内存不足 / Insufficient Memory**:  
   - **问题 / Issue**: 64MB 内存设备运行失败或崩溃。  
   - **解决 / Solution**:  
     - 本脚本最低要求 128MB 内存，Hysteria 2 运行占用 ~20MB。64MB 内存不足以稳定运行，可能导致进程终止。  
     - 建议升级到 128MB 或更高内存的 VPS。  
     - 检查内存使用：  
       ```bash
       free -m
       ```
     - 释放内存（若可能）：  
       ```bash
       sync; echo 3 > /proc/sys/vm/drop_caches
       ```
3. **网络问题 / Network Issues**:  
   - **问题 / Issue**: 无法下载 Hysteria 二进制或获取 IP。  
   - **解决 / Solution**:  
     - 检查网络连通性：  
       ```bash
       ping dl-cdn.alpinelinux.org
       curl -I https://github.com
       ```
     - 使用备用 DNS：  
       ```bash
       echo "nameserver 8.8.8.8" > /etc/resolv.conf
       ```
     - 尝试其他网络源：  
       ```bash
       wget -O /usr/local/bin/hysteria https://github.com/apernet/hysteria/releases/latest/download/hysteria-linux-amd64
       ```
4. **端口未放行 / Port Not Opened**:  
   - **问题 / Issue**: 客户端无法连接。  
   - **解决 / Solution**:  
     - NAT VPS 用户需在控制面板或主机防火墙放行 UDP 端口：  
       ```bash
       nft add rule ip filter input udp dport 55555 accept
       ```
     - 或使用 `iptables`（若支持）：  
       ```bash
       iptables -I INPUT -p udp --dport 55555 -j ACCEPT
       ```
     - 联系 VPS 提供商确保端口映射到公网。  
     - 验证端口开放：  
       ```bash
       netstat -tunlp | grep 55555
       ```
5. **ACME 证书申请失败 / ACME Certificate Failure**:  
   - **问题 / Issue**: 域名未解析或网络问题。  
   - **解决 / Solution**:  
     - 确保域名已解析到服务器 IP：  
       ```bash
       ping <your-domain>
       ```
     - 检查 80 端口是否开放（ACME 需要）：  
       ```bash
       netstat -tunlp | grep :80
       ```
     - 重新运行 ACME：  
       ```bash
       ~/.acme.sh/acme.sh --issue -d "<your-domain>" --standalone
       ```
6. **端口跳跃问题 / Port Hopping Issues**:  
   - **问题 / Issue**: 端口切换不稳定或客户端断连。  
   - **解决 / Solution**:  
     - 检查 `hy-client.yaml` 中的 `hopInterval`，建议 30s-60s：  
       ```bash
       cat /root/hy/hy-client.yaml | grep hopInterval
       ```
     - 调整间隔（例如 60s）：  
       ```bash
       sed -i 's/hopInterval: 30s/hopInterval: 60s/' /root/hy/hy-client.yaml
       ```
     - 重启服务：  
       ```bash
       kill $(cat /run/hysteria.pid); nohup /usr/local/bin/hysteria server --config /etc/hysteria/config.yaml > /var/log/hysteria.log 2>&1 &
       ```

## 贡献 / Contributing 🤝  

欢迎提交问题或拉取请求至 [https://github.com/MEILOI/HYTWOALPINE](https://github.com/MEILOI/HYTWOALPINE)！  
Welcome to submit issues or pull requests to [https://github.com/MEILOI/HYTWOALPINE](https://github.com/MEILOI/HYTWOALPINE)!  

## 致谢 / Acknowledgments 🙏  

- 感谢 MisakaNo 提供的原脚本和灵感！  
  Thanks to MisakaNo for the original script and inspiration!  
- 感谢 Hysteria 团队开发的 [Hysteria 2](https://github.com/apernet/hysteria) 代理！  
  Thanks to the Hysteria team for developing [Hysteria 2](https://github.com/apernet/hysteria)!  

## 许可证 / License 📜  

本项目采用 MIT 许可证，详情见 [LICENSE](LICENSE)。  
This project is licensed under the MIT License, see [LICENSE](LICENSE) for details.  

🌟 感谢使用 HYTWOALPINE！期待你的反馈和贡献！🚀  
🌟 Thank you for using HYTWOALPINE! Looking forward to your feedback and contributions! 🚀