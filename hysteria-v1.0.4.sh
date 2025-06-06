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
[[ $EUID -ne 0 ]] && red "注意: 请在 root 用户下运行脚本" && exit 1

# 检查并安装依赖
check_dependencies() {
    local core_deps="curl wget bash openssl iptables ip6tables"
    local optional_deps="qrencode"
    local missing_core_deps=""
    local missing_optional_deps=""
    
    # 检查核心依赖
    for dep in $core_deps; do
        if ! command -v $dep >/dev/null 2>&1; then
            missing_core_deps="$missing_core_deps $dep"
        fi
    done
    # 检查可选依赖
    for dep in $optional_deps; do
        if ! command -v $dep >/dev/null 2>&1; then
            missing_optional_deps="$missing_optional_deps $dep"
        fi
    done

    if [[ -n $missing_core_deps || -n $missing_optional_deps ]]; then
        yellow "以下依赖缺失：核心依赖 [$missing_core_deps] 可选依赖 [$missing_optional_deps]"
        if command -v apk >/dev/null 2>&1; then
            yellow "检测到 apk 包管理器，配置仓库并安装依赖..."
            # 动态获取 Alpine 版本
            local alpine_version=$(cat /etc/alpine-release 2>/dev/null | cut -d'.' -f1,2 || echo "3.21")
            local repo_file="/etc/apk/repositories"
            local main_repo="https://dl-cdn.alpinelinux.org/alpine/v${alpine_version}/main"
            local community_repo="https://dl-cdn.alpinelinux.org/alpine/v${alpine_version}/community"
            
            # 确保 main 和 community 仓库存在
            if ! grep -q "$main_repo" "$repo_file"; then
                echo "$main_repo" >> "$repo_file"
                yellow "已添加 main 仓库：$main_repo"
            fi
            if ! grep -q "$community_repo" "$repo_file"; then
                echo "$community_repo" >> "$repo_file"
                yellow "已添加 community 仓库：$community_repo"
            fi
            
            # 清理缓存并更新仓库
            apk cache clean
            apk update || {
                red "apk update 失败，可能是网络或镜像源问题"
                red "请尝试更换镜像源（如 mirrors.tuna.tsinghua.edu.cn）："
                red "  sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories"
                red "  apk update && apk add --no-cache $core_deps $optional_deps"
                exit 1
            }
            
            # 安装核心依赖
            if [[ -n $missing_core_deps ]]; then
                apk add --no-cache $core_deps || {
                    red "核心依赖 [$missing_core_deps] 安装失败"
                    red "请手动运行：apk add --no-cache $core_deps"
                    exit 1
                }
                green "核心依赖 [$core_deps] 安装成功"
            fi
            
            # 安装可选依赖（qrencode）
            if [[ -n $missing_optional_deps ]]; then
                apk add --no-cache $optional_deps || {
                    yellow "可选依赖 [$missing_optional_deps] 安装失败，二维码生成功能可能不可用"
                    yellow "请手动运行：apk add --no-cache $optional_deps"
                    yellow "或更换镜像源：sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories"
                }
            fi
        elif command -v apt >/dev/null 2>&1; then
            yellow "检测到 apt 包管理器，尝试安装缺失依赖..."
            apt update && apt install -y $missing_core_deps $missing_optional_deps || {
                red "apt 安装依赖失败，请手动运行：apt update && apt install -y $missing_core_deps $missing_optional_deps"
                exit 1
            }
        elif command -v yum >/dev/null 2>&1; then
            yellow "检测到 yum 包管理器，尝试安装缺失依赖..."
            yum install -y $missing_core_deps $missing_optional_deps || {
                red "yum 安装依赖失败，请手动运行：yum install -y $missing_core_deps $missing_optional_deps"
                exit 1
            }
        else
            red "未检测到包管理器，请手动安装以下依赖："
            red "核心依赖：$missing_core_deps"
            red "可选依赖：$missing_optional_deps"
            red "例如，在 Alpine Linux 上运行：apk add --no-cache $core_deps $optional_deps"
            exit 1
        fi
    fi
}

check_dependencies

realip() {
    ip=$(curl -s4m8 ip.gs -k) || ip=$(curl -s6m8 ip.gs -k)
    if [[ -z $ip ]]; then
        red "无法获取服务器 IP，请检查网络连接"
        exit 1
    fi
}

inst_cert() {
    if ! command -v openssl >/dev/null 2>&1; then
        red "openssl 未安装，请先安装 openssl"
        exit 1
    fi
    green "将使用必应自签证书作为 Hysteria 2 的节点证书"
    cert_path="/etc/hysteria/cert.crt"
    key_path="/etc/hysteria/private.key"
    mkdir -p /etc/hysteria
    openssl ecparam -genkey -name prime256v1 -out /etc/hysteria/private.key
    openssl req -new -x509 -days 36500 -key /etc/hysteria/private.key -out /etc/hysteria/cert.crt -subj "/CN=www.bing.com"
    if [[ ! -f $cert_path || ! -f $key_path ]]; then
        red "证书生成失败，请检查 openssl 是否正常工作"
        exit 1
    fi
    chmod 644 /etc/hysteria/cert.crt /etc/hysteria/private.key
    hy_domain="www.bing.com"
    domain="www.bing.com"
}

inst_port() {
    read -p "设置 Hysteria 2 端口 [1-65535]（回车则随机分配端口）：" port
    [[ -z $port ]] && port=$(shuf -i 2000-65535 -n 1)
    until [[ -z $(ss -tunlp 2>/dev/null | grep -w udp | awk '{print $5}' | sed 's/.*://g' | grep -w "$port") ]]; do
        if [[ -n $(ss -tunlp 2>/dev/null | grep -w udp | awk '{print $5}' | sed 's/.*://g' | grep -w "$port") ]]; then
            echo -e "${RED} $port ${PLAIN} 端口已经被其他程序占用，请更换端口重试！"
            read -p "设置 Hysteria 2 端口 [1-65535]（回车则随机分配端口）：" port
            [[ -z $port ]] && port=$(shuf -i 2000-65535 -n 1)
        fi
    done
    yellow "将在 Hysteria 2 节点使用的端口是：$port"

    # 防火墙放行端口
    if command -v iptables >/dev/null 2>&1; then
        iptables -I INPUT -p udp --dport $port -j ACCEPT
        ip6tables -I INPUT -p udp --dport $port -j ACCEPT 2>/dev/null || true
        iptables-save >/etc/iptables.rules 2>/dev/null || true
        ip6tables-save >/etc/ip6tables.rules 2>/dev/null || true
    else
        yellow "未检测到 iptables，需手动配置防火墙放行 UDP 端口 $port"
        yellow "请在 VPS 控制面板或主机防火墙中放行 UDP 端口 $port"
    fi
}

inst_pwd() {
    read -p "设置 Hysteria 2 密码（回车跳过为随机字符）：" auth_pwd
    [[ -z $auth_pwd ]] && auth_pwd=$(date +%s%N | md5sum | cut -c 1-8)
    yellow "使用在 Hysteria 2 节点的密码为：$auth_pwd"
}

inst_site() {
    read -rp "请输入 Hysteria 2 的伪装网站地址 （去除https://） [回车默认 www.bing.com]：" proxysite
    [[ -z $proxysite ]] && proxysite="www.bing.com"
    yellow "使用在 Hysteria 2 节点的伪装网站为：$proxysite"
}

insthysteria() {
    realip

    # 下载 Hysteria 2 二进制 (x86_64)
    HYSTERIA_VERSION=$(curl -s https://api.github.com/repos/apernet/hysteria/releases/latest | grep tag_name | cut -d '"' -f 4)
    if [[ -z $HYSTERIA_VERSION ]]; then
        red "无法获取 Hysteria 最新版本，请检查网络连接"
        exit 1
    fi
    wget -O /usr/local/bin/hysteria https://github.com/apernet/hysteria/releases/download/${HYSTERIA_VERSION}/hysteria-linux-amd64
    chmod +x /usr/local/bin/hysteria

    if [[ -f "/usr/local/bin/hysteria" ]]; then
        green "Hysteria 2 安装成功！"
    else
        red "Hysteria 2 安装失败，请检查网络或磁盘空间"
        exit 1
    fi

    # 询问用户配置
    inst_cert
    inst_port
    inst_pwd
    inst_site

    # 设置 Hysteria 配置文件
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
    last_port=$port
    if [[ -n $(echo $ip | grep ":") ]]; then
        last_ip="[$ip]"
    else
        last_ip=$ip
    fi

    mkdir -p /root/hy
    cat << EOF > /root/hy/hy-client.yaml
server: $last_ip:$last_port

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

transport:
  udp:
    hopInterval: 30s 
EOF

    url="hysteria2://$auth_pwd@$last_ip:$last_port/?insecure=1&sni=$hy_domain#Misaka-Hysteria2"
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
}

unsthysteria() {
    kill $(cat /run/hysteria.pid) >/dev/null 2>&1
    rm -f /run/hysteria.pid
    rm -rf /usr/local/bin/hysteria /etc/hysteria /root/hy
    if command -v iptables >/dev/null 2>&1; then
        iptables -D INPUT -p udp --dport $port -j ACCEPT >/dev/null 2>&1
        ip6tables -D INPUT -p udp --dport $port -j ACCEPT >/dev/null 2>&1
        iptables-save >/etc/iptables.rules 2>/dev/null || true
        ip6tables-save >/etc/ip6tables.rules 2>/dev/null || true
    fi
    green "Hysteria 2 已彻底卸载完成！"
}

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

stophysteria() {
    kill $(cat /run/hysteria.pid) >/dev/null 2>&1
    rm -f /run/hysteria.pid
    green "Hysteria 2 服务已停止"
}

hysteriaswitch() {
    yellow "请选择你需要的操作："
    echo -e " ${GREEN}1.${PLAIN} 启动 Hysteria 2"
    echo -e " ${GREEN}2.${PLAIN} 关闭 Hysteria 2"
    echo -e " ${GREEN}3.${PLAIN} 重启 Hysteria 2"
    read -rp "请输入选项 [0-3]: " switchInput
    case $switchInput in
        1) starthysteria ;;
        2) stophysteria ;;
        3) stophysteria && starthysteria ;;
        *) exit 1 ;;
    esac
}

changeport() {
    oldport=$(cat /etc/hysteria/config.yaml 2>/dev/null | sed -n 1p | awk '{print $2}' | awk -F ":" '{print $2}')
    read -p "设置 Hysteria 2 端口[1-65535]（回车则随机分配端口）：" port
    [[ -z $port ]] && port=$(shuf -i 2000-65535 -n 1)
    until [[ -z $(ss -tunlp 2>/dev/null | grep -w udp | awk '{print $5}' | sed 's/.*://g' | grep -w "$port") ]]; do
        if [[ -n $(ss -tunlp 2>/dev/null | grep -w udp | awk '{print $5}' | sed 's/.*://g' | grep -w "$port") ]]; then
            echo -e "${RED} $port ${PLAIN} 端口已经被其他程序占用，请更换端口重试！"
            read -p "设置 Hysteria 2 端口 [1-65535]（回车则随机分配端口）：" port
            [[ -z $port ]] && port=$(shuf -i 2000-65535 -n 1)
        fi
    done
    sed -i "1s#$oldport#$port#g" /etc/hysteria/config.yaml
    sed -i "1s#$oldport#$port#g" /root/hy/hy-client.yaml
    if command -v iptables >/dev/null 2>&1; then
        iptables -D INPUT -p udp --dport $oldport -j ACCEPT >/dev/null 2>&1
        ip6tables -D INPUT -p udp --dport $oldport -j ACCEPT >/dev/null 2>&1
        iptables -I INPUT -p udp --dport $port -j ACCEPT
        ip6tables -I INPUT -p udp --dport $port -j ACCEPT 2>/dev/null || true
        iptables-save >/etc/iptables.rules 2>/dev/null || true
        ip6tables-save >/etc/ip6tables.rules 2>/dev/null || true
    else
        yellow "未检测到 iptables，需手动放行新端口 $port"
    fi
    stophysteria && starthysteria
    green "Hysteria 2 端口已成功修改为：$port"
    yellow "请手动更新客户端配置文件以使用节点"
    showconf
}

changepasswd() {
    oldpasswd=$(cat /etc/hysteria/config.yaml 2>/dev/null | grep password: | awk '{print $2}')
    read -p "设置 Hysteria 2 密码（回车跳过为随机字符）：" passwd
    [[ -z $passwd ]] && passwd=$(date +%s%N | md5sum | cut -c 1-8)
    sed -i "s/password: $oldpasswd/password: $passwd/g" /etc/hysteria/config.yaml
    sed -i "s/auth: $oldpasswd/auth: $passwd/g" /root/hy/hy-client.yaml
    stophysteria && starthysteria
    green "Hysteria 2 节点密码已成功修改为：$passwd"
    yellow "请手动更新客户端配置文件以使用节点"
    showconf
}

changeconf() {
    green "Hysteria 2 配置变更选择如下:"
    echo -e " ${GREEN}1.${PLAIN} 修改端口"
    echo -e " ${GREEN}2.${PLAIN} 修改密码"
    read -p " 请选择操作 [1-2]：" confAnswer
    case $confAnswer in
        1) changeport ;;
        2) changepasswd ;;
        *) exit 1 ;;
    esac
}

showconf() {
    yellow "Hysteria 2 客户端 YAML 配置文件 hy-client.yaml 内容如下，并保存到 /root/hy/hy-client.yaml"
    red "$(cat /root/hy/hy-client.yaml)"
    yellow "Hysteria 2 节点分享链接如下，并保存到 /root/hy/url.txt"
    red "$(cat /root/hy/url.txt)"
}

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

menu() {
    clear
    echo "#############################################################"
    echo -e "#                  ${RED}Hysteria 2 一键安装脚本${PLAIN}                  #"
    echo -e "# ${GREEN}原作者${PLAIN}: MisakaNo の 小破站                                #"
    echo -e "# ${GREEN}原博客${PLAIN}: https://blog.misaka.cyou                          #"
    echo -e "# ${GREEN}原GitHub 项目${PLAIN}: https://github.com/Misaka-blog            #"
    echo -e "# ${GREEN}移植作者${PLAIN}: TheX                                          #"
    echo -e "# ${GREEN}移植项目${PLAIN}: https://github.com/MEILOI/HYTWOALPINE         #"
    echo -e "# ${GREEN}移植版本${PLAIN}: v1.0.4                                       #"
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

menu
