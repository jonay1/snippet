#!/bin/sh
err() {
  echo $1
  exit 0
}
check() {
    fuser -s $1/tcp
    return $?
}

[ -z $REDIS_HOME ] && err "REDIS_HOME is requried"

start() {
  case $1 in
    "server"|"sentinel")
    check $2
    if [ $? -eq 1 ]; then
      [ -f $HOME/redis-conf/$2.conf ] || err "port is not right"
      $REDIS_HOME/src/redis-$1 $HOME/redis-conf/$2.conf
    else
      echo "port $2 alreay startup"
    fi
    ;;
    *)
    echo "usage: redis <start|stop|restart> <server|sentinel> <port>"
    ;;
  esac
 
}
stop() {
  case $1 in
    "server"|"sentinel")
    check $2
    if [ $? -eq 0 ]; then
      [ -f $HOME/redis-conf/$2.conf ] || err "port is not right"
      $REDIS_HOME/src/redis-cli -h 127.0.0.1 -p $2 shutdown
    else
      echo "port $2 alreay shutdown"
    fi
    ;;
    *)
    echo "usage: redis <start|stop|restart> <server|sentinel> <port>"
    ;;
  esac
}

case $1 in
  "start"|"stop")
  $1 $2 $3
  $1 successed!
  ;;
  "restart")
  stop $2 $3
  start $2 $3
  $1 successed!
  ;;
  *)
	echo "usage: redis <start|stop|restart> <server|sentinel> <port>"
  ;;
esac
