# Lab 99 — Nettoyage / Teardown

## Objectif / Objective

FR: Nettoyer toutes les ressources Swarm créées pendant les labs.

EN: Clean up all Swarm resources created during the labs.

## Étapes / Steps

1. Supprimer la pile Drupal / Remove Drupal stack
2. Supprimer la pile database / Remove database stack
3. Supprimer le réseau overlay / Remove overlay network
4. Quitter le Swarm / Leave the Swarm
5. (Optionnel) `docker system prune` / (Optional) system prune

## Commandes clés / Key commands

```bash
# Supprimer les piles
docker stack rm drupalsite
docker stack rm database

# Supprimer le réseau
docker network rm scalenet

# Quitter le Swarm
docker swarm leave --force

# Nettoyage complet (optionnel)
docker system prune -a --volumes
```

## Script de test / Test script

`tests/99-teardown.sh`
