# Lab 03 — Pile base de données / Database Stack

## Objectif / Objective

FR: Déployer la pile base de données (MariaDB + Adminer) en tant que stack Swarm.

EN: Deploy the database stack (MariaDB + Adminer) as a Swarm stack.

## Concepts

- `docker stack deploy`
- Fichier stack YAML / Stack YAML file
- Services: MariaDB (port 3306), Adminer (port 8081)
- Volumes persistants / Persistent volumes
- Réseau overlay externe / External overlay network

## Commandes clés / Key commands

```bash
# Déployer la pile
docker stack deploy -c stack-files/stack.database.yaml database

# Vérifier les services
docker stack ls
docker stack ps database
docker service ls
```

## Fichier stack / Stack file

`stack-files/stack.database.yaml`

## Script de test / Test script

`tests/03-database-stack.sh`
