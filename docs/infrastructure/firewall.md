# Firewall (UFW) — planeamento

**NÃO alterar firewall nesta fase.**

## Portas públicas futuras (recomendado)

| Porta | Origem | Motivo |
|-------|--------|--------|
| 22 | IPs admin | SSH |
| 80 | qualquer (ou só Cloudflare) | redirect / challenge |
| 443 | qualquer (ou só Cloudflare) | HTTPS |

## Não expor publicamente

- `3306` MySQL
- `6379` Redis
- `4001` API (só `127.0.0.1` no host)
- Portas DEV (`3312`, `6380`, `8686`, `8280`)

## Cloudflare IP allowlist (opcional)

Restringir 80/443 aos [IP ranges Cloudflare](https://www.cloudflare.com/ips/) após o proxy estar estável.

## Verificação futura

```bash
./infra/scripts/check-stack.sh
sudo ufw status verbose
```
