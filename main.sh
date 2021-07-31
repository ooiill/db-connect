#!/usr/bin/env bash

current=$(cd `dirname $0`; pwd)
source ${current}/library.sh

# 配置文件
iniFile="${current}/config.ini"

# 读取所有的server配置标题
_list=`items ${iniFile}`
list=`keys ${iniFile}`
menu "${list}" "All of servers for db connect."
number=$?

# 转数组
_list=($_list)
item=${_list[${number}]}

# 获取变量
ssh_host=`ini ${iniFile} ${item} ssh-host`
ssh_port=`ini ${iniFile} ${item} ssh-port`
ssh_user=`ini ${iniFile} ${item} ssh-user`
ssh_pass=`ini ${iniFile} ${item} ssh-pass`
server_host=`ini ${iniFile} ${item} server-host`
server_port=`ini ${iniFile} ${item} server-port`
local_host=`ini ${iniFile} ${item} local-host`
local_port=`ini ${iniFile} ${item} local-port`
command=`ini ${iniFile} ${item} command`
backup=`ini ${iniFile} ${item} backup`

tag=${1}
sshCommand="echo ssh unconfigured"

if [ -n "${ssh_user}" ]; then

    # 杀死原有进程
    pid=`ps -ef | grep -v grep | grep ${local_port} | awk '{print $2}'`
    if [ -n "${pid}" ]; then
        echo ${pid} | xargs kill -9
    fi

    # ssh隧道代理
    sshCommand="sshpass -p ${ssh_pass} ssh -4 -p ${ssh_port} -N -f -L ${local_host}:${local_port}:${server_host}:${server_port} ${ssh_user}@${ssh_host} -o ExitOnForwardFailure=yes > /dev/null 2>&1"
fi

if [ -n "${command}" ]; then

    # mycli client
    if [ "${tag}" == "mycli" ]; then
        command=${command//mysql/mycli}
    fi

    ${sshCommand}

    # tag handler
    if [ "${tag}" == "debug" ]; then
        color 30 "${sshCommand}" "\n" "\n"
        command=${command//\!/\\\!}
        color 32 "${command}" "" "\n"
    elif [ "${tag}" == "debug-dump" ]; then
        color 30 "${sshCommand}" "\n" "\n"
        command=${command//mysql/mysqldump --column-statistics=0}
        command=${command//\!/\\\!}
        command=${command//-D/}
        command="${command} > ${backup}"
        color 32 "${command}" "" "\n"
    elif [ "${tag}" == "ssh-only" ]; then
        color 32 "ssh build done." "" "\n"
    else
        ${command}
    fi
fi

