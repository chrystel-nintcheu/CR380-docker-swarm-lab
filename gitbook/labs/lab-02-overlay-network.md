# Lab 02 — Réseau overlay / Overlay Network

## Objectif / Objective

FR: Créer un réseau overlay pour la communication inter-services dans le Swarm.

EN: Create an overlay network for inter-service communication in the Swarm.

## Concepts

- Réseau overlay vs bridge / Overlay vs bridge network
- Portée Swarm / Swarm scope
- DNS interne / Internal DNS

## Commandes clés / Key commands

```bash
# Créer le réseau overlay
docker network create -d overlay scalenet

# Vérifier
docker network ls
docker network inspect scalenet
```

## Script de test / Test script

`tests/02-overlay-network.sh`
