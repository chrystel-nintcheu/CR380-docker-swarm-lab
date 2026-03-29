#!/usr/bin/env bash
# =============================================================================
# CR380 - Lab 06 — Élasticité horizontale / Horizontal Scaling
# =============================================================================
#
# FR: Expérimenter la mise à l'échelle horizontale des services Swarm.
#     Couvre: docker service scale (scale-out, scale-in, restore).
#
# EN: Experiment with horizontal scaling of Swarm services.
#     Covers: docker service scale (scale-out, scale-in, restore).
#
# Depends on: 05
#
# =============================================================================

run_test() {
    section_header "06" "Élasticité horizontale / Horizontal Scaling" \
        "${GITBOOK_URL_06}"

    check_dependency "05" || { section_summary; return; }

    local FULL_SVC="${STACK_DRUPAL_NAME}_${SVC_DRUPAL}"

    # -------------------------------------------------------------------------
    # Step 1: Verify baseline replicas
    # FR: Vérifier le nombre initial de répliques
    # -------------------------------------------------------------------------
    learn_pause \
        "Avant de mettre à l'échelle, vérifions l'état actuel.\nService: ${FULL_SVC}\nRépliques attendues: ${SCALE_DEFAULT_REPLICAS}" \
        "Before scaling, let's verify the current state.\nService: ${FULL_SVC}\nExpected replicas: ${SCALE_DEFAULT_REPLICAS}"

    assert_stack_service_replicas "${STACK_DRUPAL_NAME}" "${SVC_DRUPAL}" "${SCALE_DEFAULT_REPLICAS}"

    # -------------------------------------------------------------------------
    # Step 2: Scale OUT to N replicas
    # FR: Mise à l'échelle horizontale (scale-out)
    # -------------------------------------------------------------------------
    learn_pause \
        "Passons à ${SCALE_OUT_REPLICAS} répliques (scale-out).\nCommande: docker service scale ${FULL_SVC}=${SCALE_OUT_REPLICAS}\n\nSwarm va créer de nouvelles tâches pour atteindre\nle nombre souhaité de répliques." \
        "Let's scale out to ${SCALE_OUT_REPLICAS} replicas.\nCommand: docker service scale ${FULL_SVC}=${SCALE_OUT_REPLICAS}\n\nSwarm will create new tasks to reach\nthe desired replica count."

    run_cmd "scale out to ${SCALE_OUT_REPLICAS}" "${TIMEOUT_STACK_CONVERGE}" \
        docker service scale "${FULL_SVC}=${SCALE_OUT_REPLICAS}"

    if (( CMD_EXIT_CODE == 0 )); then
        pass "Scale-out command succeeded (${SCALE_OUT_REPLICAS} replicas)"
    else
        fail "docker service scale out" \
             "exit 0" "exit ${CMD_EXIT_CODE}" \
             "Vérifiez que le service ${FULL_SVC} existe"
        section_summary
        return
    fi

    # Wait for convergence
    wait_for_stack_service "${STACK_DRUPAL_NAME}" "${SVC_DRUPAL}" "${SCALE_OUT_REPLICAS}" "${TIMEOUT_STACK_CONVERGE}"
    assert_stack_service_replicas "${STACK_DRUPAL_NAME}" "${SVC_DRUPAL}" "${SCALE_OUT_REPLICAS}"

    learn_pause \
        "Observons les ${SCALE_OUT_REPLICAS} tâches en cours.\nCommande: docker service ps ${FULL_SVC}" \
        "Let's observe the ${SCALE_OUT_REPLICAS} running tasks.\nCommand: docker service ps ${FULL_SVC}"

    run_cmd "docker service ps (scale-out)" "${TIMEOUT_DEFAULT}" \
        docker service ps "${FULL_SVC}"

    # -------------------------------------------------------------------------
    # Step 3: Scale IN to fewer replicas
    # FR: Réduction (scale-in)
    # -------------------------------------------------------------------------
    learn_pause \
        "Réduisons à ${SCALE_IN_REPLICAS} répliques (scale-in).\nCommande: docker service scale ${FULL_SVC}=${SCALE_IN_REPLICAS}\n\nSwarm va arrêter les tâches excédentaires." \
        "Let's scale in to ${SCALE_IN_REPLICAS} replicas.\nCommand: docker service scale ${FULL_SVC}=${SCALE_IN_REPLICAS}\n\nSwarm will stop the excess tasks."

    run_cmd "scale in to ${SCALE_IN_REPLICAS}" "${TIMEOUT_STACK_CONVERGE}" \
        docker service scale "${FULL_SVC}=${SCALE_IN_REPLICAS}"

    if (( CMD_EXIT_CODE == 0 )); then
        pass "Scale-in command succeeded (${SCALE_IN_REPLICAS} replicas)"
    else
        fail "docker service scale in" \
             "exit 0" "exit ${CMD_EXIT_CODE}" ""
    fi

    wait_for_stack_service "${STACK_DRUPAL_NAME}" "${SVC_DRUPAL}" "${SCALE_IN_REPLICAS}" "${TIMEOUT_STACK_CONVERGE}"
    assert_stack_service_replicas "${STACK_DRUPAL_NAME}" "${SVC_DRUPAL}" "${SCALE_IN_REPLICAS}"

    # -------------------------------------------------------------------------
    # Step 4: Restore to default
    # FR: Restaurer la valeur par défaut
    # -------------------------------------------------------------------------
    learn_pause \
        "Restaurons à ${SCALE_DEFAULT_REPLICAS} réplique(s).\nCommande: docker service scale ${FULL_SVC}=${SCALE_DEFAULT_REPLICAS}" \
        "Let's restore to ${SCALE_DEFAULT_REPLICAS} replica(s).\nCommand: docker service scale ${FULL_SVC}=${SCALE_DEFAULT_REPLICAS}"

    run_cmd "restore to ${SCALE_DEFAULT_REPLICAS}" "${TIMEOUT_STACK_CONVERGE}" \
        docker service scale "${FULL_SVC}=${SCALE_DEFAULT_REPLICAS}"

    if (( CMD_EXIT_CODE == 0 )); then
        pass "Restore command succeeded (${SCALE_DEFAULT_REPLICAS} replica)"
    else
        fail "docker service scale restore" \
             "exit 0" "exit ${CMD_EXIT_CODE}" ""
    fi

    wait_for_stack_service "${STACK_DRUPAL_NAME}" "${SVC_DRUPAL}" "${SCALE_DEFAULT_REPLICAS}" "${TIMEOUT_STACK_CONVERGE}"
    assert_stack_service_replicas "${STACK_DRUPAL_NAME}" "${SVC_DRUPAL}" "${SCALE_DEFAULT_REPLICAS}"

    section_summary
}
