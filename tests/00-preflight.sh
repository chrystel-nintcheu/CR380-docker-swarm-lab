#!/usr/bin/env bash
# =============================================================================
# CR380 - Lab 00 — Vérifications préalables / Preflight Checks
# =============================================================================
#
# FR: Vérifier que l'environnement est prêt pour les labs Docker Swarm.
#     Couvre: OS, sudo, réseau, espace disque, Docker, outils.
#
# EN: Verify the environment is ready for the Docker Swarm labs.
#     Covers: OS, sudo, network, disk space, Docker, tools.
#
# Depends on: (none)
#
# =============================================================================

run_test() {
    section_header "00" "Vérifications préalables / Preflight Checks"

    # -------------------------------------------------------------------------
    # Step 1: Check OS
    # FR: Vérifier la version du système d'exploitation
    # -------------------------------------------------------------------------
    learn_pause \
        "Nous vérifions d'abord que le système d'exploitation est Ubuntu.\nCommande: lsb_release -d" \
        "First we verify the operating system is Ubuntu.\nCommand: lsb_release -d"

    if command -v lsb_release &>/dev/null; then
        assert_output_contains \
            "OS is Ubuntu / Le SE est Ubuntu" \
            "Ubuntu" \
            "Installez Ubuntu 22.04+ LTS / Install Ubuntu 22.04+ LTS" \
            lsb_release -d
    else
        # Fallback: check /etc/os-release
        assert_output_contains \
            "OS is Ubuntu / Le SE est Ubuntu" \
            "Ubuntu" \
            "Installez Ubuntu 22.04+ LTS / Install Ubuntu 22.04+ LTS" \
            cat /etc/os-release
    fi

    # -------------------------------------------------------------------------
    # Step 2: Check sudo access
    # FR: Vérifier l'accès sudo
    # -------------------------------------------------------------------------
    learn_pause \
        "Vérification de l'accès sudo.\nCommande: sudo -n true" \
        "Checking sudo access.\nCommand: sudo -n true"

    if (( EUID == 0 )); then
        pass "Running as root / Exécution en tant que root"
    elif sudo -n true 2>/dev/null; then
        pass "sudo access available / Accès sudo disponible"
    else
        fail "sudo access not available / Accès sudo non disponible" \
             "sudo -n true exits 0" \
             "sudo requires a password" \
             "Exécutez avec sudo: sudo ./run-labs.sh / Run with sudo: sudo ./run-labs.sh"
    fi

    # -------------------------------------------------------------------------
    # Step 3: Check internet connectivity
    # FR: Vérifier la connexion Internet
    # -------------------------------------------------------------------------
    learn_pause \
        "Vérification de la connexion Internet vers Docker Hub.\nCommande: curl -s --max-time 10 https://hub.docker.com" \
        "Checking Internet connectivity to Docker Hub.\nCommand: curl -s --max-time 10 https://hub.docker.com"

    run_cmd "Check Internet" "${TIMEOUT_DEFAULT}" \
        curl -s --max-time 10 -o /dev/null -w '%{http_code}' https://hub.docker.com || true

    if (( CMD_EXIT_CODE == 0 )); then
        pass "Internet connectivity OK / Connexion Internet OK"
    else
        fail "Internet connectivity" \
             "HTTP response from hub.docker.com" \
             "curl exit code ${CMD_EXIT_CODE}" \
             "Vérifiez votre connexion Internet / Check your Internet connection"
    fi

    # -------------------------------------------------------------------------
    # Step 4: Check disk space
    # FR: Vérifier l'espace disque disponible
    # -------------------------------------------------------------------------
    learn_pause \
        "Vérification de l'espace disque disponible (minimum ${MIN_DISK_GB} Go).\nCommande: df -BG /" \
        "Checking available disk space (minimum ${MIN_DISK_GB} GB).\nCommand: df -BG /"

    local avail_gb
    avail_gb=$(df -BG / | awk 'NR==2 {print $4}' | tr -d 'G')

    if (( avail_gb >= MIN_DISK_GB )); then
        pass "Disk space: ${avail_gb} GB available (>= ${MIN_DISK_GB} GB) / Espace disque: ${avail_gb} Go"
    else
        fail "Disk space insufficient / Espace disque insuffisant" \
             ">= ${MIN_DISK_GB} GB" \
             "${avail_gb} GB" \
             "Libérez de l'espace disque / Free up disk space"
    fi

    # -------------------------------------------------------------------------
    # Step 5: Check Docker is installed
    # FR: Vérifier que Docker est installé
    # -------------------------------------------------------------------------
    learn_pause \
        "Vérification que Docker est installé.\nCommande: docker --version\n\nDocker doit être installé avant de commencer les labs Swarm." \
        "Checking Docker is installed.\nCommand: docker --version\n\nDocker must be installed before starting the Swarm labs."

    if command -v docker &>/dev/null; then
        assert_output_not_empty \
            "Docker is installed / Docker est installé" \
            "Installez Docker d'abord: sudo apt-get install docker-ce / Install Docker first" \
            docker --version
    else
        fail "Docker is not installed / Docker n'est pas installé" \
             "docker command available" "not found" \
             "Installez Docker: https://docs.docker.com/engine/install/ubuntu/"
    fi

    # -------------------------------------------------------------------------
    # Step 6: Check Docker daemon is running
    # FR: Vérifier que le démon Docker fonctionne
    # -------------------------------------------------------------------------
    learn_pause \
        "Vérification que le démon Docker est en cours d'exécution.\nCommande: docker info" \
        "Checking Docker daemon is running.\nCommand: docker info"

    if command -v docker &>/dev/null; then
        assert_success \
            "Docker daemon is running / Le démon Docker fonctionne" \
            "Essayez: sudo systemctl start docker" \
            docker info
    else
        skip "Docker daemon check skipped (Docker not installed)" \
             "Docker n'est pas installé / Docker is not installed"
    fi

    # -------------------------------------------------------------------------
    # Step 7: Check Swarm is NOT active (clean start)
    # FR: Vérifier que le Swarm n'est pas déjà actif
    # -------------------------------------------------------------------------
    learn_pause \
        "Vérification que le Swarm n'est pas déjà initialisé.\nNous voulons partir d'un état propre.\n\nCommande: docker info --format '{{.Swarm.LocalNodeState}}'" \
        "Checking Swarm is not already initialized.\nWe want a clean starting state.\n\nCommand: docker info --format '{{.Swarm.LocalNodeState}}'"

    if command -v docker &>/dev/null; then
        local swarm_state
        swarm_state=$(docker info --format '{{.Swarm.LocalNodeState}}' 2>/dev/null || echo "unknown")
        if [[ "${swarm_state}" == "inactive" ]]; then
            pass "Swarm is inactive (clean state) / Swarm inactif (état propre)"
        elif [[ "${swarm_state}" == "active" ]]; then
            skip "Swarm is already active — will be used as-is" \
                 "Exécutez 'docker swarm leave --force' pour réinitialiser / Run 'docker swarm leave --force' to reset"
        else
            skip "Cannot determine Swarm state: ${swarm_state}" \
                 "Vérifiez que Docker fonctionne / Check Docker is running"
        fi
    else
        skip "Swarm check skipped (Docker not installed)" \
             "Docker n'est pas installé / Docker is not installed"
    fi

    # -------------------------------------------------------------------------
    # Step 8: Check required tools
    # FR: Vérifier que les outils requis sont installés
    # -------------------------------------------------------------------------
    learn_pause \
        "Vérification des outils requis: curl, jq, git." \
        "Checking required tools: curl, jq, git."

    local tools=("curl" "jq" "git")
    for tool in "${tools[@]}"; do
        if command -v "${tool}" &>/dev/null; then
            pass "${tool} is installed / ${tool} est installé"
        else
            fail "${tool} is missing / ${tool} est manquant" \
                 "${tool} available in PATH" \
                 "not found" \
                 "Installez avec: sudo apt-get install -y ${tool}"
        fi
    done

    section_summary
}
