FROM openjdk:8u212-jdk-stretch
LABEL maintainer="Manuel de la Peña <manuel.delapenya@liferay.com>"

ENV LIFERAY_HOME=/liferay

ENV CATALINA_HOME=$LIFERAY_HOME/tomcat-9.0.10 \
  GOSU_VERSION=1.10 \
  LIFERAY_CONFIG_DIR=/tmp/liferay/configs \
  LIFERAY_DEPLOY_DIR=/tmp/liferay/deploy \
  LIFERAY_SHARED=/storage/liferay \
  LIFERAY_TOMCAT_URL=https://sourceforge.net/projects/lportal/files/Liferay%20Portal/7.1.2%20GA3/liferay-ce-portal-tomcat-7.1.2-ga3-20190107144105508.tar.gz/download

ENV GOSU_URL=https://github.com/tianon/gosu/releases/download/$GOSU_VERSION \
  PATH=$CATALINA_HOME/bin:$PATH

RUN set -x \
  && apt-get update \
  && apt-get install -y  \
    curl telnet tree \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  && useradd -ms /bin/bash liferay \
  && mkdir -p "$LIFERAY_HOME" \
  && chown -R liferay:liferay $LIFERAY_HOME \
  && wget -O /usr/local/bin/gosu "$GOSU_URL/gosu-$(dpkg --print-architecture)" \
  && wget -O /usr/local/bin/gosu.asc "$GOSU_URL/gosu-$(dpkg --print-architecture).asc" \
  && export GNUPGHOME="$(mktemp -d)" \
  && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
  && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
  && rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc \
  && chmod +x /usr/local/bin/gosu \
  && gosu nobody true

USER liferay

RUN set -x \
  && mkdir -p /tmp/liferay \
  && curl -fSL "$LIFERAY_TOMCAT_URL" -o /tmp/liferay-ce-portal-tomcat.tar.gz \
  && tar -xvf /tmp/liferay-ce-portal-tomcat.tar.gz -C /tmp/liferay \
  && mv /tmp/liferay/liferay-ce-portal-7.1.2-ga3/* $LIFERAY_HOME/ \
  && rm /tmp/liferay-ce-portal-tomcat.tar.gz \
  && rm -fr /tmp/liferay/liferay-ce-portal-7.1.2-ga3

USER root

WORKDIR $LIFERAY_HOME

COPY ./configs/setenv.sh $CATALINA_HOME/bin/setenv.sh
COPY ./entrypoint.sh /usr/local/bin
RUN chmod +x /usr/local/bin/entrypoint.sh
RUN chmod +x $CATALINA_HOME/bin/catalina.sh

EXPOSE 8080/tcp
EXPOSE 9000/tcp
EXPOSE 11311/tcp

VOLUME /storage

ENTRYPOINT ["entrypoint.sh"]
CMD ["catalina.sh", "run"]