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

kubectl port-forward -n "$NS" \
  svc/postgres-service 5432:5432 \
  svc/redis-service 6379:6379 \
  svc/rabbitmq-service 5672:5672 15672:15672 \
  svc/pgadmin 5050:80
