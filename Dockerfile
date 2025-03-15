FROM debian:stretch

RUN set -x; buildDeps='gcc libc6-dev make wget' \
    && apt-get update \
    && wget -O redis.tar.gz "http://download.redis.io/releases/redis-5.0.3.tar.gz"