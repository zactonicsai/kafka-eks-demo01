# Small, secure Python base.
FROM python:3.14-slim

# Run as a non-root user (security best practice).
RUN useradd --create-home appuser
WORKDIR /home/appuser

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY producer.py .

USER appuser
CMD ["python", "-u", "producer.py"]
