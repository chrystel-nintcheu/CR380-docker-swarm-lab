#!/usr/bin/env bash
# =============================================================================
# CR380 - Lab 99 — Mettre fin / Teardown
# =============================================================================
#
# FR: Nettoyer toutes les ressources Swarm créées pendant les labs.
#     Couvre: docker stack rm, docker network rm, docker swarm leave,
#     docker system prune (optionnel).
#
# EN: Clean up all Swarm resources created during the labs.
#     Covers: docker stack rm, docker network rm, docker swarm leave,
#     docker system prune (optional).
#
# Depends on: 04
#
# =============================================================================

run_test() {
    section_header "99" "Mettre fin / Teardown" \
        "${GITBOOK_URL_99}"

    check_dependency "04" || { section_summary; return; }

    local DB_STACK="${STACK_DATABASE_NAME}"
    local WEB_STACK="${STACK_DRUPAL_NAME}"

    # -------------------------------------------------------------------------
    # Step 1: Remove the Drupal stack
    # FR: Supprimer la pile Drupal
    # -------------------------------------------------------------------------
    learn_pause \
        "Nettoyons l'environnement en supprimant les piles.\nCommande: docker stack rm ${WEB_STACK}\n\nL'ordre est important: on retire d'abord la pile applicative." \
        "Let's clean up by removing the stacks.\nCommand: docker stack rm ${WEB_STACK}\n\nOrder matters: remove the application stack first."

    cleanup_stack "${WEB_STACK}"

    # Wait for stack resources to be fully removed
    sleep 5

    assert_stack_not_exists "${WEB_STACK}"

    # -------------------------------------------------------------------------
    # Step 2: Remove the database stack
    # FR: Supprimer la pile database
    # -------------------------------------------------------------------------
    learn_pause \
        "Supprimons la pile base de données.\nCommande: docker stack rm ${DB_STACK}" \
        "Let's remove the database stack.\nCommand: docker stack rm ${DB_STACK}"

    cleanup_stack "${DB_STACK}"

    sleep 5

    assert_stack_not_exists "${DB_STACK}"

    # -------------------------------------------------------------------------
    # Step 3: Remove the overlay network
    # FR: Supprimer le réseau overlay
    # -------------------------------------------------------------------------
    learn_pause \
        "Supprimons le réseau overlay.\nCommande: docker network rm ${SWARM_NETWORK_NAME}\n\nLe réseau doit être retiré après les piles qui l'utilisent." \
        "Let's remove the overlay network.\nCommand: docker network rm ${SWARM_NETWORK_NAME}\n\nThe network must be removed after the stacks that use it."

    cleanup_network "${SWARM_NETWORK_NAME}"
    assert_network_not_exists "${SWARM_NETWORK_NAME}"

    # -------------------------------------------------------------------------
    # Step 4: Leave the Swarm
    # FR: Quitter le Swarm
    # -------------------------------------------------------------------------
    learn_pause \
        "Quittons le Swarm.\nCommande: docker swarm leave --force\n\nLe flag --force est nécessaire car c'est le seul nœud manager." \
        "Let's leave the Swarm.\nCommand: docker swarm leave --force\n\nThe --force flag is needed since this is the only manager node."

    cleanup_swarm
    assert_swarm_inactive

    # -------------------------------------------------------------------------
    # Step 5: Optional prune (informational)
    # FR: Nettoyage optionnel (informatif)
    # -------------------------------------------------------------------------
    learn_pause \
        "Pour un nettoyage complet, vous pouvez exécuter:\n  docker system prune -a --volumes\n\nCette commande supprime:\n  • Conteneurs arrêtés\n  • Réseaux non utilisés\n  • Images inutilisées\n  • Volumes non référencés\n\nNous ne l'exécutons pas automatiquement pour éviter\nde supprimer des données d'autres projets." \
        "For a complete cleanup, you can run:\n  docker system prune -a --volumes\n\nThis command removes:\n  • Stopped containers\n  • Unused networks\n  • Unused images\n  • Unreferenced volumes\n\nWe don't run it automatically to avoid\nremoving data from other projects."

    pass "Teardown complete / Nettoyage terminé" \
         "All Swarm resources have been removed / Toutes les ressources Swarm ont été supprimées"

    section_summary
}
