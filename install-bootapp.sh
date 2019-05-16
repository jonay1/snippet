#!/bin/bash
#在当前目录
BASE_PATH=$(cd "$(dirname "$0")";pwd)
err() {
  echo $*
  exit 1
}

[ -z $JAVA_HOME ] && err "JAVA_HOME is requried"
[ $# -gt 1 ] || err "usage: sh install-bootapp.sh <app-name> <http port>"

APP_NAME=$1
HTTP_PORT=$2
[ -e $APP_NAME ] && err "app $APP_NAME is already exists."

APP_HOME=$BASE_PATH/$APP_NAME
mkdir -p $APP_HOME/{libs,logs,bin,conf}


(cat << EOF
#!/bin/bash

APP_NAME=$APP_NAME
APP_HOME=\$(cd "\$(dirname "\$0")";cd ..;pwd)
LOG_DIR=\$APP_HOME/logs

JAVA_OPTS="\$JAVA_OPTS -Dserver.port=$HTTP_PORT \\
                      -Dspring.config.location=\$APP_HOME/conf/application.properties \\
                      -Dfile.encoding=utf-8 -Dapp.name=\$APP_NAME \\
                      -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=\$LOG_DIR -XX:ErrorFile=\$LOG_DIR/java_error_%p.log"

export CLASSPATH=\$CLASSPATH:\$APP_HOME/conf:\$APP_HOME/libs/*

checkStart(){
    lsof -i :$HTTP_PORT > /dev/null 2>&1
    return \$?
}

checkStart
if [ \$? -eq 0 ]; then
    echo "\$APP_NAME is running! Start aborted."
    exit 0
fi

echo "\$APP_NAME begin to start..."

SYS_MAIN_CLASS=org.springframework.boot.loader.JarLauncher
nohup \$JAVA_HOME/bin/java -cp \$CLASSPATH \$JAVA_OPTS \$SYS_MAIN_CLASS >> \$LOG_DIR/server.log 2>&1 &

PID=\$!
tput sc
for i in {0..30}; 
do
  tput rc
  tput ed
  checkStart
  if [ \$? -eq 0 ]; then
    echo -n "\$APP_NAME is started in \$i s! pid is: \$PID"
    echo ""
    exit 0
  else
    echo -n "\$APP_NAME is starting \$i s"
  fi
  sleep 1; 
done
echo ""
echo "timeout(30s)!!! Please check log: \$LOG_DIR/server.log!"
EOF
) > $APP_HOME/bin/startup.sh

(cat << EOF
#!/bin/bash

APP_NAME=$APP_NAME
APP_HOME=\$(cd "\$(dirname "\$0")";cd ..;pwd)
LOG_DIR=\$APP_HOME/logs

PID=\`ps -ef | grep app.name=\$APP_NAME | grep -v grep | awk '{print \$2}'\`

if [ -z "\$PID" ]; then
    echo "\$APP_NAME isn't running! Stop aborted."
    exit 0
fi

echo "\$APP_NAME begin to stop..."

kill \$PID

tput sc
for i in {0..30}; 
do
  tput rc
  tput ed
  PID=\`ps -ef | grep app.name=\$APP_NAME | grep -v grep | awk '{print \$2}'\`
  if [ -z "\$PID" ]; then
    echo -n "\$APP_NAME stoped."
    echo ""
    exit 0
  else
    echo -n "\$APP_NAME is stopping \${i} s"
  fi
  sleep 1; 
done

echo ""
echo "timeout(30s)!!! Please check log: \$LOG_DIR/server.log!"
#force quit
kill -9 \$PID
echo "\$APP_NAME was killed!"
EOF
) > $APP_HOME/bin/shutdown.sh

chmod u+x $APP_HOME/bin/*.sh

echo "APP_HOME: $APP_HOME" >> $APP_HOME/README
echo "HTTP PORT: $HTTP_PORT" >> $APP_HOME/README
echo "CONF PATH: \$APP_HOME/conf" >> $APP_HOME/README

cat  $APP_HOME/README