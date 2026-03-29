# CR380 — Docker Swarm Lab

Labs progressifs d'initiation à Docker Swarm et à l'orchestration de conteneurs.

Progressive labs for Docker Swarm and container orchestration introduction.

## Prérequis / Prerequisites

- Ubuntu 22.04+
- Docker Engine 24+
- Accès sudo / Sudo access
- Connexion Internet / Internet connection
- ≥ 10 Go d'espace disque / ≥ 10 GB disk space

## Pour commencer / Getting Started

```bash
git clone <repository-url>
cd CR380-docker-swarm-lab
sudo bash run-labs.sh --learn
```

## Architecture

```
┌────── Docker Swarm (single-node manager) ──────┐
│                                                  │
│  ┌─── stack: database ───┐  ┌─ stack: drupal ─┐ │
│  │  mariadb   adminer    │  │    drupal (×N)   │ │
│  │  :3306     :8081      │  │    :80           │ │
│  └───────────────────────┘  └──────────────────┘ │
│            │                        │            │
│            └──── scalenet (overlay) ─┘            │
└──────────────────────────────────────────────────┘
```
