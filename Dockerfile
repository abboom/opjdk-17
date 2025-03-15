FROM ubuntu:24.04

RUN set -x; buildDeps='gcc libc6-dev make wget' \
    && apt-get update