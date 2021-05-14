FROM debian:stable-slim as build

ENV INFLUXDB_DB="speedtest" \
    INFLUXDB_URL="http://influxdb:8086" \
    SPEEDTEST_HOST="local" \
    SPEEDTEST_INTERVAL=3600

WORKDIR /app

RUN export SPEEDTESTVERSION="1.0.0" && \
    export SPEEDTESTARCH="x86_64" && \
    export SPEEDTESTPLATFORM="linux" && \
    apt-get update && \
    apt-get install bc jq curl -y && \
    curl -Ss -L https://ookla.bintray.com/download/ookla-speedtest-$SPEEDTESTVERSION-$SPEEDTESTARCH-$SPEEDTESTPLATFORM.tgz | tar -zx -C /app && \
    chmod +x speedtest

COPY run.sh .
RUN chmod +x run.sh

ENTRYPOINT ["./run.sh"]