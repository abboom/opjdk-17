FROM ubuntu:24.04

RUN set -x; buildDeps='gcc libc6-dev make wget' \
    && apt-get update \

RUN wget https://packages.microsoft.com/config/ubuntu/${ubuntu_release}/packages-microsoft-prod.deb -O packages-microsoft-prod.deb \
    && dpkg -i packages-microsoft-prod.deb