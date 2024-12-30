#!/bin/bash

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
PLAIN='\033[0m'

# 获取终端宽度并生成分割线
get_separator() {
    # 获取终端宽度
    width=$(tput cols)
    # 生成分割线
    printf '%*s\n' "$width" '' | tr ' ' '-'
}

# Docker安装
install_docker() {
    if command -v docker >/dev/null 2>&1; then
        echo -e "${GREEN}Docker已安装${PLAIN}"
        return
    fi
    
    echo -e "${YELLOW}正在安装Docker...${PLAIN}"
    
    if command -v apt >/dev/null 2>&1; then
        apt update && apt install -y docker.io
    elif command -v yum >/dev/null 2>&1; then
        yum install -y docker
    else
        echo -e "${RED}不支持的系统类型${PLAIN}"
        return 1
    fi
    
    systemctl enable docker
    systemctl start docker
    
    echo -e "${GREEN}Docker安装完成${PLAIN}"
}

# Docker容器管理
docker_container_manage() {
    if ! command -v docker &>/dev/null; then
        echo -e "${RED}Docker未安装${PLAIN}"
        return 1
    fi

    while true; do
        clear
        echo -e "${CYAN}Docker容器管理${PLAIN}"
        echo -e "${YELLOW}$(get_separator)${PLAIN}"
        
        # 表头
        printf "${CYAN}%-15s %-20s %-25s %-20s${PLAIN}\n" "ID" "名称" "状态" "端口"
        echo -e "${YELLOW}$(get_separator)${PLAIN}"
        
        # 获取容器列表并格式化输出
        docker ps -a --format "{{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}" | while IFS=$'\t' read -r id name status ports; do
            # 处理状态信息
            if [[ $status == *"Up"* ]]; then
                # 处理运行状态
                runtime=$(echo "$status" | grep -oP 'Up \K.*?(?= ?\(|$)')
                # 优化时间显示
                if [[ $runtime == *"seconds"* ]]; then
                    runtime=$(echo "$runtime" | sed 's/seconds/秒/')
                elif [[ $runtime == *"minutes"* ]]; then
                    runtime=$(echo "$runtime" | sed 's/minutes/分钟/')
                elif [[ $runtime == *"hours"* ]]; then
                    runtime=$(echo "$runtime" | sed 's/hours/小时/')
                elif [[ $runtime == *"days"* ]]; then
                    runtime=$(echo "$runtime" | sed 's/days/天/')
                elif [[ $runtime == *"weeks"* ]]; then
                    runtime=$(echo "$runtime" | sed 's/weeks/周/')
                elif [[ $runtime == *"months"* ]]; then
                    runtime=$(echo "$runtime" | sed 's/months/月/')
                fi
                status="运行 ${runtime}"
            else
                # 处理退出状态
                exit_code=$(echo "$status" | grep -oP 'Exited \(\K[^)]*')
                exit_time=$(echo "$status" | grep -oP '\)[[:space:]]\K.*?ago')
                if [[ $exit_time == *"seconds"* ]]; then
                    exit_time=$(echo "$exit_time" | sed 's/seconds/秒/')
                elif [[ $exit_time == *"minutes"* ]]; then
                    exit_time=$(echo "$exit_time" | sed 's/minutes/分钟/')
                elif [[ $exit_time == *"hours"* ]]; then
                    exit_time=$(echo "$exit_time" | sed 's/hours/小时/')
                elif [[ $exit_time == *"days"* ]]; then
                    exit_time=$(echo "$exit_time" | sed 's/days/天/')
                fi
                status="已停止 ${exit_time}前"
            fi
            
            # 如果状态太长，进行截断
            if [ ${#status} -gt 25 ]; then
                status="${status:0:22}..."
            fi
            
            # 处理端口信息
            if [ -z "$ports" ]; then
                ports="-"
            else
                # 处理所有端口映射格式
                ports=$(echo "$ports" | sed -E '
                    s/0\.0\.0\.0://g;      # 移除 0.0.0.0:
                    s/\[\:\:\]://g;         # 移除 [::]:
                    s/:::*//g;              # 移除 :::
                    s/\/tcp//g;             # 移除 /tcp
                    s/\/udp//g;             # 移除 /udp
                    s/->/ ► /g;             # 替换 -> 为 ►
                    s/[[:space:]]+/ /g      # 压缩多余空格
                ' | tr ',' '\n' | sort -u | head -n1)

                [ -z "$ports" ] && ports="-"
            fi
            
            # 截断ID只显示前12位
            id="${id:0:12}"
            
            # 如果名称太长，进行截断
            if [ ${#name} -gt 20 ]; then
                name="${name:0:17}..."
            fi
            
            # 输出格式化的行
            printf "%-15s %-20s %-25s %-20s\n" "$id" "$name" "$status" "$ports"
        done
        
        echo -e "${YELLOW}$(get_separator)${PLAIN}"
        echo "1. 创建容器"
        echo "2. 启动容器"
        echo "3. 停止容器" 
        echo "4. 重启容器"
        echo "5. 删除容器"
        echo "6. 进入容器"
        echo "0. 返回"
        echo -e "${YELLOW}$(get_separator)${PLAIN}"
        
        read -p "请选择: " choice
        case "$choice" in
            1)
                read -p "请输入创建命令: " command
                eval $command
                ;;
            2)
                read -p "容器名称或ID: " container
                docker start $container
                ;;
            3)  
                read -p "容器名称或ID: " container
                docker stop $container
                ;;
            4)
                read -p "容器名称或ID: " container
                docker restart $container
                ;;
            5)
                read -p "容器名称或ID: " container
                docker rm -f $container
                ;;
            6)
                read -p "容器名称或ID: " container
                docker exec -it $container /bin/bash
                ;;
            0)
                break
                ;;
            *)
                echo "无效选择"
                ;;
        esac
        read -n 1 -s -r -p "按任意键继续..."
    done
}

# Docker镜像管理
docker_image_manage() {
    if ! command -v docker &>/dev/null; then
        echo -e "${RED}Docker未安装${PLAIN}"
        return 1
    fi

    while true; do
        clear
        echo -e "${CYAN}Docker镜像管理${PLAIN}"
        echo -e "${YELLOW}$(get_separator)${PLAIN}"
        
        # 使用自定义格式显示镜像列表
        docker images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}" | while read -r line; do
            if [[ $line == *"REPOSITORY"* ]]; then
                printf "${CYAN}%-50s %-20s${PLAIN}\n" "镜像" "大小"
                echo -e "${YELLOW}$(get_separator)${PLAIN}"
            else
                printf "%-50s %-20s\n" $line
            fi
        done
        
        echo -e "${YELLOW}$(get_separator)${PLAIN}"
        echo "1. 拉取镜像"
        echo "2. 删除镜像"
        echo "0. 返回"
        echo -e "${YELLOW}$(get_separator)${PLAIN}"
        
        read -p "请选择: " choice
        case "$choice" in
            1)
                read -p "镜像名称: " image
                docker pull $image
                ;;
            2)
                read -p "镜像ID或名称: " image
                docker rmi $image
                ;;
            0)
                break
                ;;
            *)
                echo "无效选择"
                ;;
        esac
        read -n 1 -s -r -p "按任意键继续..."
    done
}

# Docker网络管理
docker_network_manage() {
    if ! command -v docker &>/dev/null; then
        echo -e "${RED}Docker未安装${PLAIN}"
        return 1
    fi

    while true; do
        clear
        echo -e "${CYAN}Docker网络管理${PLAIN}"
        echo -e "${YELLOW}$(get_separator)${PLAIN}"
        
        # 使用自定义格式显示网络列表
        docker network ls --format "table {{.Name}}\t{{.Driver}}" | while read -r line; do
            if [[ $line == *"NAME"* ]]; then
                printf "${CYAN}%-30s %-20s${PLAIN}\n" "名称" "驱动"
                echo -e "${YELLOW}$(get_separator)${PLAIN}"
            else
                printf "%-30s %-20s\n" $line
            fi
        done
        
        echo -e "${YELLOW}$(get_separator)${PLAIN}"
        echo "1. 创建网络"
        echo "2. 删除网络"
        echo "3. 查看网络详情"
        echo "4. 连接容器到网络"
        echo "5. 断开容器与网络的连接"
        echo "0. 返回"
        echo -e "${YELLOW}$(get_separator)${PLAIN}"
        
        read -p "请选择: " choice
        case "$choice" in
            1)
                read -p "网络名称: " network
                docker network create $network
                ;;
            2)
                read -p "网络名称: " network
                docker network rm $network
                ;;
            3)
                read -p "网络名称: " network
                docker network inspect $network
                ;;
            4)
                read -p "容器名称: " container
                read -p "网络名称: " network
                docker network connect $network $container
                ;;
            5)
                read -p "容器名称: " container
                read -p "网络名称: " network
                docker network disconnect $network $container
                ;;
            0)
                break
                ;;
            *)
                echo "无效选择"
                ;;
        esac
        read -n 1 -s -r -p "按任意键继续..."
    done
}

# Docker数据卷管理
docker_volume_manage() {
    if ! command -v docker &>/dev/null; then
        echo -e "${RED}Docker未安装${PLAIN}"
        return 1
    fi

    while true; do
        clear
        echo -e "${CYAN}Docker数据卷管理${PLAIN}"
        echo -e "${YELLOW}$(get_separator)${PLAIN}"
        
        # 使用自定义格式显示数据卷列表
        docker volume ls --format "table {{.Name}}\t{{.Driver}}" | while read -r line; do
            if [[ $line == *"VOLUME"* ]]; then
                printf "${CYAN}%-40s %-20s${PLAIN}\n" "名称" "驱动"
                echo -e "${YELLOW}$(get_separator)${PLAIN}"
            else
                printf "%-40s %-20s\n" $line
            fi
        done
        
        echo -e "${YELLOW}$(get_separator)${PLAIN}"
        echo "1. 创建数据卷"
        echo "2. 删除数据卷"
        echo "3. 查看数据卷详情"
        echo "4. 清理无用数据卷"
        echo "0. 返回"
        echo -e "${YELLOW}$(get_separator)${PLAIN}"
        
        read -p "请选择: " choice
        case "$choice" in
            1)
                read -p "数据卷名称: " volume
                docker volume create $volume
                ;;
            2)
                read -p "数据卷名称: " volume
                docker volume rm $volume
                ;;
            3)
                read -p "数据卷名称: " volume
                docker volume inspect $volume
                ;;
            4)
                docker volume prune -f
                ;;
            0)
                break
                ;;
            *)
                echo "无效选择"
                ;;
        esac
        read -n 1 -s -r -p "按任意键继续..."
    done
}

# Nginx管理
nginx_manage() {
    while true; do
        clear
        if ! command -v nginx &>/dev/null; then
            echo -e "${YELLOW}Nginx未安装，是否安装？(y/n)${PLAIN}"
            read -p "请选择: " choice
            case "$choice" in
                [Yy])
                    if command -v apt &>/dev/null; then
                        apt update && apt install -y nginx
                    elif command -v yum &>/dev/null; then
                        yum install -y nginx
                    fi
                    ;;
                *)
                    return 0
                    ;;
            esac
        fi
        
        echo -e "${CYAN}Nginx管理${PLAIN}"
        echo -e "${YELLOW}$(get_separator)${PLAIN}"
        # 获取状态并转换为中文
        status=$(systemctl is-active nginx 2>/dev/null || echo '未运行')
        case "$status" in
            active)
                status="运行中"
                ;;
            inactive)
                status="已停止"
                ;;
            failed)
                status="运行失败"
                ;;
            unknown)
                status="未知状态"
                ;;
            *)
                status="未运行"
                ;;
        esac
        echo -e "状态: ${status}"
        echo -e "${YELLOW}$(get_separator)${PLAIN}"
        echo "1. 设置重定向"
        echo "2. 配置反向代理"
        echo "3. 申请SSL证书"
        echo "4. 部署静态网站"
        echo "5. 更换站点域名"
        echo "6. 删除站点域名"
        echo "7. 启动Nginx"
        echo "8. 停止Nginx"
        echo "9. 重启Nginx"
        echo "10. 重载配置"
        echo "11. 卸载Nginx"
        echo "0. 返回"
        echo -e "${YELLOW}$(get_separator)${PLAIN}"
        
        read -p "请选择: " choice
        case "$choice" in
            1)
                read -p "源域名: " source_domain
                read -p "目标域名: " target_domain
                cat > /etc/nginx/conf.d/${source_domain}.conf << EOF
server {
    server_name ${source_domain};
    return 301 \$scheme://${target_domain}\$request_uri;
    listen 80;
}
EOF
                nginx -t && systemctl reload nginx
                ;;
            2)
                read -p "域名: " domain
                read -p "后端地址和端口: " backend
                cat > /etc/nginx/conf.d/${domain}.conf << EOF
server {
    server_name ${domain};
    location / {
        proxy_pass http://${backend};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    listen 80;
}
EOF
                nginx -t && systemctl reload nginx
                ;;
            3)
                read -p "域名: " domain
                if ! command -v certbot >/dev/null 2>&1; then
                    apt update && apt install -y certbot python3-certbot-nginx
                fi
                certbot --nginx -d ${domain} --non-interactive --agree-tos --email admin@${domain}
                ;;
            4)
                read -p "域名: " domain
                read -p "网站目录: " webroot
                mkdir -p ${webroot}
                cat > /etc/nginx/conf.d/${domain}.conf << EOF
server {
    server_name ${domain};
    root ${webroot};
    index index.html;
    location / {
        try_files \$uri \$uri/ =404;
    }
    listen 80;
}
EOF
                nginx -t && systemctl reload nginx
                ;;
            5)
                read -p "原域名: " old_domain
                read -p "新域名: " new_domain
                mv "/etc/nginx/conf.d/${old_domain}.conf" "/etc/nginx/conf.d/${new_domain}.conf"
                sed -i "s/${old_domain}/${new_domain}/g" "/etc/nginx/conf.d/${new_domain}.conf"
                if [ -d "/etc/letsencrypt/live/${old_domain}" ]; then
                    certbot --nginx -d ${new_domain} --non-interactive --agree-tos --email admin@${new_domain}
                fi
                nginx -t && systemctl reload nginx
                ;;
            6)
                read -p "域名: " domain
                rm -f "/etc/nginx/conf.d/${domain}.conf"
                if [ -d "/etc/letsencrypt/live/${domain}" ]; then
                    certbot delete --cert-name ${domain} --non-interactive
                fi
                nginx -t && systemctl reload nginx
                ;;
            7)
                systemctl start nginx
                ;;
            8)
                systemctl stop nginx
                ;;
            9)
                systemctl restart nginx
                ;;
            10)
                nginx -t && systemctl reload nginx
                ;;
            11)
                if command -v apt &>/dev/null; then
                    apt remove --purge -y nginx nginx-common nginx-full
                    rm -rf /etc/nginx
                    rm -rf /var/log/nginx
                elif command -v yum &>/dev/null; then
                    yum remove -y nginx
                    rm -rf /etc/nginx
                    rm -rf /var/log/nginx
                fi
                ;;
            0)
                break
                ;;
            *)
                echo "无效选择"
                ;;
        esac
        read -n 1 -s -r -p "按任意键继续..."
    done
}

# 主菜单
main_menu() {
    while true; do
        clear
        echo -e "${CYAN}Docker+Nginx管理面板${PLAIN}"
        echo -e "${YELLOW}$(get_separator)${PLAIN}"
        echo "1. Docker管理"
        echo "2. Nginx管理"
        echo "0. 退出"
        echo -e "${YELLOW}$(get_separator)${PLAIN}"
        
        read -p "请选择: " choice
        case "$choice" in
            1)
                docker_menu
                ;;
            2)
                nginx_manage
                ;;
            0)
                exit 0
                ;;
            *)
                echo "无效选择"
                ;;
        esac
    done
}

# Docker管理菜单
docker_menu() {
    while true; do
        clear
        echo -e "${CYAN}Docker管理${PLAIN}"
        echo -e "${YELLOW}$(get_separator)${PLAIN}"
        echo "1. 安装Docker"
        echo "2. 容器管理"
        echo "3. 镜像管理"
        echo "4. 网络管理"
        echo "5. 数据卷管理"
        echo "0. 返回"
        echo -e "${YELLOW}$(get_separator)${PLAIN}"
        
        read -p "请选择: " choice
        case "$choice" in
            1)
                install_docker
                ;;
            2)
                docker_container_manage
                ;;
            3)
                docker_image_manage
                ;;
            4)
                docker_network_manage
                ;;
            5)
                docker_volume_manage
                ;;
            0)
                break
                ;;
            *)
                echo "无效选择"
                ;;
        esac
        read -n 1 -s -r -p "按任意键继续..."
    done
}

# 检查root权限
[ "$(id -u)" != "0" ] && { echo -e "${RED}请使用root权限运行${PLAIN}"; exit 1; }

# 创建快捷命令
cp -f "$(readlink -f "$0")" /usr/local/bin/yaxp.sh
chmod +x /usr/local/bin/yaxp.sh
ln -sf /usr/local/bin/yaxp.sh /usr/local/bin/y

# 启动主菜单
main_menu 