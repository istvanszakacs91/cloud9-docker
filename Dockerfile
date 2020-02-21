FROM alpine:3.8

RUN apk --update add build-base g++ make curl wget openssl-dev apache2-utils git libxml2-dev sshfs nodejs nodejs-npm bash tmux supervisor ruby ruby-dev sqlite \
 && rm -f /var/cache/apk/*\
 && git clone https://github.com/c9/core.git /cloud9 \
 && cd cloud9 \
 && curl -s -L https://raw.githubusercontent.com/c9/install/master/link.sh | bash \
 && /cloud9/scripts/install-sdk.sh \
 && sed -i -e 's_127.0.0.1_0.0.0.0_g' /cloud9/configs/standalone.js \
 && mkdir /workspace \
 && mkdir -p /var/log/supervisor

# add a simple script that can auto-detect the appropriate JAVA_HOME value
# based on whether the JDK or only the JRE is installed
RUN { \
        echo '#!/bin/sh'; \
        echo 'set -e'; \
        echo; \
        echo 'dirname "$(dirname "$(readlink -f "$(which javac || which java)")")"'; \
    } > /usr/local/bin/docker-java-home \
    && chmod +x /usr/local/bin/docker-java-home
ENV JAVA_HOME /usr/lib/jvm/java-1.8-openjdk
ENV PATH $PATH:/usr/lib/jvm/java-1.8-openjdk/jre/bin:/usr/lib/jvm/java-1.8-openjdk/bin

ENV JAVA_VERSION 8u212
ENV JAVA_ALPINE_VERSION 8.212.04-r0

RUN set -x \
    && apk add --no-cache \
        openjdk8="$JAVA_ALPINE_VERSION" \
    && [ "$JAVA_HOME" = "$(docker-java-home)" ]

ADD supervisord.conf /etc/

VOLUME /workspace

EXPOSE 80

ENTRYPOINT ["supervisord", "--nodaemon", "--configuration", "/etc/supervisord.conf"]
