#!/usr/bin/env bash
# =============================================================================
# CR380 - Lab 03 — Pile de base de données / Database Stack
# =============================================================================
#
# FR: Déployer la pile de base de données (MariaDB + Adminer) en tant que
#     stack Swarm. Couvre: IaC YAML, docker stack deploy, docker stack ps,
#     docker stack services, vérification HTTP.
#
# EN: Deploy the database stack (MariaDB + Adminer) as a Swarm stack.
#     Covers: IaC YAML, docker stack deploy, docker stack ps,
#     docker stack services, HTTP verification.
#
# Depends on: 02
#
# =============================================================================

run_test() {
    section_header "03" "Pile BD / Database Stack" \
        "${GITBOOK_URL_03}"

    check_dependency "02" || { section_summary; return; }

    local STACK_FILE="${STACK_DATABASE_FILE}"
    local STACK_NAME="${STACK_DATABASE_NAME}"

    # -------------------------------------------------------------------------
    # Step 1: Validate the stack YAML file
    # FR: Valider le fichier YAML de la pile
    # -------------------------------------------------------------------------
    learn_pause \
        "Nous validons d'abord le fichier de pile (stack).\nFichier: ${STACK_FILE}\n\nCe fichier définit l'Infrastructure as Code (IaC) pour:\n  • ${SVC_MARIADB} — Base de données (port ${PORT_MARIADB})\n  • ${SVC_ADMINER} — Interface web de gestion BD (port ${PORT_ADMINER})\n\nLes deux services partagent le réseau overlay '${SWARM_NETWORK_NAME}'." \
        "We first validate the stack file.\nFile: ${STACK_FILE}\n\nThis file defines the Infrastructure as Code (IaC) for:\n  • ${SVC_MARIADB} — Database (port ${PORT_MARIADB})\n  • ${SVC_ADMINER} — DB web management interface (port ${PORT_ADMINER})\n\nBoth services share the '${SWARM_NETWORK_NAME}' overlay network."

    if [[ ! -f "${STACK_FILE}" ]]; then
        fail "Stack file not found / Fichier de pile introuvable" \
             "${STACK_FILE}" "file missing" \
             "Vérifiez que le fichier existe dans stack-files/"
        section_summary
        return
    fi

    # Try docker stack config (Docker 25+), fall back to basic check
    if docker stack config -c "${STACK_FILE}" &>/dev/null 2>&1; then
        pass "Stack YAML validated (docker stack config) / YAML validé"
    else
        # Fallback: check for valid YAML with grep for key fields
        if grep -q "services:" "${STACK_FILE}" && grep -q "${SVC_MARIADB}" "${STACK_FILE}"; then
            pass "Stack YAML basic validation OK / Validation basique du YAML OK"
        else
            fail "Stack YAML validation failed" \
                 "valid stack file" "missing services section" \
                 "Vérifiez la syntaxe du fichier ${STACK_FILE}"
        fi
    fi

    # -------------------------------------------------------------------------
    # Step 2: Deploy the database stack
    # FR: Déployer la pile de base de données
    # -------------------------------------------------------------------------
    learn_pause \
        "Déploiement de la pile de base de données.\nCommande: docker stack deploy -c ${STACK_FILE} ${STACK_NAME}\n\nSwarm va télécharger les images et démarrer les services." \
        "Deploying the database stack.\nCommand: docker stack deploy -c ${STACK_FILE} ${STACK_NAME}\n\nSwarm will pull images and start the services."

    run_cmd "docker stack deploy database" "${TIMEOUT_PULL}" \
        docker stack deploy -c "${STACK_FILE}" "${STACK_NAME}" || true

    if (( CMD_EXIT_CODE == 0 )); then
        pass "Stack '${STACK_NAME}' deployed / Pile '${STACK_NAME}' déployée"
    else
        fail "docker stack deploy failed" \
             "exit code 0" "exit code ${CMD_EXIT_CODE}" \
             "Vérifiez que le Swarm est actif et que le réseau ${SWARM_NETWORK_NAME} existe"
        section_summary
        return
    fi

    # -------------------------------------------------------------------------
    # Step 3: Wait for services to converge
    # FR: Attendre que les services convergent
    # -------------------------------------------------------------------------
    learn_pause \
        "Attente de la convergence des services...\nSwarm télécharge les images et démarre les conteneurs.\nCela peut prendre un moment lors de la première exécution." \
        "Waiting for services to converge...\nSwarm pulls images and starts containers.\nThis may take a moment on first run."

    wait_for_stack_service "${STACK_NAME}" "${SVC_MARIADB}" 1 "${TIMEOUT_STACK_CONVERGE}"
    wait_for_stack_service "${STACK_NAME}" "${SVC_ADMINER}" 1 "${TIMEOUT_STACK_CONVERGE}"

    # -------------------------------------------------------------------------
    # Step 4: Verify stack tasks are running
    # FR: Vérifier que les tâches de la pile fonctionnent
    # -------------------------------------------------------------------------
    learn_pause \
        "Vérifions les tâches de la pile.\nCommande: docker stack ps ${STACK_NAME}\n\nChaque service crée une ou plusieurs 'tâches' (tasks).\nL'état doit être 'Running'." \
        "Let's check the stack tasks.\nCommand: docker stack ps ${STACK_NAME}\n\nEach service creates one or more 'tasks'.\nThe state should be 'Running'."

    assert_output_contains \
        "Stack tasks show Running / Tâches de la pile en exécution" \
        "Running" \
        "Les tâches devraient être en état Running" \
        docker stack ps "${STACK_NAME}" --format '{{.CurrentState}}'

    # -------------------------------------------------------------------------
    # Step 5: Verify stack services
    # FR: Vérifier les services de la pile
    # -------------------------------------------------------------------------
    learn_pause \
        "Listons les services de la pile.\nCommande: docker stack services ${STACK_NAME}\n\nVous devriez voir 2 services: ${SVC_MARIADB} et ${SVC_ADMINER}.\nLa colonne REPLICAS montre le nombre d'instances." \
        "Let's list the stack services.\nCommand: docker stack services ${STACK_NAME}\n\nYou should see 2 services: ${SVC_MARIADB} and ${SVC_ADMINER}.\nThe REPLICAS column shows the instance count."

    assert_stack_exists "${STACK_NAME}"

    assert_output_contains \
        "Service ${SVC_MARIADB} in stack / Service ${SVC_MARIADB} dans la pile" \
        "${SVC_MARIADB}" \
        "Le service ${SVC_MARIADB} devrait apparaître" \
        docker stack services "${STACK_NAME}" --format '{{.Name}}'

    assert_output_contains \
        "Service ${SVC_ADMINER} in stack / Service ${SVC_ADMINER} dans la pile" \
        "${SVC_ADMINER}" \
        "Le service ${SVC_ADMINER} devrait apparaître" \
        docker stack services "${STACK_NAME}" --format '{{.Name}}'

    # -------------------------------------------------------------------------
    # Step 6: Verify replicas
    # FR: Vérifier le nombre de répliques
    # -------------------------------------------------------------------------
    assert_stack_service_replicas "${STACK_NAME}" "${SVC_MARIADB}" 1
    assert_stack_service_replicas "${STACK_NAME}" "${SVC_ADMINER}" 1

    # -------------------------------------------------------------------------
    # Step 7: HTTP check — Adminer
    # FR: Vérification HTTP — Adminer
    # -------------------------------------------------------------------------
    learn_pause \
        "Vérifions que Adminer est accessible via HTTP.\nCommande: curl -s http://localhost:${PORT_ADMINER}\n\nAdminer est une interface web de gestion de base de données." \
        "Let's verify Adminer is accessible via HTTP.\nCommand: curl -s http://localhost:${PORT_ADMINER}\n\nAdminer is a web-based database management interface."

    # Give Adminer a moment to start
    sleep 5
    assert_http_reachable "http://localhost:${PORT_ADMINER}" 200

    # -------------------------------------------------------------------------
    # Step 8: Find containers with docker ps
    # FR: Repérer les conteneurs avec docker ps
    # -------------------------------------------------------------------------
    learn_pause \
        "Repérons les conteneurs en cours d'exécution.\nCommande: docker ps\n\nVous devriez voir les conteneurs de la pile ${STACK_NAME}.\nLe nom du conteneur est préfixé par le nom de la pile." \
        "Let's find the running containers.\nCommand: docker ps\n\nYou should see the ${STACK_NAME} stack containers.\nThe container name is prefixed with the stack name."

    assert_output_contains \
        "docker ps shows ${STACK_NAME} containers" \
        "${STACK_NAME}" \
        "Les conteneurs de la pile devraient apparaître dans docker ps" \
        docker ps --format '{{.Names}}'

    section_summary
}
