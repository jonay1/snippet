#!/bin/sh
#BASE_PATH=$(cd "$(dirname "$0")";pwd)
BASE_PATH=$HOME
err() {
  echo $1
  exit 0
}
cd $BASE_PATH
[ -d redis-conf ] || mkdir redis-conf
[ -d redis-log ] || mkdir redis-log
[ -z $REDIS_HOME ] && err "REDIS_HOME is requried" 
[ -f $redis-conf/$2 ] && err "port is allready used"

case $1 in
  "master")
  [ $# -gt 1 ] || { echo "err! such as: sh install.sh master 3679"; exit 0; }
  echo "installing master redis, port $2";
(cat << EOF
#当前redis端口定义：
port $2
#当前redis主机地址：
bind 0.0.0.0
#redis 守护进程设置：
daemonize yes
#保护模式：
protected-mode no
#redis日志：
logfile "$BASE_PATH/redis-log/$2.log"
EOF
) > redis-conf/$2.conf
  ;;
  "slave")
  [ $# -gt 3 ] || { echo "err! such as: sh install.sh slave 3680 127.0.0.1 3679"; exit 0; }
  echo "installing slave redis, port $2, slaveof $3:$4";
  (cat << EOF
#当前redis端口定义：
port $2
#当前redis主机地址：
bind 0.0.0.0
#redis 守护进程设置：
daemonize yes
#保护模式：
protected-mode no
#redis日志：
logfile "$BASE_PATH/redis-log/$2.log"
#设置主机
slaveof $3 $4
EOF
) > redis-conf/$2.conf
  ;;
  "sentinel")
  [ $# -gt 3 ] || { echo "err! such as: sh install.sh sentinel 23679 127.0.0.1 3679"; exit 0; }
  echo "install sentinel redis, port $2";
(cat << EOF
#当前redis端口定义：
port $2
#当前redis主机地址：
bind 0.0.0.0
#redis 守护进程设置：
daemonize yes
#保护模式：
protected-mode no
#redis日志：
logfile "$BASE_PATH/redis-log/$2.log"
#哨兵监控主机配置
sentinel monitor mymaster $3 $4 2
#哨兵链接失效时间(单位：毫秒)
sentinel down-after-milliseconds mymaster 30000
#redis失效时转移设置
sentinel parallel-syncs mymaster 1
#redis转移时间设置
sentinel failover-timeout mymaster 5000
EOF
) > redis-conf/$2.conf
  ;;
  *)
  [ $# -gt 1 ] || { echo "usage: sh install-redis.sh <master|slave|sentinel> <port> [master ip] [master port]"; exit 0; }
  ;;
esac

echo "config file : $BASE_PATH/redis-conf/$2.conf"
echo "log file    : $BASE_PATH/redis-log/$2.log"
echo "install finished."