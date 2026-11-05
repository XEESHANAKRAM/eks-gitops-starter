"""Demo app for eks-gitops-starter.

A tiny Flask web app that proves the full GitOps flow end to end:
code -> image -> Git -> ArgoCD -> EKS -> Prometheus metrics -> Grafana.
"""
import time

from flask import Flask, jsonify
from prometheus_client import CONTENT_TYPE_LATEST, Counter, Histogram, generate_latest

app = Flask(__name__)

REQUEST_COUNT = Counter(
    "demo_app_http_requests_total",
    "Total HTTP requests served by the demo app",
    ["method", "endpoint", "status"],
)
REQUEST_LATENCY = Histogram(
    "demo_app_http_request_duration_seconds",
    "HTTP request latency in seconds",
    ["method", "endpoint"],
)


@app.before_request
def _start_timer():
    from flask import request

    request.start_time = time.time()


@app.after_request
def _record_metrics(response):
    from flask import request

    latency = time.time() - request.start_time
    REQUEST_COUNT.labels(request.method, request.path, response.status_code).inc()
    REQUEST_LATENCY.labels(request.method, request.path).observe(latency)
    return response


@app.route("/")
def index():
    return jsonify(
        {
            "app": "demo-app",
            "message": "Hello from eks-gitops-starter!",
            "gitops": "Deployed by ArgoCD from apps/demo-app/k8s",
        }
    )


@app.route("/healthz")
def healthz():
    return jsonify({"status": "ok"}), 200


@app.route("/metrics")
def metrics():
    return generate_latest(), 200, {"Content-Type": CONTENT_TYPE_LATEST}


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
