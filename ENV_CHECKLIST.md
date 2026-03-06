# Kubernetes vs .env – Variable Checklist

Reference: `sagamba-microservices/.env` → EKS `sagamba-config` (ConfigMap) + `sagamba-secrets` (Secret).

## ConfigMap (`sagamba-config`)

| .env variable | ConfigMap value | Notes |
|---------------|-----------------|--------|
| DB_HOST | postgres-service | K8s service name |
| DB_PORT | 5432 | |
| DB_NAME | sagamba_db | |
| DB_MAX_POOL_SIZE | 8 | Lower in K8s to limit total connections |
| REDIS_HOST | redis-service | |
| REDIS_PORT | 6379 | |
| REDIS_TIMEOUT | 6000 | Added to match .env |
| RABBITMQ_HOST | rabbitmq-service | |
| RABBITMQ_PORT | 5672 | |
| RABBITMQ_VIRTUAL_HOST | /sagamba | EKS broker vhost |
| EUREKA_HOST | service-registry-service | |
| EUREKA_PORT | 8761 | |
| EUREKA_PREFER_IP_ADDRESS | true | For gateway routing |
| MAIL_HOST | smtp.gmail.com | |
| MAIL_PORT | 587 | |
| MAIL_FROM | saveservegroup@gmail.com | Aligned with .env |
| MAIL_FROM_NAME | noreply | |
| MAIL_NOTIFICATIONS_ENABLED | true | |
| SMTP_AUTH | true | |
| SMTP_STARTTLS | true | |
| PASSWORD_RESET_BASE_URL | https://sagamba.savetoserve.rw | Production URL |
| VERIFICATION_BASE_URL | https://sagamba.savetoserve.rw | |
| DEFAULT_EMAIL | fistonfle04@gmail.com | |
| ALWAYS_USE_DEFAULT_EMAIL | true | |
| REQUIRE_OTP_FOR_LOGIN | true | |
| CORS_ALLOWED_ORIGINS | https://sagamba..., https://sagambaapi..., localhost | |
| PUBLIC_API_URL | https://sagambaapi.savetoserve.rw | For Swagger / api-docs |
| SPRING_PROFILES_ACTIVE | kubernetes | Set in deployment too |

## Secret (`sagamba-secrets`)

| .env variable | Secret key | Notes |
|---------------|------------|--------|
| DB_USERNAME | DB_USERNAME | sagamba_user |
| DB_PASSWORD | DB_PASSWORD | |
| REDIS_PASSWORD | REDIS_PASSWORD | |
| RABBITMQ_USERNAME | RABBITMQ_USERNAME | sagamba_user (not guest in K8s) |
| RABBITMQ_PASSWORD | RABBITMQ_PASSWORD | |
| JWT_SECRET | JWT_SECRET | |
| MAIL_USERNAME | MAIL_USERNAME | saveservegroup@gmail.com |
| MAIL_PASSWORD | MAIL_PASSWORD | Gmail App Password |
| INITIAL_ADMIN_USERNAME | INITIAL_ADMIN_USERNAME | admin |
| INITIAL_ADMIN_EMAIL | INITIAL_ADMIN_EMAIL | admin@sagamba.local |
| INITIAL_ADMIN_PASSWORD | INITIAL_ADMIN_PASSWORD | Admin123! |

## Not in Kubernetes (app defaults or not needed in K8s)

| .env variable | Reason |
|---------------|--------|
| REDIS_MAX_ACTIVE, REDIS_MAX_IDLE, REDIS_MIN_IDLE | App defaults OK |
| DB_MIN_IDLE, DB_CONNECTION_TIMEOUT | App defaults OK |
| JWT_EXPIRATION, JWT_REFRESH_EXPIRATION | App defaults (auth-service) |
| SERVICE_REGISTRY_PORT, API_GATEWAY_PORT, AUTH_SERVICE_PORT, ... | Ports are in deployment spec |
| LOG_LEVEL_* | Optional; set in ConfigMap if you want to tune |
| FLYWAY_* | Defaults in app |
| OTP_EXPIRY_MINUTES, EMAIL_VERIFICATION_EXPIRY_HOURS, PASSWORD_SETUP_AFTER_VERIFY_MINUTES | App defaults |
| CORS_ALLOWED_METHODS | Gateway/ConfigMap can add if needed |

## Auth-service deployment env

Auth-service gets all of the above from ConfigMap and Secret via `valueFrom`; it also has:

- REDIS_TIMEOUT (from ConfigMap)
- PUBLIC_API_URL (from ConfigMap)

## Apply after changes

```bash
kubectl apply -f sagamba-eks-manifests/configmap.yaml -n sagamba
kubectl apply -f sagamba-eks-manifests/secrets.yaml -n sagamba
# If you only patched secrets:
# kubectl patch secret sagamba-secrets -n sagamba --type=merge -p '{"stringData":{...}}'
kubectl rollout restart deployment auth-service -n sagamba
```
