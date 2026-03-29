# Lab 01 — Initialisation Swarm / Swarm Init

## Objectif / Objective

FR: Initialiser un cluster Docker Swarm mono-nœud (manager).

EN: Initialize a single-node Docker Swarm cluster (manager).

## Concepts

- `docker swarm init --advertise-addr <IP>`
- Nœud manager vs worker / Manager vs worker node
- Token de jonction / Join token

## Commandes clés / Key commands

```bash
# Déterminer l'adresse IP du nœud
ip -4 addr show scope global

# Initialiser le Swarm
docker swarm init --advertise-addr <IP>

# Vérifier l'état
docker info --format '{{.Swarm.LocalNodeState}}'
docker node ls
```

## Script de test / Test script

`tests/01-swarm-init.sh`
