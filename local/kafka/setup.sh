#!/usr/bin/env bash
# Downloads the Prometheus JMX exporter Java agent that the Kafka broker loads
# (see KAFKA_OPTS in docker-compose.yml). Run this ONCE before `docker compose up`.
set -euo pipefail

# Pin the agent version (latest 1.x on Maven Central).
JMX_VERSION="1.0.1"
JAR_URL="https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/${JMX_VERSION}/jmx_prometheus_javaagent-${JMX_VERSION}.jar"
DEST="$(dirname "$0")/jmx_prometheus_javaagent.jar"

if [[ -f "$DEST" ]]; then
  echo "JMX agent already present at $DEST"
  exit 0
fi

echo "Downloading JMX Prometheus Java agent ${JMX_VERSION}..."
curl -fsSL -o "$DEST" "$JAR_URL"
echo "Saved to $DEST"
