# OTP / Email – Check All Set Properties

When OTP is not received, verify these in the **auth-service** pod.

## 1. List env vars in the running pod (names only; values hidden)

From repo root or from `sagamba-eks-manifests`:

```bash
# Get one auth-service pod name
POD=$(kubectl get pods -n sagamba -l app=auth-service -o jsonpath='{.items[0].metadata.name}')
echo "Pod: $POD"

# Show all env var NAMES (no values, to avoid leaking secrets)
kubectl exec -n sagamba $POD -- env | sort | cut -d= -f1
```

## 2. Check mail-related env (values shown – run in private)

```bash
POD=$(kubectl get pods -n sagamba -l app=auth-service -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n sagamba $POD -- env | grep -E '^MAIL_|^SMTP_|^DEFAULT_EMAIL|^ALWAYS_USE'
```

Expected (or similar):

- MAIL_HOST=smtp.gmail.com
- MAIL_PORT=587
- MAIL_USERNAME=saveservegroup@gmail.com (or your sender)
- MAIL_PASSWORD=*** (set; never log this)
- MAIL_FROM=saveservegroup@gmail.com
- MAIL_FROM_NAME=noreply
- MAIL_NOTIFICATIONS_ENABLED=true
- SMTP_AUTH=true
- SMTP_STARTTLS=true
- DEFAULT_EMAIL=fistonfle04@gmail.com (where OTP is sent when ALWAYS_USE_DEFAULT_EMAIL=true)
- ALWAYS_USE_DEFAULT_EMAIL=true

If any of these are **empty** or **missing**, OTP may not be sent or may go to the wrong address.

## 3. Check auth-service logs when you request OTP

In one terminal, stream logs:

```bash
kubectl logs -n sagamba -l app=auth-service -f --tail=20
```

Then trigger “Request OTP” from the app (or Swagger). Look for:

- **"Mail not configured. OTP for ..."** → `MAIL_NOTIFICATIONS_ENABLED` is false or Spring could not create JavaMailSender (check MAIL_USERNAME/MAIL_PASSWORD).
- **"Failed to send OTP email to ..."** → SMTP error (auth, TLS, or Gmail blocking).
- **"OTP sent via email to ..."** → Mail sent; check spam or DEFAULT_EMAIL address.

## 4. Properties that must be set for OTP to send

| Property (env) | Used for | Empty/missing? |
|----------------|----------|-----------------|
| MAIL_HOST | SMTP server | Use default smtp.gmail.com |
| MAIL_PORT | SMTP port | Use 587 |
| MAIL_USERNAME | SMTP login | **Must set** (e.g. Gmail address) |
| MAIL_PASSWORD | SMTP password | **Must set** (Gmail App Password) |
| MAIL_FROM | From header | Should match MAIL_USERNAME for Gmail |
| MAIL_FROM_NAME | From name | Optional |
| MAIL_NOTIFICATIONS_ENABLED | Enable sending | Must be true |
| SMTP_AUTH | Use auth | true for Gmail |
| SMTP_STARTTLS | TLS | true for Gmail |
| DEFAULT_EMAIL | Fallback / redirect recipient | Set if ALWAYS_USE_DEFAULT_EMAIL=true |
| ALWAYS_USE_DEFAULT_EMAIL | Send all mail to DEFAULT_EMAIL | true → OTP goes to DEFAULT_EMAIL |

## 5. Gmail checklist

- Use **App Password**, not normal password: Google Account → Security → 2-Step Verification → App passwords.
- MAIL_USERNAME = full Gmail address.
- MAIL_FROM = same as MAIL_USERNAME (or a “Send mail as” address).
- MAIL_PASSWORD = 16-char App Password (no spaces in secret).

## 6. Re-apply ConfigMap and Secret, then restart

If you changed ConfigMap or Secret:

```bash
cd sagamba-eks-manifests
kubectl apply -f configmap.yaml -n sagamba
kubectl apply -f secrets.yaml -n sagamba
kubectl rollout restart deployment auth-service -n sagamba
kubectl rollout status deployment auth-service -n sagamba
```

Then request OTP again and watch logs (step 3).
