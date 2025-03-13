
```bash
如果[$(id-u)！="0"]；则
#!/bin/bash
#
# Dante SOCKS5服务器自动安装
# --作者：Lozy

set -e  # 任何命令失败立即退出

# 检查root权限
if [ "$(id -u)" != "0" ]; then
  echo "错误：必须使用root权限运行此脚本"
  exit 1
fi

REQUEST_SERVER="https://raw.github.com/Lozy/danted/master"
SCRIPT_SERVER="https://public.sockd.info"
SYSTEM_RECOGNIZE=""

[ "$1" = "--no-github" ] && REQUEST_SERVER=${SCRIPT_SERVER}

# 识别操作系统
if [ -f /etc/os-release ]; then
  OS_NAME=$(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)
  case $OS_NAME in
    *Debian*)  SYSTEM_RECOGNIZE="debian" ;;
    *Ubuntu*)  SYSTEM_RECOGNIZE="ubuntu" ;;
    *CentOS*|*Rocky*|*Alma*) SYSTEM_RECOGNIZE="centos" ;;
    *Fedora*)  SYSTEM_RECOGNIZE="fedora" ;;
    *openSUSE*|*SUSE*) SYSTEM_RECOGNIZE="opensuse" ;;
    *) echo "不支持的操作系统: $OS_NAME"; exit 1 ;;
  esac
else
  echo "无法识别操作系统"
  exit 1
fi

# 安装依赖
case $SYSTEM_RECOGNIZE in
  debian|ubuntu)
    apt-get update
    apt-get install -y wget unzip gcc make libpam0g-dev
    ;;
  centos|fedora)
    yum install -y wget unzip gcc make pam-devel
    ;;
  opensuse)
    zypper install -y wget unzip gcc make pam-devel
    ;;
esac

# 下载预编译包
dante_version="1.4.3"
package_url="${REQUEST_SERVER}/dante-${dante_version}-${SYSTEM_RECOGNIZE}-linux.zip"
if ! wget --no-check-certificate "$package_url"; then
  echo "下载失败，尝试源码编译..."
  # 添加源码编译逻辑
  wget --no-check-certificate https://github.com/Lozy/danted/archive/master.zip
  unzip master.zip
  cd danted-master
  ./configure --prefix=/usr --sysconfdir=/etc
  make && make install
else
  unzip dante-${dante_version}-${SYSTEM_RECOGNIZE}-linux.zip
  dpkg -i dante-server*.deb || rpm -ivh dante-server*.rpm
fi

# 配置服务
cat > /etc/danted.conf <<EOF
logoutput: syslog
user.privileged: root
user.unprivileged: nobody
internal: 0.0.0.0 port = 1080
external: eth0
method: username none
client pass {
  from: 0.0.0.0/0 to: 0.0.0.0/0
}
pass {
  from: 0.0.0.0/0 to: 0.0.0.0/0
  command: connect
  method: none
}
EOF

# 启动服务
systemctl enable danted
systemctl start danted

echo "安装完成！端口：1080"
```

---
