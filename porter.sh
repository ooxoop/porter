#!/usr/bin/env bash

Folder="/usr/local/porter"

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Green_font_prefix}[注意]${Font_color_suffix}"

check_sys(){
	if [[ -f /etc/redhat-release ]]; then
		release="centos"
	elif cat /etc/issue | grep -q -E -i "debian"; then
		release="debian"
	elif cat /etc/issue | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
	elif cat /proc/version | grep -q -E -i "debian"; then
		release="debian"
	elif cat /proc/version | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
	fi
	bit=`uname -m`
}

check_pid(){
	PID=`ps -ef | grep "porter" | grep -v "grep" | grep -v "porter.sh"| grep -v "init.d" | grep -v "service" | awk '{print $2}'`
}

get_ip(){
	ip=$(wget -qO- -t1 -T2 ipinfo.io/ip)
	if [[ -z "${ip}" ]]; then
		ip=$(wget -qO- -t1 -T2 api.ip.sb/ip)
		if [[ -z "${ip}" ]]; then
			ip=$(wget -qO- -t1 -T2 members.3322.org/dyndns/getip)
			if [[ -z "${ip}" ]]; then
				ip="VPS_IP"
			fi
		fi
	fi
}

check_new_ver(){
	echo -e "${Info} 请输入 porter 版本号，格式如：[ 1.34.0 ]，获取地址：[ https://github.com/ooxoop/porter/releases ]"
	read -e -p "默认回车自动获取最新版本号:" porter_new_ver
	if [[ -z ${porter_new_ver} ]]; then
		porter_new_ver=$(wget --no-check-certificate -qO- https://api.github.com/repos/ooxoop/porter/releases | grep -o '"tag_name": ".*"' |head -n 1| sed 's/"//g;s/v//g' | sed 's/tag_name: //g')
		if [[ -z ${porter_new_ver} ]]; then
			echo -e "${Error} porter 最新版本获取失败，请手动获取最新版本号[ https://github.com/ooxoop/porter/releases ]"
			read -e -p "请输入版本号 [ 格式如 1.34.0 ] :" porter_new_ver
			[[ -z "${porter_new_ver}" ]] && echo "取消..." && exit 1
		else
			echo -e "${Info} 检测到 porter 最新版本为 [ ${porter_new_ver} ]"
		fi
	else
		echo -e "${Info} 即将准备下载 porter 版本为 [ ${porter_new_ver} ]"
	fi
}

check_install_status(){
	[[ ! -e "/usr/bin/porter" ]] && echo -e "${Error} porter 没有安装，请检查 !" && exit 1
	[[ ! -e "/root/.porter/porter.conf" ]] && echo -e "${Error} porter 配置文件不存在，请检查 !" && [[ $1 != "un" ]] && exit 1
}

download_porter(){
	cd "/usr/local"
	if [[ ${bit} == "x86_64" ]]; then
		bit="amd64"
	elif [[ ${bit} == "i386" || ${bit} == "i686" ]]; then
		bit="386"
	else
		bit="arm64"
	fi
	mkdir "${Folder}" && cd "${Folder}"
	wget -N --no-check-certificate "https://github.com/ooxoop/porter/releases/download/v${porter_new_ver}/porter"
	chmod +x porter
	cp porter /usr/bin/porter
	mkdir /root/.porter
	wget --no-check-certificate https://raw.githubusercontent.com/ooxoop/porter/master/config.json -O /root/.porter/porter.conf
	echo -e "${Info} porter 主程序安装完毕！开始配置服务文件..."
}

service_porter(){
	if [[ ${release} = "centos" ]]; then
		if ! wget --no-check-certificate https://raw.githubusercontent.com/ooxoop/porter/master/porter_centos.service -O /etc/init.d/porter; then
			echo -e "${Error} porter服务 管理脚本下载失败 !" && exit 1
		fi
		chmod +x /etc/init.d/porter
		chkconfig --add porter
		chkconfig porter on
	else
		if ! wget --no-check-certificate https://raw.githubusercontent.com/ooxoop/porter/master/porter_debian.service -O /etc/init.d/porter; then
			echo -e "${Error} porter服务 管理脚本下载失败 !" && exit 1
		fi
		chmod +x /etc/init.d/porter
		update-rc.d -f porter defaults
	fi
	echo -e "${Info} porter服务 管理脚本安装完毕 !"
}


Install_porter(){
	check_sys
	check_new_ver
	download_porter
	service_porter
	echo -e "porter 已安装完成！请重新运行脚本进行配置~"
}

Remove_porter(){
	Stop_porter
	rm -rf "$Folder" && rm -rf /root/.porter && rm -rf /etc/init.d/porter
	echo -e "${Info} gost 已卸载完成！"
}

Start_porter(){
	check_install_status
	check_pid
	[[ ! -z ${PID} ]] && echo -e "${Error} porter 正在运行，请检查 !" && exit 1
	/etc/init.d/porter start
	View_config
}

Stop_porter(){
	check_install_status
	check_pid
	[[ -z ${PID} ]] && echo -e "${Error} porter 没有运行，请检查 !" && exit 1
	/etc/init.d/porter stop
}

Restart_porter(){
	check_install_status
	check_pid
	[[ ! -z ${PID} ]] && /etc/init.d/porter stop
	/etc/init.d/porter start
	View_config
}


echo && echo -e " porter 一键安装管理脚本beta ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
 -- ooxoop | lajiblog.com --

${Green_font_prefix} 1.${Font_color_suffix} 安装 porter
${Green_font_prefix} 2.${Font_color_suffix} 卸载 porter
————————————
${Green_font_prefix} 3.${Font_color_suffix} 启动 porter
${Green_font_prefix} 4.${Font_color_suffix} 停止 porter
${Green_font_prefix} 5.${Font_color_suffix} 重启 porter
————————————
${Green_font_prefix} 6.${Font_color_suffix} 查看 当前配置
${Green_font_prefix} 7.${Font_color_suffix} 打开 配置文件
${Green_font_prefix} 8.${Font_color_suffix} 查看 日志文件
————————————" && echo
if [[ -e "/usr/bin/porter" ]]; then
	check_pid
	if [[ ! -z "${PID}" ]]; then
		echo -e " 当前状态: ${Green_font_prefix}已安装${Font_color_suffix} 并 ${Green_font_prefix}已启动${Font_color_suffix}"
	else
		echo -e " 当前状态: ${Green_font_prefix}已安装${Font_color_suffix} 但 ${Red_font_prefix}未启动${Font_color_suffix}"
	fi
else
	echo -e " 当前状态: ${Red_font_prefix}未安装${Font_color_suffix}"
fi
echo
read -e -p " 请输入数字 [0-10]:" num
case "$num" in
	1)
	Install_porter
	;;
	2)
	Remove_porter
	;;
	3)
	Start_porter
	;;
	4)
	Stop_porter
	;;
	5)
	Restart_porter
	;;
	6)
	View_config
	;;
	7)
	vi /root/.porter/porter.conf
	Restart_porter
	;;
	8)
	tail -n 50 /root/.porter/porter.log
	;;
	*)
	echo "请输入正确数字 [0-10]"
	;;
esac




