#!/bin/sh
#在当前目录
BASE_PATH=$(cd "$(dirname "$0")";pwd)
err() {
  echo $*
  exit 1
}

[ -z $JAVA_HOME ] && err "JAVA_HOME is requried"
[ -z $CATALINA_HOME ] && err "CATALINA_HOME is requried"


[ $# -gt 3 ] || err "usage: sh install-tomcat.sh <app-name> <http port> <shutdown port> <ajp port>"

APP_NAME=$1
HTTP_PORT=$2
SHUTDOWN_PORT=$3
AJP_PORT=$4
CATALINA_BASE=$BASE_PATH/$APP_NAME
[ -e $APP_NAME ] && err "app $1 is already exists."

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
#!/bin/sh
[ -z "\$CATALINA_HOME" ] && export CATALINA_HOME=$CATALINA_HOME
[ -z "\$CATALINA_BASE" ] && export CATALINA_BASE=$CATALINA_BASE
export CATALINA_OPTS="\$CATALINA_OPTS \
                      -Dapp.name=$APP_NAME \
                      -DconfPath=$CATALINA_BASE/application.properties \
                      -DlogHome=$CATALINA_BASE/logs/ \
                      -Dfile.encoding=UTF-8 -Djava.awt.headless=true \
                      -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=\$CATALINA_BASE -XX:ErrorFile=\$CATALINA_BASE/java_error_%p.log"
export CLASSPATH=\$CLASSPATH:\$HOME/conf/:\$CATALINA_HOME/lib/*:\$CATALINA_HOME/bin/*


checkStart(){
    lsof -i :$SHUTDOWN_PORT > /dev/null 2>&1
    return \$?
}

checkStart
if [ \$? -eq 0 ]; then
    echo "$APP_NAME is running! Start aborted."
    exit 1
fi

work_dir=\$CATALINA_BASE/work/Catalina/localhost/$APP_NAME
[ -d \$work_dir ] && rm -rf \$work_dir

echo "$APP_NAME begin to start..."

\$CATALINA_HOME/bin/startup.sh

#check
loopcount=0
echo -n "$APP_NAME is starting"
while [ \$loopcount -lt 60 ];do
    checkStart
    if [ \$? -eq 0 ]; then
        echo "OK!"
        exit 0
    else
        echo -n "."
        sleep 1
        loopcount=`expr \$loopcount + 1`
    fi
done

echo "timeout(60s)!!! Please check log: catalina.out!"
EOF
) > $CATALINA_BASE/bin/startup.sh

(cat << EOF
#!/bin/sh
[ -z "\$CATALINA_HOME" ] && export CATALINA_HOME=$CATALINA_HOME
[ -z "\$CATALINA_BASE" ] && export CATALINA_BASE=$CATALINA_BASE

checkStart(){
    lsof -i :$SHUTDOWN_PORT > /dev/null 2>&1
    return \$?
}

checkStart


if [ \$? -ne 0 ]; then
    echo "$APP_NAME isn't running! Stop aborted."
    exit 0
fi

echo "$APP_NAME begin to stop..."
\$CATALINA_HOME/bin/shutdown.sh

#check
loopcount=0
echo -n "$APP_NAME is stopping"
while [ \$loopcount -lt 90 ];do
    checkStart
    if [ \$? -ne 0 ]; then
        echo "OK!"
        echo "$APP_NAME stoped."
        exit 0
    else
        echo -n "."
        sleep 1
        loopcount=`expr \$loopcount + 1`
    fi
done

echo "timeout(90s)!!! Please check log: catalina.out!"

#force quit
fuser -s -k $HTTP_PORT/tcp
echo "$APP_NAME was killed!"
EOF
) > $CATALINA_BASE/bin/shutdown.sh


echo "CATALINA_HOME: $CATALINA_HOME" >> $CATALINA_BASE/README
echo "CATALINA_BASE: $CATALINA_BASE" >> $CATALINA_BASE/README
echo "HTTP PORT: $HTTP_PORT" >> $CATALINA_BASE/README
echo "SHUTDOWN PORT: $SHUTDOWN_PORT" >> $CATALINA_BASE/README
echo "AJP PORT: $AJP_PORT" >> $CATALINA_BASE/README


cat  $CATALINA_BASE/README

