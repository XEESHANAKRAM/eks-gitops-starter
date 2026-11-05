# syntax=docker/dockerfile:1
# Alpine base: the Debian-slim image carried 46 unpatched HIGH vulnerabilities
# in its OS packages (no fixed versions available yet), so the image uses
# Alpine instead — same app, far smaller vulnerability surface.
FROM python:3.12-alpine

# Patch Alpine packages so the image ships without known HIGH vulnerabilities.
RUN apk upgrade --no-cache

WORKDIR /app

# Install dependencies first so the layer is cached between code changes.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

# Run as a non-root user.
RUN adduser -D appuser && chown -R appuser:appuser /app
USER appuser

EXPOSE 8080

# 2 gunicorn workers is plenty for a demo app.
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "2", "app:app"]
