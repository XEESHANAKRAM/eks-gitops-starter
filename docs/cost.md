# Cost

Prices are AWS list prices for `us-east-1` at the time of writing and will
change. Treat these as planning numbers, not a quote — check the
[AWS Pricing Calculator](https://calculator.aws.amazon.com/) before you
commit.

## Default setup (2× t3.medium, 1 NAT gateway, 24/7)

| Resource | Approx. cost / month |
| -------- | -------------------- |
| EKS control plane | ~$73 |
| 2× t3.medium nodes (on-demand) | ~$61 |
| 1× NAT gateway + data processing | ~$32 + usage |
| EBS volumes (nodes + Prometheus 10 Gi + Grafana 5 Gi) | ~$5–10 |
| CloudWatch Logs (EKS control plane logs + VPC Flow Logs) | ~$2–5 |
| LoadBalancer (only if you expose ArgoCD/Grafana publicly) | ~$16–20 each |
| **Total, default** | **~$180–195 / month** |

## How to spend less

| Change | Saves | Trade-off |
| ------ | ----- | --------- |
| Run it only while learning, then `./scripts/destroy.sh` | Everything | Nothing persists |
| `node_desired_size = 1` | ~$30/mo | No HA for the demo app |
| Smaller instance type (`t3.small`) | ~$30/mo | Less headroom for Prometheus |
| Spot instances for the node group | Up to 60–70% of node cost | Nodes can be interrupted |
| `single_nat_gateway = true` (already the default) | ~$64/mo vs 3 NAT gateways | One AZ failure takes out outbound traffic |

## Production direction

For real production use, budget for: 3 NAT gateways, 3 nodes across 3 AZs,
larger instances, and longer Prometheus retention (bigger EBS volumes).
Expect roughly **$350–500 / month** for a small production-grade setup in
one region — and put a billing alarm on the account from day one:

```bash
aws cloudwatch put-metric-alarm --alarm-name billing-over-200 \
  --metric-name EstimatedCharges --namespace AWS/Billing \
  --statistic Maximum --period 21600 --threshold 200 \
  --comparison-operator GreaterThanThreshold --evaluation-periods 1
```
