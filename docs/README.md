# docs/ — screenshots & evidence

Drop captured images here. The root README references them once they exist (the
image links are commented out until the files are committed).

## Shot list

Capture these during a short `make apply ENV=prod` → demo → `make nuke` session
(see [Failover & DR demo](../README.md#failover--dr-demo)). Total apply time is
well under an hour; confirm Oracle License Included pricing first.

| File | What to capture | Where |
|---|---|---|
| `architecture.png` | The rendered Mermaid architecture diagram | GitHub README render, or mermaid.live export |
| `cloudwatch-alarms.png` | All alarms `OK`, then one flipping to `ALARM` during failover | CloudWatch → Alarms |
| `oracle-failover-event.png` | The `Multi-AZ instance failover started/completed` event pair | RDS → Databases → ppc-prod-oracle → Logs & events |
| `aurora-failover-event.png` | Aurora promotion event + recovery time (< 30s) | RDS → Databases → ppc-prod-aurora → Logs & events |
| `performance-insights.png` *(optional)* | Top SQL / DB load during a small load test | RDS → Performance Insights |
| `budget-alert.png` *(optional)* | The AWS Budgets alarm config at the $-ceiling | Billing → Budgets |

## Tips

- Blur or crop account IDs / ARNs before committing — this repo is public.
- PNG, ~1400px wide is plenty; keep each under ~500 KB.
- After adding a file, uncomment its `![...](docs/...)` line in the root README.
