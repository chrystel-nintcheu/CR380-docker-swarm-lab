# CR380 — Docker Swarm Lab / Orchestration avec Docker Swarm

> FR : Labs progressifs d'initiation à Docker Swarm et à l'orchestration de conteneurs.
> EN : Progressive labs for Docker Swarm and container orchestration introduction.

## Architecture du projet / Project Architecture

```
                    ┌──────────────────────────────────────┐
                    │         Docker Swarm Cluster          │
                    │         (single-node manager)         │
                    │                                       │
                    │  ┌─────────────────────────────────┐  │
                    │  │     Overlay Network: scalenet    │  │
                    │  │                                  │  │
                    │  │  ┌────────┐  ┌────────┐         │  │
                    │  │  │MariaDB │  │Adminer │         │  │
                    │  │  │ :3306  │  │ :8081  │         │  │
                    │  │  └────────┘  └────────┘         │  │
                    │  │       stack: database            │  │
                    │  │                                  │  │
                    │  │  ┌────────────────────┐          │  │
                    │  │  │   Drupal  :80      │          │  │
                    │  │  │  (1→5→2 replicas)  │          │  │
                    │  │  └────────────────────┘          │  │
                    │  │       stack: drupalsite          │  │
                    │  └─────────────────────────────────┘  │
                    └──────────────────────────────────────┘
```

## Labs

| Lab | Titre / Title | Concepts |
|-----|--------------|----------|
| 00 | Preflight | OS, Docker, espace disque, outils / OS, Docker, disk space, tools |
| 01 | Swarm Init | `docker swarm init`, advertise-addr, join token |
| 02 | Overlay Network | `docker network create -d overlay`, réseau overlay / overlay networking |
| 03 | Database Stack | `docker stack deploy`, MariaDB + Adminer, IaC YAML |
| 04 | Web App Stack | Drupal, découverte de services DNS / DNS service discovery |
| 05 | Surveillance / Monitoring | `docker stack ls`, `docker stack ps`, `docker stack services` |
| 06 | Élasticité horizontale / Horizontal Scaling | `docker service scale`, scale-out, scale-in |
| 99 | Nettoyage / Teardown | `docker stack rm`, `docker swarm leave`, prune |

## Modes d'exécution / Execution Modes

### Mode apprentissage / Learn Mode (étudiants / students)

```bash
sudo bash run-labs.sh --learn
sudo bash run-labs.sh --learn --lab 03   # un seul lab / single lab
```

Pause interactive entre chaque étape avec explications bilingues FR/EN.

### Mode validation / Validate Mode (enseignant / teacher)

```bash
sudo bash run-labs.sh --validate
sudo bash run-labs.sh --validate --lab 04
```

Exécution rapide sans pauses. Génère un rapport JSON dans `results/`.

### Validation enseignant / Teacher Batch Validation

```bash
sudo bash run-teacher-validation.sh
```

### Autres options / Other Options

```bash
sudo bash run-labs.sh --quick            # Labs 00–06 sans teardown
sudo bash run-labs.sh --reset 03         # Réinitialiser le lab 03
sudo bash run-labs.sh --diff             # Comparer deux rapports
sudo bash run-labs.sh --verbose          # Sortie détaillée
```

## Prérequis / Prerequisites

- Ubuntu 22.04+ (ou compatible)
- Docker Engine installé / Docker Engine installed
- Accès sudo / Sudo access
- Connexion Internet / Internet connection (pull d'images, git clone)
- ≥ 10 Go d'espace disque / ≥ 10 GB disk space

## Provisionnement VM / VM Provisioning

### Avec Multipass

```bash
bash cloud-init/provision-multipass.sh
```

### Cloud-init direct

Utilisez `cloud-init/user-data-fresh.yaml` comme user-data pour votre VM cloud ou locale.

## Structure des fichiers / File Structure

```
CR380-docker-swarm-lab/
├── config.env                          # Configuration centrale
├── run-labs.sh                         # Runner principal
├── run-teacher-validation.sh           # Validation enseignant
├── .gitbook.yaml                       # GitBook configuration
├── tests/
│   ├── _common.sh                      # Framework de test
│   ├── 00-preflight.sh                 # Lab 00 — Vérification
│   ├── 01-swarm-init.sh               # Lab 01 — Initialisation Swarm
│   ├── 02-overlay-network.sh          # Lab 02 — Réseau overlay
│   ├── 03-database-stack.sh           # Lab 03 — Pile BD
│   ├── 04-webapp-stack.sh             # Lab 04 — Pile WEBAPP
│   ├── 05-monitoring.sh               # Lab 05 — Surveillance
│   ├── 06-horizontal-scaling.sh       # Lab 06 — Élasticité
│   └── 99-teardown.sh                 # Lab 99 — Nettoyage
├── stack-files/
│   ├── stack.database.yaml             # Lab 03 — MariaDB + Adminer
│   └── stack.drupal.yaml               # Lab 04 — Drupal CMS
├── gitbook/                            # Documentation GitBook
│   ├── README.md                       # Introduction
│   ├── SUMMARY.md                      # Table des matières
│   └── labs/                           # Pages des labs
│       ├── lab-00-preflight.md
│       ├── lab-01-swarm-init.md
│       ├── lab-02-overlay-network.md
│       ├── lab-03-database-stack.md
│       ├── lab-04-webapp-stack.md
│       ├── lab-05-monitoring.md
│       ├── lab-06-horizontal-scaling.md
│       └── lab-99-teardown.md
├── cloud-init/
│   ├── user-data-fresh.yaml
│   └── provision-multipass.sh
├── results/                            # Rapports JSON (git-ignored)
└── logs/                               # Journaux (git-ignored)
```

## Licence / License

GPL-3.0 — Voir [LICENSE](LICENSE)
