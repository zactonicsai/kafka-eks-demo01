FROM python:3.14-slim

RUN useradd --create-home appuser
WORKDIR /home/appuser

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY consumer.py .

USER appuser
CMD ["python", "-u", "consumer.py"]
