#!/bin/sh
#需要$JBOSS_HOME/standalone的读和执行权限 chmod -R 755 $JBOSS_HOME/standalone
#BASE_PATH=$(cd "$(dirname "$0")";pwd)
BASE_PATH=$HOME/appServer
err() {
  echo $1
  exit 0
}

[ -z $JAVA_HOME ] && err "JAVA_HOME is requried"
[ -z $JBOSS_HOME ] && err "JBOSS_HOME is requried"
[ -d $BASE_PATH ] || mkdir $BASE_PATH
cd $BASE_PATH

[ $# -gt 0 ] || err "usage: sh install-jboss.sh <app-name>"

[ -d $1 ] && err "appServer $1 is already exists."

offset=$(ls|wc -l)

cp -r $JBOSS_HOME/standalone $1
mkdir $1/bin

(cat << EOF
#!/bin/sh
[ -z \$JBOSS_HOME ] && export JBOSS_HOME=$JBOSS_HOME
export JBOSS_BASE_DIR=$BASE_PATH/$1
export JBOSS_LOG_DIR=\$JBOSS_BASE_DIR/log
export JBOSS_CONFIG_DIR=\$JBOSS_BASE_DIR/configuration
export JBOSS_MODULEPATH=\$JBOSS_HOME/modules
export JAVA_OPTS="-Xms1024m -Xmx4096m -Djava.awt.headless=true -Dapp.name=$1 -Djava.net.preferIPv4Stack=true -Dfile.encoding=utf-8 -DconfPath=\$HOME/conf/mngApplication.properties -Dspring.config.location=\$HOME/conf/application.properties -DlogHome=\$HOME/logs -Djboss.socket.binding.port-offset=$offset -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=\$JBOSS_BASE_DIR -XX:ErrorFile=\$JBOSS_BASE_DIR/java_error_%p.log"


nohup \$JBOSS_HOME/bin/standalone.sh -b 0.0.0.0 > /dev/null 2>&1 &
EOF
) > $1/bin/startup.sh

(cat << EOF
#!/bin/bash
[ -z \$JBOSS_HOME ] && export JBOSS_HOME=$JBOSS_HOME
\$JBOSS_HOME/bin/jboss-cli.sh -c --controller=localhost:$(($offset+9990)) 'shutdown'

EOF
) > $1/bin/shutdown.sh

echo "APP_HOME: $BASE_PATH/$1"
echo "HTTP PORT: $((8080+$offset))"
echo "ADMIN HTTP PORT: $((9990+$offset))"
echo "ADMIN HTTPS PORT: $((9443+$offset))"
