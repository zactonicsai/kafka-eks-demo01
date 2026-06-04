"""Kafka producer that sends a message every second and reports OTEL metrics.

Metrics emitted (scraped via the OTEL collector -> Prometheus -> Grafana):
  * messages_produced_total : counter of messages sent
Traces emitted:
  * one span per produced message
"""
import json
import os
import time

from confluent_kafka import Producer

# ---- OpenTelemetry setup -------------------------------------------------
from opentelemetry import metrics, trace
from opentelemetry.exporter.otlp.proto.grpc.metric_exporter import OTLPMetricExporter
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.metrics import MeterProvider
from opentelemetry.sdk.metrics.export import PeriodicExportingMetricReader
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor

# Config from environment (set in docker-compose).
BOOTSTRAP = os.environ.get("KAFKA_BOOTSTRAP", "kafka:9092")
TOPIC = os.environ.get("KAFKA_TOPIC", "demo-messages")
OTLP = os.environ.get("OTEL_EXPORTER_OTLP_ENDPOINT", "http://otel-collector:4317")
SERVICE = os.environ.get("OTEL_SERVICE_NAME", "kafka-producer")

resource = Resource.create({"service.name": SERVICE})

# Metrics provider: push to the OTEL collector every 5s.
metric_reader = PeriodicExportingMetricReader(
    OTLPMetricExporter(endpoint=OTLP, insecure=True), export_interval_millis=5000
)
metrics.set_meter_provider(MeterProvider(resource=resource, metric_readers=[metric_reader]))
meter = metrics.get_meter(SERVICE)
produced_counter = meter.create_counter(
    "messages_produced", description="Total messages produced"
)

# Trace provider: send spans to the collector.
trace.set_tracer_provider(TracerProvider(resource=resource))
trace.get_tracer_provider().add_span_processor(
    BatchSpanProcessor(OTLPSpanExporter(endpoint=OTLP, insecure=True))
)
tracer = trace.get_tracer(SERVICE)

# ---- Kafka producer ------------------------------------------------------
producer = Producer({"bootstrap.servers": BOOTSTRAP})


def delivery_report(err, msg):
    """Called once per message to confirm delivery (or report failure)."""
    if err is not None:
        print(f"Delivery failed: {err}")
    else:
        print(f"Delivered to {msg.topic()} [{msg.partition()}] @ offset {msg.offset()}")


def main():
    n = 0
    while True:
        n += 1
        # A span lets OTEL trace the produce operation end-to-end.
        with tracer.start_as_current_span("produce_message"):
            payload = {
                "id": n,
                "ts": time.time(),  # send timestamp; consumer uses it for latency
                "text": f"hello-{n}",
            }
            producer.produce(
                TOPIC, value=json.dumps(payload).encode("utf-8"), callback=delivery_report
            )
            producer.poll(0)  # serve delivery callbacks
            produced_counter.add(1, {"topic": TOPIC})
            print(f"Produced message {n}")
        time.sleep(1)


if __name__ == "__main__":
    main()
