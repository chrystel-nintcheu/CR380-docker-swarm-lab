#!/usr/bin/env bash
# =============================================================================
# CR380 - Lab 01 — Initialisation du Swarm / Swarm Initialization
# =============================================================================
#
# FR: Initialiser un cluster Docker Swarm sur le nœud courant.
#     Couvre: détection IP, docker swarm init, vérification manager,
#     token d'adhésion worker.
#
# EN: Initialize a Docker Swarm cluster on the current node.
#     Covers: IP detection, docker swarm init, manager verification,
#     worker join token.
#
# Depends on: 00
#
# =============================================================================

run_test() {
    section_header "01" "Initialisation du Swarm / Swarm Init" \
        "${GITBOOK_URL_01}"

    check_dependency "00" || { section_summary; return; }

    # -------------------------------------------------------------------------
    # Step 1: Detect the node IP address
    # FR: Identifier l'adresse IP du nœud
    # -------------------------------------------------------------------------
    learn_pause \
        "Nous identifions l'adresse IP du nœud pour l'option --advertise-addr.\nCommande: ip -4 addr show scope global" \
        "We identify the node IP address for the --advertise-addr option.\nCommand: ip -4 addr show scope global"

    local NODE_IP
    NODE_IP=$(ip -4 addr show scope global | grep -oP '(?<=inet\s)\d+\.\d+\.\d+\.\d+' | head -1)

    if [[ -n "${NODE_IP}" ]]; then
        pass "Node IP detected: ${NODE_IP} / IP du nœud détectée: ${NODE_IP}"
    else
        fail "Could not detect node IP / Impossible de détecter l'IP du nœud" \
             "a valid IPv4 address" "empty" \
             "Vérifiez votre configuration réseau / Check your network configuration"
        section_summary
        return
    fi

    # -------------------------------------------------------------------------
    # Step 2: Initialize the Swarm
    # FR: Initialiser le Swarm sur le nœud contrôleur
    # -------------------------------------------------------------------------
    learn_pause \
        "Initialisation du cluster Swarm avec l'adresse IP détectée.\nCommande: docker swarm init --advertise-addr ${NODE_IP}\n\nCette commande fait de ce nœud le 'manager' (contrôleur) du cluster." \
        "Initializing the Swarm cluster with the detected IP address.\nCommand: docker swarm init --advertise-addr ${NODE_IP}\n\nThis command makes this node the 'manager' (controller) of the cluster."

    # Check if swarm is already active
    local swarm_state
    swarm_state=$(docker info --format '{{.Swarm.LocalNodeState}}' 2>/dev/null || echo "unknown")

    if [[ "${swarm_state}" == "active" ]]; then
        pass "Swarm already initialized — using existing cluster / Swarm déjà initialisé"
    else
        run_cmd "docker swarm init" "${TIMEOUT_DEFAULT}" \
            docker swarm init --advertise-addr "${NODE_IP}" || true

        if (( CMD_EXIT_CODE == 0 )); then
            pass "Swarm initialized successfully / Swarm initialisé avec succès"
        else
            fail "docker swarm init failed" \
                 "exit code 0" "exit code ${CMD_EXIT_CODE}" \
                 "Vérifiez que Docker fonctionne et que l'IP ${NODE_IP} est correcte"
            section_summary
            return
        fi
    fi

    # -------------------------------------------------------------------------
    # Step 3: Verify Swarm is active
    # FR: Vérifier que le Swarm est actif
    # -------------------------------------------------------------------------
    learn_pause \
        "Vérification que le Swarm est actif.\nCommande: docker info --format '{{.Swarm.LocalNodeState}}'" \
        "Verifying the Swarm is active.\nCommand: docker info --format '{{.Swarm.LocalNodeState}}'"

    assert_swarm_active

    # -------------------------------------------------------------------------
    # Step 4: Verify node is a manager
    # FR: Vérifier que le nœud est un gestionnaire (manager)
    # -------------------------------------------------------------------------
    learn_pause \
        "Vérification que ce nœud est un manager.\nCommande: docker node ls\n\nUn manager peut gérer le cluster et déployer des services.\nLe champ 'MANAGER STATUS' doit montrer 'Leader'." \
        "Verifying this node is a manager.\nCommand: docker node ls\n\nA manager can manage the cluster and deploy services.\nThe 'MANAGER STATUS' field should show 'Leader'."

    assert_node_is_manager

    assert_output_contains \
        "docker node ls shows Leader / docker node ls montre Leader" \
        "Leader" \
        "Ce nœud devrait être le Leader / This node should be the Leader" \
        docker node ls

    # -------------------------------------------------------------------------
    # Step 5: Display the worker join token
    # FR: Afficher le token d'adhésion worker
    # -------------------------------------------------------------------------
    learn_pause \
        "Récupération du token pour ajouter des workers au cluster.\nCommande: docker swarm join-token worker -q\n\nCe token permet à d'autres machines de rejoindre le cluster\nen tant que workers (nœuds de travail).\n\nNote: Dans ce lab, nous utilisons un seul nœud (manager)." \
        "Retrieving the token to add workers to the cluster.\nCommand: docker swarm join-token worker -q\n\nThis token allows other machines to join the cluster\nas workers.\n\nNote: In this lab, we use a single node (manager)."

    assert_output_not_empty \
        "Worker join token available / Token d'adhésion worker disponible" \
        "Essayez: docker swarm join-token worker -q" \
        docker swarm join-token worker -q

    section_summary
}
