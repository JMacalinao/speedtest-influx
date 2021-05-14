#!/bin/bash

echo "Wait for things to calm down for a while... (60s)"
sleep 60

while :; do
	if [[ -z "${SPEEDTEST_SERVER}" ]]; then
	 	echo "[$(date)] Starting Speedtest CLI..."
		JSON=$(./speedtest --accept-license --accept-gdpr -f json)
	else
 		echo "[$(date)] Starting Speedtest CLI with specific server ID ${SPEEDTEST_SERVER}..."
 		JSON=$(./speedtest --accept-license --accept-gdpr -f json -s ${SPEEDTEST_SERVER})
	fi

	DOWNLOAD=$(echo ${JSON} | jq -r .download.bandwidth)
	DOWNLOAD=$(printf %.2f\\n "$((DOWNLOAD * 8 / 10000))e-2")
	UPLOAD=$(echo ${JSON} | jq -r .upload.bandwidth)
	UPLOAD=$(printf %.2f\\n "$((UPLOAD * 8 / 10000))e-2")
	PING=$(echo ${JSON} | jq -r .ping.latency)
	JITTER=$(echo ${JSON} | jq -r .ping.jitter)
	SHARE=$(echo ${JSON} | jq -r .result.url)
	UPLOAD=$(echo $UPLOAD | sed 's/\(\.[0-9][0-9]\)[0-9]*/\1/g')
	DOWNLOAD=$(echo $DOWNLOAD | sed 's/\(\.[0-9][0-9]\)[0-9]*/\1/g')

	if (( $(echo "$DOWNLOAD > 0 && $UPLOAD > 0" | bc -l) )); then
		echo "[$(date)] Speedtest results - Download: ${DOWNLOAD}, Upload: ${UPLOAD}, Ping: ${PING}, Jitter: ${JITTER}, Share: ${SHARE}"
		curl -sL -XPOST "${INFLUXDB_URL}/write?db=${INFLUXDB_DB}" --data-binary "download,host=${SPEEDTEST_HOST} value=${DOWNLOAD}"
		curl -sL -XPOST "${INFLUXDB_URL}/write?db=${INFLUXDB_DB}" --data-binary "upload,host=${SPEEDTEST_HOST} value=${UPLOAD}"
		curl -sL -XPOST "${INFLUXDB_URL}/write?db=${INFLUXDB_DB}" --data-binary "ping,host=${SPEEDTEST_HOST} value=${PING}"
		curl -sL -XPOST "${INFLUXDB_URL}/write?db=${INFLUXDB_DB}" --data-binary "jitter,host=${SPEEDTEST_HOST} value=${JITTER}"
		curl -sL -XPOST "${INFLUXDB_URL}/write?db=${INFLUXDB_DB}" --data-binary "share,host=${SPEEDTEST_HOST} value=\"${SHARE}\""
	else
		echo "[$(date)] Unable to get Speedtest results."
	fi
	
	echo "[$(date)] Sleeping for ${SPEEDTEST_INTERVAL} seconds..."
	sleep ${SPEEDTEST_INTERVAL}
done
