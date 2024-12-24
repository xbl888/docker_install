#!/bin/bash
# auther: Jason Yin
# blog: https://www.cnblogs.com/yinzhengjie


# 加载操作系统的变量，主要是ID变量。
. /etc/os-release

# DOCKER_VERSION=26.1.1
DOCKER_VERSION=20.10.24
# DOCKER_COMPOSE_VERSION=2.27.0
DOCKER_COMPOSE_VERSION=2.23.0
FILENAME=docker-${DOCKER_VERSION}.tgz
DOCKER_COMPOSE_FILE=docker-compose-v${DOCKER_COMPOSE_VERSION}
URL=https://download.docker.com/linux/static/stable/x86_64
DOCKER_COMPOSE_URL=https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-linux-x86_64
DOWNLOAD=./download
BASE_DIR=/oldboyedu/softwares
OS_VERSION=$ID




# 判断是否下载了docker-compose
function prepare(){
   # 判断是否下载docker-compose文件
   if [ ! -f ${DOWNLOAD}/${DOCKER_COMPOSE_FILE} ]; then
      wget -T 3  -t 2 ${DOCKER_COMPOSE_URL} -O ${DOWNLOAD}/${DOCKER_COMPOSE_FILE}
   fi
   
   if [ $? != 0 ];then
     rm -f ${DOWNLOAD}/${DOCKER_COMPOSE_FILE}
     echo "不好意思，由于网络波动原因，无法下载${DOCKER_COMPOSE_URL}软件包，程序已退出!请稍后再试......"
     exit 100
   fi

   # 给脚本添加执行权限
   chmod +x ${DOWNLOAD}/${DOCKER_COMPOSE_FILE}
}


# 定义安装函数
function InstallDocker(){

	if [ $OS_VERSION == "centos" ];then
	  [ -f /usr/bin/wget ] || yum -y install wget
          rpm -qa |grep bash-completion || yum -y install bash-completion
	fi

	if [ $OS_VERSION == "ubuntu" ];then
	  [ -f /usr/bin/wget ] || apt -y install wget
	fi

    # 判断文件是否存在，若不存在则下载软件包
    if [ ! -f ${DOWNLOAD}/${FILENAME} ]; then
       wget ${URL}/${FILENAME} -O ${DOWNLOAD}/${FILENAME}
    fi
    
    # 判断安装路径是否存在
    if [ ! -d ${BASE_DIR} ]; then
      install -d ${BASE_DIR}
    fi
    
    # 解压软件包到安装目录
    tar xf ${DOWNLOAD}/${FILENAME} -C ${BASE_DIR}
 
    # 安装docker-compose
    prepare
    cp $DOWNLOAD/${DOCKER_COMPOSE_FILE} ${BASE_DIR}/docker/docker-compose
   
    # 创建软连接
    ln -svf ${BASE_DIR}/docker/* /usr/bin/
    
    # 自动补全功能
    cp $DOWNLOAD/docker /usr/share/bash-completion/completions/docker
    source /usr/share/bash-completion/completions/docker
    
    # 配置镜像加速
    install -d /etc/docker
    cp $DOWNLOAD/daemon.json /etc/docker/daemon.json
    
    # 开机自启动脚本
    cp download/docker.service /usr/lib/systemd/system/docker.service
    systemctl daemon-reload
    systemctl enable --now docker
    docker version
    docker-compose version
    tput setaf 3
    echo "安装成功,欢迎使用薛博立的二进制docker安装脚本，欢迎下次使用!"
    tput setaf 2
}


# 卸载docker
function UninstallDocker(){
  # 停止docker服务
  systemctl disable --now docker

  # 卸载启动脚本
  rm -f /usr/lib/systemd/system/docker.service

  # 清空程序目录
  rm -rf ${BASE_DIR}/docker

  # 清空数据目录
  rm -rf /var/lib/{docker,containerd} 

  # 清除符号链接
  rm -f /usr/bin/{containerd,containerd-shim,containerd-shim-runc-v2,ctr,docker,dockerd,docker-init,docker-proxy,runc}

  # 使得终端变粉色
  tput setaf 5
  echo "卸载成功,欢迎再次使用薛博立的二进制docker安装脚本哟~"
  tput setaf 7
}


# 程序的入口函数
function main(){
   # 判断传递的参数
   case $1 in
     install|i)
      InstallDocker
      ;;
      remove|r)
      UninstallDocker
      ;;
     *)
       echo "Invalid parameter, Usage: $0 install|remove"
       ;;
   esac
}

# 向入口函数传参
main $1 
