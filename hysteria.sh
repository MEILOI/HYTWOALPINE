#!/bin/bash

export LANG=en_US.UTF-8

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
PLAIN="\033[0m"

red() { echo -e "\033[31m\033[01m$1\033[0m"; }
green() { echo -e "\033[32m\033[01m$1\033[0m"; }
yellow() { echo -e "\033[33m\033[01m$1\033[0m"; }

# 判断是否为 root 用户
if [[ $EUID -ne 0 ]]; then
    red "错误: 请以 root 用户或使用 sudo 运行脚本"
    yellow "当前用户: $(whoami) (UID: $EUID)"
    yellow "尝试: sudo $0 或 su - 后重新运行"
    exit 1
fi

# 检查并安装依赖
check_dependencies() {
    local core_deps="curl wget bash openssl"
    local missing_core_deps=""
    
    for dep in $core_deps; do
        if ! command -v $dep >/dev/null 2>&1; then
            missing_core_deps="$missing_core_deps $dep"
        fi
    done

    if [[ -n $missing_core_deps ]]; then
        yellow "以下核心依赖缺失：[$missing_core_deps]"
        if command -v apk >/dev/null 2>&1; then
            yellow "检测到 apk 包管理器，配置仓库并安装依赖..."
            local alpine_version=$(cat /etc/alpine-release 2>/dev/null | cut -d'.' -f1,2 || echo "3.21")
            local repo_file="/etc/apk/repositories"
            local main_repo="https://dl-cdn.alpinelinux.org/alpine/v${alpine_version}/main"
            local community_repo="https://dl-cdn.alpinelinux.org/alpine/v${alpine_version}/community"
            
            if ! grep -q "$main_repo" "$repo_file"; then
                echo "$main_repo" >> "$repo_file"
                yellow "已添加 main 仓库：$main_repo"
            fi
            if ! grep -q "$community_repo" "$repo_file"; then
                echo "$community_repo" >> "$repo_file"
                yellow "已添加 community 仓库：$community_repo"
            fi
            
            apk cache clean
            apk update || {
                red "apk update 失败，尝试更换镜像源："
                red "sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories"
                exit 1
            }
            
            apk add --no-cache $core_deps || {
                red "核心依赖 [$missing_core_deps] 安装失败"
                red "请手动运行：apk add --no-cache $core_deps"
                exit 1
            }
            green "核心依赖 [$core_deps] 安装成功"
        else
            red "未检测到 apk 包管理器，请手动安装依赖：$missing_core_deps"
            exit 1
        fi
    fi
}

# 获取服务器 IP
realip() {
    ip=$(curl -s4m8 ip.gs -k) || ip=$(curl -s6m8 ip.gs -k)
    if [[ -z $ip ]]; then
        red "无法获取服务器 IP，请检查网络连接"
        exit 1
    fi
}

# 必应自签证书
inst_cert() {
    if ! command -v openssl >/dev/null 2>&1; then
        red "openssl 未安装，请先安装 openssl"
        exit 1
    fi
    green "将使用必应自签证书作为 Hysteria 2 的节点证书"
    cert_path="/etc/hysteria/cert.crt"
    key_path="/etc/hysteria/private.key"
    mkdir -p /etc/hysteria
    openssl ecparam -genkey -name prime256v1 -out "$key_path"
    openssl req -new -x509 -days 36500 -key "$key_path" -out "$cert_path" -subj "/CN=www.bing.com"
    if [[ ! -f $cert_path || ! -f $key_path ]]; then
        red "证书生成失败，请检查 openssl 是否正常工作"
        exit 1
    fi
    chmod 644 "$cert_path" "$key_path"
    hy_domain="www.bing.com"
    domain="www.bing.com"
}

# Acme 自动证书
inst_acme() {
    green "将使用 Acme 脚本自动申请证书"
    if ! command -v curl >/dev/null 2>&1; then
        red "curl 未安装，请先安装 curl"
        exit 1
    fi
    read -rp "请输入您的域名（例如 example.com）：" domain
    [[ -z $domain ]] && red "域名不能为空！" && exit 1
    cert_path="/etc/hysteria/cert.crt"
    key_path="/etc/hysteria/private.key"
    mkdir -p /etc/hysteria
    curl -fsSL https://get.acme.sh | sh
    ~/.acme.sh/acme.sh --issue -d "$domain" --standalone || {
        red "Acme 证书申请失败，请检查域名或网络"
        exit 1
    }
    ~/.acme.sh/acme.sh --install-cert -d "$domain" \
        --cert-file "$cert_path" \
        --key-file "$key_path" || {
        red "证书安装失败，请检查 acme.sh"
        exit 1
    }
    chmod 644 "$cert_path" "$key_path"
    hy_domain="$domain"
}

# 自定义证书路径
inst_custom_cert() {
    green "将使用自定义证书路径"
    read -rp "请输入证书文件路径（例如 /path/to/cert.crt）：" cert_path
    read -rp "请输入私钥文件路径（例如 /path/to/private.key）：" key_path
    read -rp "请输入证书对应的域名（例如 example.com）：" domain
    [[ -z $cert_path || -z $key_path || -z $domain ]] && red "证书路径、私钥路径或域名不能为空！" && exit 1
    [[ ! -f $cert_path || ! -f $key_path ]] && red "证书或私钥文件不存在！" && exit 1
    mkdir -p /etc/hysteria
    cp "$cert_path" /etc/hysteria/cert.crt
    cp "$key_path" /etc/hysteria/private.key
    chmod 644 /etc/hysteria/cert.crt /etc/hysteria/private.key
    hy_domain="$domain"
}

# 选择证书
select_cert() {
    yellow "请选择证书类型："
    echo -e " ${GREEN}1.${PLAIN} 必应自签证书 （默认）"
    echo -e " ${GREEN}2.${PLAIN} Acme 脚本自动申请"
    echo -e " ${GREEN}3.${PLAIN} 自定义证书路径"
    read -rp "请输入选项 [1-3]: " cert_choice
    case $cert_choice in
        1|"") inst_cert ;;
        2) inst_acme ;;
        3) inst_custom_cert ;;
        *) red "无效选项，请选择 1-3！" && exit 1 ;;
    esac
}

# 设置单端口
inst_port() {
    read -rp "设置 Hysteria 2 端口 [1-65535]（回车则随机分配端口）：" port
    [[ -z $port ]] && port=$(shuf -i 2000-65535 -n 1)
    until [[ -z $(ss -tunlp 2>/dev/null | grep -w udp | awk '{print $5}' | sed 's/.*://g' | grep -w "$port") ]]; do
        if [[ -n $(ss -tunlp 2>/dev/null | grep -w udp | awk '{print $5}' | sed 's/.*://g' | grep -w "$port") ]]; then
            red "$port 端口已经被其他程序占用，请更换端口重试！"
            read -rp "设置 Hysteria 2 端口 [1-65535]（回车则随机分配端口）：" port
            [[ -z $port ]] && port=$(shuf -i 2000-65535 -n 1)
        fi
    done
    yellow "将在 Hysteria 2 节点使用的端口是：$port"
    yellow "NAT VPS 用户：请确保端口 $port 已由 VPS 提供商映射到公网"
    yellow "若未映射，请联系提供商开放 UDP 端口 $port"
}

# 安装 Hysteria
insthysteria() {
    realip
    select_cert
    inst_port
    green "NAT VPS 环境：跳过 iptables 防火墙配置"
    green "请确保端口 $port 已由 VPS 主机的防火墙或 NAT 规则开放"
    inst_pwd
    inst_site

    # 下载 Hysteria 2
    HYSTERIA_VERSION=$(curl -s https://api.github.com/repos/apernet/hysteria/releases/latest | grep tag_name | cut -d '"' -f 4)
    if [[ -z $HYSTERIA_VERSION ]]; then
        red "无法获取 Hysteria 最新版本，请检查网络连接"
        exit 1
    fi
    wget -O /usr/local/bin/hysteria https://github.com/apernet/hysteria/releases/download/${HYSTERIA_VERSION}/hysteria-linux-amd64
    chmod +x /usr/local/bin/hysteria
    if [[ ! -f "/usr/local/bin/hysteria" ]]; then
        red "Hysteria 2 安装失败，请检查网络或磁盘空间"
        exit 1
    fi
    green "Hysteria 2 安装成功！"

    # 设置服务端配置文件
    cat << EOF > /etc/hysteria/config.yaml
listen: :$port
tls:
  cert: $cert_path
  key: $key_path
quic:
  initStreamReceiveWindow: 8388608
  maxStreamReceiveWindow: 8388608
  initConnReceiveWindow: 16777216
  maxConnReceiveWindow: 16777216
auth:
  type: password
  password: $auth_pwd
masquerade:
  type: proxy
  proxy:
    url: https://$proxysite
    rewriteHost: true
EOF

    # 生成客户端配置文件
    if [[ -n $(echo $ip | grep ":") ]]; then
        last_ip="[$ip]"
    else
        last_ip=$ip
    fi
    mkdir -p /root/hy
    cat << EOF > /root/hy/hy-client.yaml
server: $last_ip:$port
auth: $auth_pwd
tls:
  sni: $hy_domain
  insecure: true
quic:
  initStreamReceiveWindow: 8388608
  maxStreamReceiveWindow: 8388608
  initConnReceiveWindow: 16777216
  maxConnReceiveWindow: 16777216
fastOpen: true
socks5:
  listen: 127.0.0.1:5080
EOF

    url="hysteria2://$auth_pwd@$last_ip:$port/?insecure=1&sni=$hy_domain#Misaka-Hysteria2"
    echo $url > /root/hy/url.txt

    # 启动 Hysteria 2
    nohup /usr/local/bin/hysteria server --config /etc/hysteria/config.yaml > /var/log/hysteria.log 2>&1 &
    echo $! > /run/hysteria.pid
    sleep 2
    if ps | grep -q "[h]ysteria.*server"; then
        green "Hysteria 2 服务启动成功"
    else
        red "Hysteria 2 服务启动失败，请检查 /var/log/hysteria.log"
        exit 1
    fi

    red "======================================================================================"
    green "Hysteria 2 代理服务安装完成"
    yellow "Hysteria 2 客户端 YAML 配置文件 hy-client.yaml 内容如下，并保存到 /root/hy/hy-client.yaml"
    red "$(cat /root/hy/hy-client.yaml)"
    yellow "Hysteria 2 节点分享链接如下，并保存到 /root/hy/url.txt"
    red "$(cat /root/hy/url.txt)"
    yellow "NAT VPS 用户：请确保端口 $port 已映射到公网，否则客户端无法连接"
}

# 设置密码
inst_pwd() {
    read -rp "设置 Hysteria 2 密码（回车跳过为随机字符）：" auth_pwd
    [[ -z $auth_pwd ]] && auth_pwd=$(date +%s%N | md5sum | cut -c 1-8)
    yellow "使用在 Hysteria 2 节点的密码为：$auth_pwd"
}

# 设置伪装网站
inst_site() {
    read -rp "请输入 Hysteria 2 的伪装网站地址 （去除https://） [回车默认 www.bing.com]：" proxysite
    [[ -z $proxysite ]] && proxysite="www.bing.com"
    yellow "使用在 Hysteria 2 节点的伪装网站为：$proxysite"
}

# 卸载 Hysteria
unsthysteria() {
    kill $(cat /run/hysteria.pid) >/dev/null 2>&1
    rm -f /run/hysteria.pid
    rm -rf /usr/local/bin/hysteria /etc/hysteria /root/hy
    green "Hysteria 2 已彻底卸载完成！"
    yellow "NAT VPS 用户：若需清理主机的端口映射，请联系 VPS 提供商"
}

# 启动 Hysteria
starthysteria() {
    nohup /usr/local/bin/hysteria server --config /etc/hysteria/config.yaml > /var/log/hysteria.log 2>&1 &
    echo $! > /run/hysteria.pid
    sleep 2
    if ps | grep -q "[h]ysteria.*server"; then
        green "Hysteria 2 服务已启动"
    else
        red "Hysteria 2 服务启动失败，请检查 /var/log/hysteria.log"
    fi
}

# 停止 Hysteria
stophysteria() {
    kill $(cat /run/hysteria.pid) >/dev/null 2>&1
    rm -f /run/hysteria.pid
    green "Hysteria 2 服务已停止"
}

# 开关 Hysteria
hysteriaswitch() {
    yellow "请选择你需要的操作："
    echo -e " ${GREEN}1.${PLAIN} 启动 Hysteria 2"
    echo -e " ${GREEN}2.${PLAIN} 关闭 Hysteria 2"
    echo -e " ${GREEN}3.${PLAIN} 重启 Hysteria 2"
    read -rp "请输入选项 [0-3]: " switchInput
 drowsiness continues:
    case $switchInput in
        1) starthysteria ;;
        2) stophysteria ;;
        3) stophysteria && starthysteria ;;
        *) exit 1 ;;
    esac
}

# 修改端口
changeport() {
    old_port=$(cat /etc/hysteria/config.yaml 2>/dev/null | grep "listen:" | awk '{print $2}' | cut -d':' -f2)
    read -rp "设置 Hysteria 2 端口 [1-65535]（回车则随机分配端口）：" port
    [[ -z $port ]] && port=$(shuf -i 2000-65535 -n 1)
    until [[ -z $(ss -tunlp 2>/dev/null | grep -w udp | awk '{print $5}' | sed 's/.*://g' | grep -w "$port") ]]; do
        if [[ -n $(ss -tunlp 2>/dev/null | grep -w udp | awk '{print $5}' | sed 's/.*://g' | grep -w "$port") ]]; then
            red "$port 端口已经被其他程序占用，请更换端口重试！"
            read -rp "设置 Hysteria 2 端口 [1-65535]（回车则随机分配端口）：" port
            [[ -z $port ]] && port=$(shuf -i 2000-65535 -n 1)
        fi
    done
    sed -i "s/listen: :$old_port/listen: :$port/" /etc/hysteria/config.yaml
    sed -i "s/server: .*:$old_port/server: $last_ip:$port/" /root/hy/hy-client.yaml
    sed -i "s/:$old_port/:$port/" /root/hy/url.txt
    stophysteria && starthysteria
    green "Hysteria 2 端口已修改为：$port"
    yellow "NAT VPS 用户：请联系 VPS 提供商，将端口 $port 映射到公网"
    yellow "请手动更新客户端配置文件以使用节点"
    showconf
}

# 修改密码
changepasswd() {
    oldpasswd=$(cat /etc/hysteria/config.yaml 2>/dev/null | grep password: | awk '{print $2}')
    read -rp "设置 Hysteria 2 密码（回车跳过为随机字符）：" passwd
    [[ -z $passwd ]] && passwd=$(date +%s%N | md5sum | cut -c 1-8)
    sed -i "s/password: $oldpasswd/password: $passwd/g" /etc/hysteria/config.yaml
    sed -i "s/auth: $oldpasswd/auth: $passwd/g" /root/hy/hy-client.yaml
    sed -i "s/hysteria2:\/\/$oldpasswd@/hysteria2:\/\/$passwd@/" /root/hy/url.txt
    stophysteria && starthysteria
    green "Hysteria 2 节点密码已成功修改为：$passwd"
    yellow "请手动更新客户端配置文件以使用节点"
    showconf
}

# 修改配置
changeconf() {
    green "Hysteria 2 配置变更选择如下:"
    echo -e " ${GREEN}1.${PLAIN} 修改端口"
    echo -e " ${GREEN}2.${PLAIN} 修改密码"
    read -rp "请选择操作 [1-2]：" confAnswer
    case $confAnswer in
        1) changeport ;;
        2) changepasswd ;;
        *) exit 1 ;;
    esac
}

# 显示配置
showconf() {
    yellow "Hysteria 2 客户端 YAML 配置文件 hy-client.yaml 内容如下，并保存到 /root/hy/hy-client.yaml"
    red "$(cat /root/hy/hy-client.yaml)"
    yellow "Hysteria 2 节点分享链接如下，并保存到 /root/hy/url.txt"
    red "$(cat /root/hy/url.txt)"
    yellow "NAT VPS 用户：请确保端口 $port 已由 VPS 提供商映射到公网"
}

# 更新内核
update_core() {
    HYSTERIA_VERSION=$(curl -s https://api.github.com/repos/apernet/hysteria/releases/latest | grep tag_name | cut -d '"' -f 4)
    if [[ -z $HYSTERIA_VERSION ]]; then
        red "无法获取 Hysteria 最新版本，请检查网络连接"
        exit 1
    fi
    wget -O /usr/local/bin/hysteria https://github.com/apernet/hysteria/releases/download/${HYSTERIA_VERSION}/hysteria-linux-amd64
    chmod +x /usr/local/bin/hysteria
    stophysteria && starthysteria
    green "Hysteria 2 内核已更新到最新版本"
}

# 主菜单
menu() {
    clear
    echo "#############################################################"
    echo -e "#                  ${RED}Hysteria 2 一键安装脚本${PLAIN}                  #"
    echo -e "# ${GREEN}原作者${PLAIN}: MisakaNo の 小破站                                #"
    echo -e "# ${GREEN}原博客${PLAIN}: https://blog.misaka.cyou                          #"
    echo -e "# ${GREEN}原GitHub 项目${PLAIN}: https://github.com/Misaka-blog            #"
    echo -e "# ${GREEN}移植作者${PLAIN}: TheX                                          #"
    echo -e "# ${GREEN}移植项目${PLAIN}: https://github.com/MEILOI/HYTWOALPINE         #"
    echo -e "# ${GREEN}移植版本${PLAIN}: v1.0.5                                       #"
    echo "#############################################################"
    echo ""
    echo -e " ${GREEN}1.${PLAIN} 安装 Hysteria 2"
    echo -e " ${GREEN}2.${PLAIN} ${RED}卸载 Hysteria 2${PLAIN}"
    echo " -------------"
    echo -e " ${GREEN}3.${PLAIN} 关闭、开启、重启 Hysteria 2"
    echo -e " ${GREEN}4.${PLAIN} 修改 Hysteria 2 配置"
    echo -e " ${GREEN}5.${PLAIN} 显示 Hysteria 2 配置文件"
    echo -e " ${GREEN}6.${PLAIN} 更新 Hysteria 2 内核"
    echo -e " ${GREEN}0.${PLAIN} 退出脚本"
    read -rp "请输入选项 [0-6]: " menuInput
    case $menuInput in
        1) insthysteria ;;
        2) unsthysteria ;;
        3) hysteriaswitch ;;
        4) changeconf ;;
        5) showconf ;;
        6) update_core ;;
        *) exit 1 ;;
    esac
}

check_dependencies
menu