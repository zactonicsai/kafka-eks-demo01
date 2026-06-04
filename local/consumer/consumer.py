"""Kafka consumer that reads messages and reports OTEL metrics.

Metrics emitted:
  * messages_consumed_total : counter of messages received
  * message_latency_ms      : histogram of produce->consume latency
Traces emitted:
  * one span per consumed message
"""
import json
import os
import time

from confluent_kafka import Consumer

from opentelemetry import metrics, trace
from opentelemetry.exporter.otlp.proto.grpc.metric_exporter import OTLPMetricExporter
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.metrics import MeterProvider
from opentelemetry.sdk.metrics.export import PeriodicExportingMetricReader
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor

BOOTSTRAP = os.environ.get("KAFKA_BOOTSTRAP", "kafka:9092")
TOPIC = os.environ.get("KAFKA_TOPIC", "demo-messages")
GROUP = os.environ.get("KAFKA_GROUP", "demo-consumer-group")
OTLP = os.environ.get("OTEL_EXPORTER_OTLP_ENDPOINT", "http://otel-collector:4317")
SERVICE = os.environ.get("OTEL_SERVICE_NAME", "kafka-consumer")

resource = Resource.create({"service.name": SERVICE})

metric_reader = PeriodicExportingMetricReader(
    OTLPMetricExporter(endpoint=OTLP, insecure=True), export_interval_millis=5000
)
metrics.set_meter_provider(MeterProvider(resource=resource, metric_readers=[metric_reader]))
meter = metrics.get_meter(SERVICE)
consumed_counter = meter.create_counter(
    "messages_consumed", description="Total messages consumed"
)
latency_hist = meter.create_histogram(
    "message_latency_ms", description="Produce-to-consume latency in ms", unit="ms"
)

trace.set_tracer_provider(TracerProvider(resource=resource))
trace.get_tracer_provider().add_span_processor(
    BatchSpanProcessor(OTLPSpanExporter(endpoint=OTLP, insecure=True))
)
tracer = trace.get_tracer(SERVICE)

# ---- Kafka consumer ------------------------------------------------------
consumer = Consumer(
    {
        "bootstrap.servers": BOOTSTRAP,
        "group.id": GROUP,
        "auto.offset.reset": "earliest",  # read from start on first run
    }
)
consumer.subscribe([TOPIC])


def main():
    print(f"Consuming from {TOPIC} as group {GROUP}")
    while True:
        msg = consumer.poll(1.0)  # wait up to 1s for a message
        if msg is None:
            continue
        if msg.error():
            print(f"Consumer error: {msg.error()}")
            continue

        with tracer.start_as_current_span("consume_message"):
            data = json.loads(msg.value().decode("utf-8"))
            # Compute end-to-end latency using the producer's timestamp.
            latency_ms = (time.time() - data.get("ts", time.time())) * 1000.0
            consumed_counter.add(1, {"topic": TOPIC})
            latency_hist.record(latency_ms, {"topic": TOPIC})
            print(f"Consumed id={data.get('id')} latency={latency_ms:.1f}ms")


if __name__ == "__main__":
    main()
