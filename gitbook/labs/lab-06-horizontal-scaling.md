# Lab 06 — Élasticité horizontale / Horizontal Scaling

## Objectif / Objective

FR: Expérimenter la mise à l'échelle horizontale (scale-out / scale-in) des services Swarm.

EN: Experiment with horizontal scaling (scale-out / scale-in) of Swarm services.

## Concepts

- `docker service scale`
- Scale-out : augmenter les répliques (1 → 5)
- Scale-in : réduire les répliques (5 → 2)
- Restauration : retour à la valeur initiale (2 → 1)
- Répartition de charge / Load balancing

## Commandes clés / Key commands

```bash
# Augmenter à 5 répliques
docker service scale drupalsite_drupal=5

# Observer
docker service ps drupalsite_drupal

# Réduire à 2
docker service scale drupalsite_drupal=2

# Restaurer
docker service scale drupalsite_drupal=1
```

## Script de test / Test script

`tests/06-horizontal-scaling.sh`
