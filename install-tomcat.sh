#!/bin/bash
#在当前目录
BASE_PATH=$(cd "$(dirname "$0")";pwd)
err() {
  echo $*
  exit 1
}


#[ -z $JAVA_HOME ] && read -p "JAVA_HOME路径:" JAVA_HOME
#[ -z $JAVA_HOME ] && err '缺少环境变量JAVA_HOME'
[ -z "$TOMCAT_HOME" ] && read -p "TOMCAT目录:" TOMCAT_HOME
[ ! -d "$TOMCAT_HOME" ] && err 'TOMCAT目录不正确'
CATALINA_HOME=$TOMCAT_HOME
#[ $# -gt 3 ] || err "usage: sh install-tomcat.sh <app-name> <http port> <shutdown port> <ajp port>"

APP_NAME=$1
HTTP_PORT=$2
SHUTDOWN_PORT=$3
AJP_PORT=$4

[ -z "$APP_NAME" ] && read -p "应用名称(默认 app):" APP_NAME && APP_NAME=${APP_NAME:-app}
[ -e $APP_NAME ] && err "该名称已存在"
[ -z "$HTTP_PORT" ] && read -p "HTTP端口(默认 8080):" HTTP_PORT && HTTP_PORT=${HTTP_PORT:-8080}
[ -z "$SHUTDOWN_PORT" ] && read -p "SHUTDOWN端口(默认 8005):" SHUTDOWN_PORT && SHUTDOWN_PORT=${SHUTDOWN_PORT:-8005} 
[ -z "$AJP_PORT" ] && read -p "AJP端口(默认 8009):" AJP_PORT && AJP_PORT=${AJP_PORT:-8009}

CATALINA_BASE=$BASE_PATH/$APP_NAME

mkdir -p $CATALINA_BASE/{webapps,temp,work,logs,bin}
cp -r $CATALINA_HOME/conf $CATALINA_BASE/conf

P1=
case "`uname`" in
CYGWIN*) cygwin=true;;
OS400*) os400=true;;
Darwin*) P1=".bak";;
esac
sed -i $P1 's/port=.*shutdown/port="'$SHUTDOWN_PORT'" shutdown/' $CATALINA_BASE/conf/server.xml 
sed -i $P1 's/port=.*protocol="HTTP/port="'$HTTP_PORT'" protocol="HTTP/' $CATALINA_BASE/conf/server.xml
sed -i $P1 's/port=.*protocol="AJP/port="'$AJP_PORT'" protocol="AJP/' $CATALINA_BASE/conf/server.xml
#  sed -i $P1 's#</Host>#<Context docBase="'$CATALINA_BASE'/../../'$APP_NAME'.war" path="/'$APP_NAME'" reloadable="false" /></Host>#' $CATALINA_BASE/conf/server.xml

(cat << EOF
CLASSPATH=\$CATALINA_BASE/conf
EOF
) > $CATALINA_BASE/bin/setenv.sh

(cat << EOF
#!/bin/bash
export CATALINA_HOME=$CATALINA_HOME
export CATALINA_BASE=\$(cd "\$(dirname "\$0")";cd ..;pwd)
export CATALINA_OPTS="\$CATALINA_OPTS \\
                      -Dapp.name=${APP_NAME}_ \\
                      -DlogHome=\$CATALINA_BASE/logs/ \\
                      -Dspring.config.location=\$CATALINA_BASE/conf/application.properties \\
                      -Dfile.encoding=UTF-8 -Djava.awt.headless=true \\
                      -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=\$CATALINA_BASE -XX:ErrorFile=\$CATALINA_BASE/java_error_%p.log"

checkStart(){
    fuser -s $SHUTDOWN_PORT/tcp > /dev/null 2>&1
    return \$?
}

PID=\`ps -ef|grep app.name=${APP_NAME}_ |grep -v grep|awk '{print \$2}'\`
if [ -n "\$PID" ]; then
    echo "$APP_NAME is running! Start aborted."
    exit 0
fi

work_dir=\$CATALINA_BASE/work/Catalina/localhost/$APP_NAME
[ -d \$work_dir ] && rm -rf \$work_dir

echo "$APP_NAME begin to start..."

\$CATALINA_HOME/bin/startup.sh

tput sc
for i in {0..90}; 
do
  tput rc
  tput ed
  checkStart
  if [ \$? -eq 0 ]; then
    echo -n "$APP_NAME is started in \$i s!"
    echo ""
    exit 0
  else
    echo -n "$APP_NAME is starting \$i s"
  fi
  sleep 1; 
done
echo ""
echo "timeout(90s)!!! Please check log: \$CATALINA_BASE/logs/catalina.out!"

#tail -f \$CATALINA_BASE/logs/catalina.out | sed -e "/Server startup in/q"
# checkStart
# if [ \$? -eq 0 ]; then
#   echo "$APP_NAME is started success!"
# else
#   echo "$APP_NAME is started failed!"
# fi

EOF
) > $CATALINA_BASE/bin/startup.sh

(cat << EOF
#!/bin/bash
export CATALINA_HOME=$CATALINA_HOME
export CATALINA_BASE=\$(cd "\$(dirname "\$0")";cd ..;pwd)

PID=\`ps -ef|grep app.name=${APP_NAME}_ |grep -v grep|awk '{print \$2}'\`

if [ -z "\$PID" ]; then
    echo "$APP_NAME isn't running! Stop aborted."
    exit 0
fi

echo "$APP_NAME begin to stop..."
\$CATALINA_HOME/bin/shutdown.sh

tput sc
for i in {0..60}; 
do
  tput rc
  tput ed
  PID=\`ps -ef|grep app.name=${APP_NAME}_ |grep -v grep|awk '{print \$2}'\`
  if [ -z "\$PID" ]; then
    echo -n "$APP_NAME stoped in \$i s."
    echo ""
    exit 0
  else
    echo -n "$APP_NAME is stopping \$i s"
  fi
  sleep 1; 
done

# echo ""
# echo "timeout(60s)!!! Please check log: \$CATALINA_BASE/logs/catalina.out!"

#force quit
kill \$PID
echo "$APP_NAME was killed!"
EOF
) > $CATALINA_BASE/bin/shutdown.sh

chmod u+x $CATALINA_BASE/bin/*.sh

echo "TOMCAT目录: $CATALINA_HOME" >> $CATALINA_BASE/README
echo "应用目录:   $CATALINA_BASE" >> $CATALINA_BASE/README
echo "HTTP端口:   $HTTP_PORT" >> $CATALINA_BASE/README
echo "SHUTDOWN端口:$SHUTDOWN_PORT" >> $CATALINA_BASE/README
echo "AJP端口:    $AJP_PORT" >> $CATALINA_BASE/README


cat  $CATALINA_BASE/README

