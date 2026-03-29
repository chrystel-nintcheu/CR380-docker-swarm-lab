# Lab 00 — Prévol / Preflight

## Objectif / Objective

FR: Vérifier que l'environnement est prêt pour les labs Docker Swarm.

EN: Verify the environment is ready for Docker Swarm labs.

## Vérifications / Checks

| Check | Description |
|-------|-------------|
| OS | Ubuntu 22.04+ |
| Access | root, sudo, ou membre du groupe docker |
| Internet | Connectivité vers hub.docker.com |
| Disk | ≥ 10 Go disponibles |
| Docker | Engine installé et démon actif |
| Swarm | Non actif (état propre) |
| Tools | curl, jq, git |

## Commande / Command

```bash
# Avec sudo:
sudo bash run-labs.sh --lab 00

# Ou si vous êtes dans le groupe docker:
bash run-labs.sh --lab 00
```

## Script de test / Test script

`tests/00-preflight.sh`
