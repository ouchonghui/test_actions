FROM alpine:3.19 AS ROCKETMQ_DASHBOARD_BUILD

LABEL maintainer="chongh.ou <ochhgz@163.com>"

ENV MAVEN_HOME="/home/maven/apache-maven-3.8.6"

ARG ROCKETMQ_DASHBOARD_VERSION=1.0.0

RUN set -x \
    && apk add --no-cache openjdk17 curl gcompat libstdc++ nodejs npm  \
    && mkdir -p /home/console/rocketmq-dashboard && mkdir -p /home/maven \
    && curl -SL https://archive.apache.org/dist/rocketmq/rocketmq-dashboard/${ROCKETMQ_DASHBOARD_VERSION}/rocketmq-dashboard-${ROCKETMQ_DASHBOARD_VERSION}-source-release.zip -o /home/console/rocketmq-dashboard.zip \
    && unzip /home/console/rocketmq-dashboard.zip -d /home/console/rocketmq-dashboard/tmp_unzip/ \
    && TOP_DIR=$(ls /home/console/rocketmq-dashboard/tmp_unzip) && mv "/home/console/rocketmq-dashboard/tmp_unzip/$TOP_DIR"/* /home/console/rocketmq-dashboard/

COPY ./asset/console/pom.xml /home/console/rocketmq-dashboard/

RUN curl -SL https://archive.apache.org/dist/maven/maven-3/3.8.6/binaries/apache-maven-3.8.6-bin.zip -o /home/maven/maven.zip \
    && unzip /home/maven/maven.zip -d /home/maven/ \
    && export PATH=$PATH:$MAVEN_HOME/bin \
    && cd /home/console/rocketmq-dashboard \
    && mvn clean package -Dmaven.test.skip=true \
    && mv /home/console/rocketmq-dashboard/target/rocketmq-dashboard-${ROCKETMQ_DASHBOARD_VERSION}.jar /home/console/rocketmq-dashboard.jar

FROM alpine:3.19

LABEL maintainer="chongh.ou <ochhgz@163.com>"

# 环境变量
ENV BASE_DIR="/root" \
    ROCKETMQ_HOME="/root/rocketmq" \
    CONSOLE_HOME="/root/console" \
    TIME_ZONE="Asia/Shanghai" \
    # namesrv jvm参数
    NAMESRV_XMS=512m \
    NAMESRV_XMX=512m \
    NAMESRV_XMN=256m \
    # broker jvm参数
    BROKER_XMS=512m \
    BROKER_XMX=512m \
    BROKER_XMN=256m \
    BROKER_MDM=512m \
    # console 参数
    NAMESRV_ADDR="localhost:9876" \
    # 宿主机ip地址: 需要提供给broker.conf使用，以将broker注册地址修改为外网地址，否则默认注册的是docker内部ip地址，外部应用程序无法访问到broker
    HOST_IP="127.0.0.1"

ARG ROCKETMQ_VERSION=${ROCKETMQ_VERSION}

WORKDIR ${BASE_DIR}

COPY --from=ROCKETMQ_DASHBOARD_BUILD /home/console/rocketmq-dashboard.jar ${CONSOLE_HOME}/rocketmq-dashboard.jar

COPY ["./asset", "/tmp/asset/"]

RUN set -x \
    && apk add --no-cache openjdk17 curl bash tzdata \
    && cp /usr/share/zoneinfo/$TIME_ZONE /etc/localtime && echo $TIME_ZONE > /etc/timezone \
    # 下载rocketmq压缩包
    && curl -SL https://archive.apache.org/dist/rocketmq/${ROCKETMQ_VERSION}/rocketmq-all-${ROCKETMQ_VERSION}-bin-release.zip -o /tmp/rocketmq.zip \
    && apk del curl tzdata \
    && unzip /tmp/rocketmq.zip -d ${BASE_DIR}/ \
    && mv ${BASE_DIR}/rocketmq-all-${ROCKETMQ_VERSION}-bin-release ${BASE_DIR}/rocketmq \
    && ln -snf /usr/share/zoneinfo/$TIME_ZONE /etc/localtime && echo $TIME_ZONE > /etc/timezone \
    && mkdir -p ${BASE_DIR}/data/rocketmq \
    && mkdir -p ${BASE_DIR}/data/logs \
    && mkdir -p ${BASE_DIR}/data/console \
    && mkdir -p ${BASE_DIR}/data/console/config \
    && mkdir -p ${BASE_DIR}/data/console/store \
    && mv /tmp/asset/console/users.properties ${BASE_DIR}/data/console/store \
    && mv /tmp/asset/console/* ${BASE_DIR}/data/console/config \
    && mv /tmp/asset/rocketmq/* ${ROCKETMQ_HOME}/bin \
    && mv /tmp/asset/docker/run.sh ${BASE_DIR}/run.sh \
    && mv ${ROCKETMQ_HOME}/conf ${BASE_DIR}/data/rocketmq \
    && rm -rf /tmp/* \
    # 创建软链接
    && ln -s ${BASE_DIR}/data/logs ${BASE_DIR}/logs \
    && ln -s ${BASE_DIR}/data/rocketmq/conf ${ROCKETMQ_HOME}/conf \
    && ln -s ${BASE_DIR}/store ${ROCKETMQ_HOME}/store \
    && ln -s ${BASE_DIR}/data/console/config ${CONSOLE_HOME}/config \
    && ln -s ${BASE_DIR}/data/console/store ${CONSOLE_HOME}/store \
    # 将文件和目录统一设置成644
    && chmod 644 -R ${BASE_DIR} \
    # 将目录统一设置成755
    && find ${BASE_DIR} -type d -print | xargs chmod 755 \
    # 将${BASE_DIR}/rocketmq/rocketmq/bin下统一设置成755
    && chmod 755 -R ${ROCKETMQ_HOME}/bin \
    # 将${BASE_DIR}/run.sh更名为${BASE_DIR}/.run.sh
    && mv ${BASE_DIR}/run.sh ${BASE_DIR}/.run.sh \
    # 将${BASE_DIR}/.run.sh设置为755
    && chmod 755 ${BASE_DIR}/.run.sh

# 导出端口
EXPOSE 8080 9876 10909 10910 10911 10912

# 匿名卷
VOLUME ${BASE_DIR}/data

#执行脚本
CMD ${BASE_DIR}/.run.sh