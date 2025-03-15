FROM ubuntu:latest
LABEL authors="ashen"

ENTRYPOINT ["top", "-b"]