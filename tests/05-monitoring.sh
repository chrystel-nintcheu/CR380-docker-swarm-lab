#!/usr/bin/env bash
# =============================================================================
# CR380 - Lab 05 — Surveillance / Monitoring
# =============================================================================
#
# FR: Surveiller l'état du cluster Swarm et des stacks déployés.
#     Couvre: docker stack ls, docker stack ps, docker service ls,
#     docker node ls, docker node ps.
#
# EN: Monitor the Swarm cluster state and deployed stacks.
#     Covers: docker stack ls, docker stack ps, docker service ls,
#     docker node ls, docker node ps.
#
# Depends on: 04
#
# =============================================================================

run_test() {
    section_header "05" "Surveillance / Monitoring" \
        "${GITBOOK_URL_05}"

    check_dependency "04" || { section_summary; return; }

    local DB_STACK="${STACK_DATABASE_NAME}"
    local WEB_STACK="${STACK_DRUPAL_NAME}"

    # -------------------------------------------------------------------------
    # Step 1: docker stack ls — List all stacks
    # FR: Lister toutes les piles déployées
    # -------------------------------------------------------------------------
    learn_pause \
        "Vérifions les piles déployées dans le cluster.\nCommande: docker stack ls\n\nVous devriez voir deux piles: '${DB_STACK}' et '${WEB_STACK}'." \
        "Let's check the stacks deployed in the cluster.\nCommand: docker stack ls\n\nYou should see two stacks: '${DB_STACK}' and '${WEB_STACK}'."

    run_cmd "docker stack ls" "${TIMEOUT_DEFAULT}" \
        docker stack ls

    if (( CMD_EXIT_CODE == 0 )); then
        pass "docker stack ls succeeded"
    else
        fail "docker stack ls" "exit 0" "exit ${CMD_EXIT_CODE}" \
             "Le Swarm devrait être actif avec des piles déployées."
    fi

    assert_output_contains \
        "Stack '${DB_STACK}' visible in stack ls" \
        "${DB_STACK}" \
        "La pile ${DB_STACK} devrait apparaître dans la liste" \
        docker stack ls

    assert_output_contains \
        "Stack '${WEB_STACK}' visible in stack ls" \
        "${WEB_STACK}" \
        "La pile ${WEB_STACK} devrait apparaître dans la liste" \
        docker stack ls

    # -------------------------------------------------------------------------
    # Step 2: docker stack ps — Inspect tasks per stack
    # FR: Inspecter les tâches par pile
    # -------------------------------------------------------------------------
    learn_pause \
        "Inspectons les tâches de chaque pile.\nCommande: docker stack ps <stack_name>\n\nCela montre l'état de chaque réplique de chaque service." \
        "Let's inspect the tasks for each stack.\nCommand: docker stack ps <stack_name>\n\nThis shows the state of each replica of each service."

    for stack in "${DB_STACK}" "${WEB_STACK}"; do
        assert_output_contains \
            "Stack '${stack}' has Running tasks" \
            "Running" \
            "Les tâches de la pile ${stack} devraient être Running" \
            docker stack ps "${stack}" --format '{{.CurrentState}}'
    done

    # -------------------------------------------------------------------------
    # Step 3: docker service ls — List all services
    # FR: Lister tous les services
    # -------------------------------------------------------------------------
    learn_pause \
        "Affichons la liste de tous les services Swarm.\nCommande: docker service ls\n\nChaque service montre le nombre de répliques actives." \
        "Let's list all Swarm services.\nCommand: docker service ls\n\nEach service shows the number of active replicas."

    run_cmd "docker service ls" "${TIMEOUT_DEFAULT}" \
        docker service ls

    for svc in "${SVC_MARIADB}" "${SVC_ADMINER}" "${SVC_DRUPAL}"; do
        assert_output_contains \
            "Service '${svc}' visible in service ls" \
            "${svc}" \
            "Le service ${svc} devrait apparaître" \
            docker service ls
    done

    # -------------------------------------------------------------------------
    # Step 4: docker node ls — Cluster nodes
    # FR: Nœuds du cluster
    # -------------------------------------------------------------------------
    learn_pause \
        "Vérifions les nœuds du cluster.\nCommande: docker node ls\n\nDans notre lab mono-nœud, un seul nœud (Leader) apparaît." \
        "Let's check the cluster nodes.\nCommand: docker node ls\n\nIn our single-node lab, one node (Leader) should appear."

    assert_output_contains \
        "Node is Leader" \
        "Leader" \
        "Le nœud devrait avoir le statut Leader" \
        docker node ls

    # -------------------------------------------------------------------------
    # Step 5: docker node ps — Tasks running on this node
    # FR: Tâches exécutées sur ce nœud
    # -------------------------------------------------------------------------
    learn_pause \
        "Inspectons les tâches sur le nœud courant.\nCommande: docker node ps\n\nToutes les tâches devraient être affichées car nous n'avons\nqu'un seul nœud." \
        "Let's inspect the tasks on the current node.\nCommand: docker node ps\n\nAll tasks should appear since we have only one node."

    run_cmd "docker node ps" "${TIMEOUT_DEFAULT}" \
        docker node ps

    if (( CMD_EXIT_CODE == 0 )); then
        pass "docker node ps succeeded"
    else
        fail "docker node ps" "exit 0" "exit ${CMD_EXIT_CODE}" \
             "Le nœud devrait être accessible"
    fi

    section_summary
}
