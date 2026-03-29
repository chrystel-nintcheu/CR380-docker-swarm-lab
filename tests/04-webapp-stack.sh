#!/usr/bin/env bash
# =============================================================================
# CR380 - Lab 04 — Pile WEBAPP / Web App Stack (Drupal)
# =============================================================================
#
# FR: Déployer la pile application web (Drupal) en tant que stack Swarm.
#     Couvre: docker stack deploy, découverte DNS interne Swarm,
#     connexion entre piles via le réseau overlay.
#
# EN: Deploy the web application stack (Drupal) as a Swarm stack.
#     Covers: docker stack deploy, Swarm internal DNS discovery,
#     cross-stack communication via overlay network.
#
# Depends on: 03
#
# =============================================================================

run_test() {
    section_header "04" "Pile WEBAPP / Web App Stack" \
        "${GITBOOK_URL_04}"

    check_dependency "03" || { section_summary; return; }

    local STACK_FILE="${STACK_DRUPAL_FILE}"
    local STACK_NAME="${STACK_DRUPAL_NAME}"

    # -------------------------------------------------------------------------
    # Step 1: Validate the stack YAML file
    # FR: Valider le fichier YAML de la pile
    # -------------------------------------------------------------------------
    learn_pause \
        "Validons le fichier de pile Drupal.\nFichier: ${STACK_FILE}\n\nCe fichier définit:\n  • ${SVC_DRUPAL} — CMS Drupal (port ${PORT_DRUPAL})\n    avec 1 réplique initiale\n\nLe service utilise le réseau overlay '${SWARM_NETWORK_NAME}'\npartagé avec la pile database." \
        "Let's validate the Drupal stack file.\nFile: ${STACK_FILE}\n\nThis file defines:\n  • ${SVC_DRUPAL} — Drupal CMS (port ${PORT_DRUPAL})\n    with 1 initial replica\n\nThe service uses the '${SWARM_NETWORK_NAME}' overlay network\nshared with the database stack."

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
        if grep -q "services:" "${STACK_FILE}" && grep -q "${SVC_DRUPAL}" "${STACK_FILE}"; then
            pass "Stack YAML basic validation OK / Validation basique du YAML OK"
        else
            fail "Stack YAML validation failed" \
                 "valid stack file" "missing services section" \
                 "Vérifiez la syntaxe du fichier ${STACK_FILE}"
        fi
    fi

    # -------------------------------------------------------------------------
    # Step 2: Deploy the Drupal stack
    # FR: Déployer la pile Drupal
    # -------------------------------------------------------------------------
    learn_pause \
        "Déploiement de la pile Drupal.\nCommande: docker stack deploy -c ${STACK_FILE} ${STACK_NAME}\n\nLors de l'installation du site Drupal, renseignez comme\nnom d'hôte de la base de données le nom du service: '${SVC_MARIADB}'." \
        "Deploying the Drupal stack.\nCommand: docker stack deploy -c ${STACK_FILE} ${STACK_NAME}\n\nWhen installing the Drupal site, use the database\nservice name as the host: '${SVC_MARIADB}'."

    run_cmd "docker stack deploy drupalsite" "${TIMEOUT_PULL}" \
        docker stack deploy -c "${STACK_FILE}" "${STACK_NAME}" || true

    if (( CMD_EXIT_CODE == 0 )); then
        pass "Stack '${STACK_NAME}' deployed / Pile '${STACK_NAME}' déployée"
    else
        fail "docker stack deploy failed" \
             "exit code 0" "exit code ${CMD_EXIT_CODE}" \
             "Vérifiez que le réseau ${SWARM_NETWORK_NAME} existe: docker network ls"
        section_summary
        return
    fi

    # -------------------------------------------------------------------------
    # Step 3: Wait for the service to converge
    # FR: Attendre la convergence du service
    # -------------------------------------------------------------------------
    learn_pause \
        "Attente de la convergence du service Drupal...\nDrupal peut prendre plus de temps car l'image est volumineuse." \
        "Waiting for the Drupal service to converge...\nDrupal may take longer as the image is large."

    wait_for_stack_service "${STACK_NAME}" "${SVC_DRUPAL}" 1 "${TIMEOUT_STACK_CONVERGE}"

    # -------------------------------------------------------------------------
    # Step 4: Verify stack service is running
    # FR: Vérifier que le service fonctionne
    # -------------------------------------------------------------------------
    assert_stack_exists "${STACK_NAME}"
    assert_stack_service_replicas "${STACK_NAME}" "${SVC_DRUPAL}" 1

    assert_output_contains \
        "Stack tasks show Running / Tâches en exécution" \
        "Running" \
        "Les tâches devraient être en état Running" \
        docker stack ps "${STACK_NAME}" --format '{{.CurrentState}}'

    # -------------------------------------------------------------------------
    # Step 5: HTTP check — Drupal
    # FR: Vérification HTTP — Drupal
    # -------------------------------------------------------------------------
    learn_pause \
        "Vérifions que Drupal est accessible via HTTP.\nCommande: curl -s http://localhost:${PORT_DRUPAL}\n\nDrupal peut répondre avec un code 200 ou 302 (redirection\nvers la page d'installation)." \
        "Let's verify Drupal is accessible via HTTP.\nCommand: curl -s http://localhost:${PORT_DRUPAL}\n\nDrupal may respond with a 200 or 302 (redirect\nto installation page)."

    # Give Drupal a moment to start
    sleep 10

    local drupal_code
    drupal_code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 15 "http://localhost:${PORT_DRUPAL}" 2>/dev/null) || drupal_code="000"
    if [[ "${drupal_code}" =~ ^(200|302|303)$ ]]; then
        pass "Drupal responds (HTTP ${drupal_code}) on port ${PORT_DRUPAL}"
    else
        fail "Drupal HTTP check" \
             "HTTP 200/302/303" "HTTP ${drupal_code}" \
             "Drupal peut prendre du temps à démarrer. Attendez et réessayez."
    fi

    # -------------------------------------------------------------------------
    # Step 6: DNS test — ping mariadb from Drupal container
    # FR: Test DNS — ping mariadb depuis le conteneur Drupal
    # -------------------------------------------------------------------------
    learn_pause \
        "Testons la découverte de services DNS interne de Swarm.\nSwarm fournit un DNS interne pour les conteneurs,\nfacilitant la communication entre les services.\n\nDepuis le conteneur Drupal, nous pouvons résoudre 'mariadb'\npar son nom de service.\n\nRAPPEL: C'est pourquoi lors de la configuration Drupal,\non utilise 'mariadb' comme hôte de la base de données." \
        "Let's test Swarm's internal DNS service discovery.\nSwarm provides an internal DNS for containers,\nfacilitating communication between services.\n\nFrom the Drupal container, we can resolve 'mariadb'\nby its service name.\n\nREMINDER: This is why during Drupal configuration,\nwe use 'mariadb' as the database host."

    # Find the drupal container name (swarm names: <stack>_<service>.<slot>.<id>)
    local drupal_container
    drupal_container=$(docker ps --filter "name=${STACK_NAME}_${SVC_DRUPAL}" --format '{{.Names}}' | head -1)

    if [[ -n "${drupal_container}" ]]; then
        # Install ping if not available, then test DNS
        docker exec "${drupal_container}" bash -c \
            "command -v ping >/dev/null || (apt-get update -qq && apt-get install -y -qq iputils-ping >/dev/null 2>&1)" \
            2>/dev/null || true

        assert_success \
            "DNS: Drupal can resolve ${SVC_MARIADB} / Résolution DNS ${SVC_MARIADB}" \
            "Les services devraient communiquer via le réseau ${SWARM_NETWORK_NAME}" \
            docker exec "${drupal_container}" ping -c 2 -W 5 "${SVC_MARIADB}"
    else
        skip "Could not find Drupal container for DNS test" \
             "Le conteneur Drupal n'a pas été trouvé — le service n'a peut-être pas convergé"
    fi

    section_summary
}
