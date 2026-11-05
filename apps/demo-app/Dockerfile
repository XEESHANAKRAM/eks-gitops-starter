# syntax=docker/dockerfile:1
FROM python:3.12-slim

WORKDIR /app

# Install dependencies first so the layer is cached between code changes.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

# Run as a non-root user.
RUN useradd -m appuser && chown -R appuser:appuser /app
USER appuser

EXPOSE 8080

# 2 gunicorn workers is plenty for a demo app.
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "2", "app:app"]
