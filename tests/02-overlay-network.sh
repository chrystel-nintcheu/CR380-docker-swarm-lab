#!/usr/bin/env bash
# =============================================================================
# CR380 - Lab 02 — Réseau overlay / Overlay Network
# =============================================================================
#
# FR: Créer un réseau overlay Swarm-scoped pour la communication inter-services.
#     Couvre: docker network create -d overlay, inspection du réseau.
#
# EN: Create a Swarm-scoped overlay network for inter-service communication.
#     Covers: docker network create -d overlay, network inspection.
#
# Depends on: 01
#
# =============================================================================

run_test() {
    section_header "02" "Réseau overlay / Overlay Network" \
        "${GITBOOK_URL_02}"

    check_dependency "01" || { section_summary; return; }

    # -------------------------------------------------------------------------
    # Step 1: Create the overlay network
    # FR: Créer le réseau overlay scalenet
    # -------------------------------------------------------------------------
    learn_pause \
        "Création d'un réseau overlay pour le cluster Swarm.\nCommande: docker network create -d overlay ${SWARM_NETWORK_NAME}\n\nLe pilote (driver) 'overlay' permet la communication\nentre les conteneurs répartis sur plusieurs nœuds.\nLe nom '${SWARM_NETWORK_NAME}' sera utilisé par toutes les piles de services." \
        "Creating an overlay network for the Swarm cluster.\nCommand: docker network create -d overlay ${SWARM_NETWORK_NAME}\n\nThe 'overlay' driver enables communication\nbetween containers spread across multiple nodes.\nThe name '${SWARM_NETWORK_NAME}' will be used by all service stacks."

    # Check if network already exists
    if docker network inspect "${SWARM_NETWORK_NAME}" &>/dev/null; then
        pass "Network '${SWARM_NETWORK_NAME}' already exists / Réseau déjà existant"
    else
        run_cmd "docker network create overlay" "${TIMEOUT_DEFAULT}" \
            docker network create -d "${SWARM_NETWORK_DRIVER}" "${SWARM_NETWORK_NAME}" || true

        if (( CMD_EXIT_CODE == 0 )); then
            pass "Network '${SWARM_NETWORK_NAME}' created / Réseau créé"
        else
            fail "Failed to create network '${SWARM_NETWORK_NAME}'" \
                 "exit code 0" "exit code ${CMD_EXIT_CODE}" \
                 "Vérifiez que le Swarm est actif: docker info | grep Swarm"
            section_summary
            return
        fi
    fi

    # -------------------------------------------------------------------------
    # Step 2: Verify the network exists
    # FR: Vérifier que le réseau existe
    # -------------------------------------------------------------------------
    learn_pause \
        "Vérifions que le réseau a été créé.\nCommande: docker network ls" \
        "Let's verify the network was created.\nCommand: docker network ls"

    assert_network_exists "${SWARM_NETWORK_NAME}"

    # -------------------------------------------------------------------------
    # Step 3: Verify the network driver is overlay
    # FR: Vérifier que le pilote est overlay
    # -------------------------------------------------------------------------
    learn_pause \
        "Inspectons le réseau pour confirmer le pilote overlay.\nCommande: docker network inspect ${SWARM_NETWORK_NAME}\n\nLe champ 'Driver' doit afficher 'overlay'.\nLe champ 'Scope' doit afficher 'swarm'." \
        "Let's inspect the network to confirm the overlay driver.\nCommand: docker network inspect ${SWARM_NETWORK_NAME}\n\nThe 'Driver' field should show 'overlay'.\nThe 'Scope' field should show 'swarm'."

    assert_output_contains \
        "Network driver is overlay / Pilote réseau est overlay" \
        "overlay" \
        "Le réseau devrait utiliser le pilote overlay" \
        docker network inspect --format '{{.Driver}}' "${SWARM_NETWORK_NAME}"

    assert_output_contains \
        "Network scope is swarm / Portée du réseau est swarm" \
        "swarm" \
        "Le réseau devrait avoir la portée 'swarm'" \
        docker network inspect --format '{{.Scope}}' "${SWARM_NETWORK_NAME}"

    # -------------------------------------------------------------------------
    # Step 4: List all networks
    # FR: Lister tous les réseaux
    # -------------------------------------------------------------------------
    learn_pause \
        "Listons tous les réseaux Docker pour voir notre réseau overlay.\nCommande: docker network ls\n\nVous devriez voir '${SWARM_NETWORK_NAME}' avec le driver 'overlay'." \
        "Let's list all Docker networks to see our overlay network.\nCommand: docker network ls\n\nYou should see '${SWARM_NETWORK_NAME}' with the 'overlay' driver."

    assert_output_contains \
        "docker network ls shows ${SWARM_NETWORK_NAME}" \
        "${SWARM_NETWORK_NAME}" \
        "Le réseau ${SWARM_NETWORK_NAME} devrait apparaître dans la liste" \
        docker network ls

    section_summary
}
