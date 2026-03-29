# Lab 05 — Surveillance / Monitoring

## Objectif / Objective

FR: Surveiller l'état du cluster Swarm et des stacks déployés à l'aide des commandes d'inspection.

EN: Monitor the Swarm cluster state and deployed stacks using inspection commands.

## Concepts

- Vue d'ensemble des piles / Stack overview
- Inspection des tâches / Task inspection
- Liste des services / Service listing
- État des nœuds / Node state

## Commandes clés / Key commands

```bash
# Lister les piles déployées
docker stack ls

# Tâches d'une pile
docker stack ps database
docker stack ps drupalsite

# Tous les services
docker service ls

# Nœuds du cluster
docker node ls

# Tâches sur ce nœud
docker node ps
```

## Script de test / Test script

`tests/05-monitoring.sh`
