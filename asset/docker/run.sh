#!/bin/bash

# start mqnamesrv service
nohup $ROCKETMQ_HOME/bin/mqnamesrv > /dev/null 2>&1 &
echo "启动：mqnamesrv"

# start mqbroker service
# 添加broker对外地址
echo "brokerIP1 = $HOST_IP" >> $ROCKETMQ_HOME/conf/broker.conf
nohup $ROCKETMQ_HOME/bin/mqbroker -n $NAMESRV_ADDR -c $ROCKETMQ_HOME/conf/broker.conf > /dev/null 2>&1 &
echo "启动：mqbroker"

# start console service
cd $CONSOLE_HOME
nohup  java -jar rocketmq-dashboard.jar > /dev/null 2>&1 &
echo "启动：console"
echo ""
echo "Console帐号以及密码"
echo "帐号：admin   密码：admin"
echo "帐号：normal  密码：normal"
echo ''
echo ' _____            _        _   __  __  ____  '
echo '|  __ \          | |      | | |  \/  |/ __ \ '
echo '| |__) |___   ___| | _____| |_| \  / | |  | |'
echo '|  _  // _ \ / __| |/ / _ \ __| |\/| | |  | |'
echo '| | \ \ (_) | (__|   <  __/ |_| |  | | |__| |'
echo '|_|  \_\___/ \___|_|\_\___|\__|_|  |_|\___\_\'
echo ''
echo ""

# foreground process
tail -f /dev/null
