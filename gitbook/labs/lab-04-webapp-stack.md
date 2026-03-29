# Lab 04 — Pile application web / Web App Stack

## Objectif / Objective

FR: Déployer la pile application web (Drupal) et vérifier la communication inter-piles via DNS Swarm.

EN: Deploy the web application stack (Drupal) and verify cross-stack communication via Swarm DNS.

## Concepts

- Deuxième stack sur le même réseau overlay
- Découverte de services DNS / DNS service discovery
- Drupal CMS connecté à MariaDB
- Communication inter-piles / Cross-stack communication

## Commandes clés / Key commands

```bash
# Déployer la pile Drupal
docker stack deploy -c stack-files/stack.drupal.yaml drupalsite

# Vérifier
docker stack ps drupalsite
curl -s http://localhost:80

# Test DNS (depuis le conteneur Drupal)
docker exec <drupal_container> ping -c 2 mariadb
```

## Fichier stack / Stack file

`stack-files/stack.drupal.yaml`

## Script de test / Test script

`tests/04-webapp-stack.sh`
