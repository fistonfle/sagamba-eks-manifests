#!/usr/bin/env bash
# Start port-forwards to EKS infra for local development.
# Run from sagamba-eks-manifests (or set NAMESPACE).
# Requires: kubectl, cluster access.

set -e
NS="${NAMESPACE:-sagamba}"

echo "Port-forwarding EKS infra to localhost (namespace=$NS). Press Ctrl+C to stop."
echo "  PostgreSQL: localhost:5432"
echo "  Redis:      localhost:6379"
echo "  RabbitMQ:   localhost:5672 (AMQP), localhost:15672 (UI)"
echo "  pgAdmin:    http://localhost:5050"
echo ""

cleanup() {
  echo ""
  echo "Stopping port-forwards..."
  for pid in $pids; do kill "$pid" 2>/dev/null; done
  exit 0
}
trap cleanup SIGINT SIGTERM

kubectl port-forward -n "$NS" svc/postgres-service 5432:5432 &
pids="$!"
kubectl port-forward -n "$NS" svc/redis-service 6379:6379 &
pids="$pids $!"
kubectl port-forward -n "$NS" svc/rabbitmq-service 5672:5672 15672:15672 &
pids="$pids $!"
kubectl port-forward -n "$NS" svc/pgadmin 5050:80 &
pids="$pids $!"

wait
