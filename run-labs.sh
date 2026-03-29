#!/usr/bin/env bash
# =============================================================================
# CR380 - Docker Swarm Lab Test Suite — Master Runner / Lanceur principal
# =============================================================================
#
# FR: Script principal qui orchestre l'exécution de tous les tests de lab.
#     Supporte plusieurs modes d'exécution pour enseignants et étudiants.
#
# EN: Main script that orchestrates the execution of all lab tests.
#     Supports multiple execution modes for teachers and students.
#
# Usage:
#   sudo ./run-labs.sh                    # Default: validate mode (teacher)
#   sudo ./run-labs.sh --validate         # Same as default
#   sudo ./run-labs.sh --learn            # Student mode: interactive, with pauses
#   sudo ./run-labs.sh --lab 06           # Run only lab 06
#   sudo ./run-labs.sh --reset 05         # Cleanup + rerun lab 05
#   sudo ./run-labs.sh --quick            # Skip preflight if swarm already active
#   sudo ./run-labs.sh --diff             # Compare last two reports
#   sudo ./run-labs.sh --verbose          # Show full command output
#   sudo ./run-labs.sh --learn --lab 02   # Combine: learn mode on lab 02 only
#
# =============================================================================

# Resolve paths
RUNNER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TESTS_DIR="${RUNNER_DIR}/tests"

# =============================================================================
# PARSE ARGUMENTS / ANALYSE DES ARGUMENTS
# =============================================================================

# Defaults
export MODE="validate"
export VERBOSE=1
RUN_LAB=""
RESET_LAB=""
QUICK_MODE=false
DIFF_ONLY=false

usage() {
    cat <<'USAGE'
CR380 - Docker Swarm Lab Test Suite

Usage: sudo ./run-labs.sh [OPTIONS]

Modes:
  --validate        Mode enseignant (défaut): exécution rapide, résumé à la fin
                    Teacher mode (default): fast execution, summary at end
  --learn           Mode étudiant: explications bilingues, pause entre les étapes
                    Student mode: bilingual explanations, pause between steps

Options:
  --lab NN          Exécuter uniquement le lab NN / Run only lab NN
  --reset NN        Nettoyer puis réexécuter le lab NN / Clean then rerun lab NN
  --quick           Sauter preflight si Swarm actif / Skip preflight if Swarm active
  --diff            Comparer les 2 derniers rapports / Compare last 2 reports
  --verbose         Afficher toutes les sorties / Show all output
  --help            Afficher cette aide / Show this help

Examples:
  sudo ./run-labs.sh --learn              # Tutoriel interactif / Interactive tutorial
  sudo ./run-labs.sh --validate           # Validation rapide / Quick validation
  sudo ./run-labs.sh --learn --lab 02     # Lab 02 en mode apprentissage / Lab 02 in learn mode
  sudo ./run-labs.sh --reset 99           # Tout nettoyer / Full cleanup
USAGE
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --validate)  MODE="validate"; shift ;;
        --learn)     MODE="learn"; shift ;;
        --lab)       RUN_LAB="$2"; shift 2 ;;
        --reset)     RESET_LAB="$2"; shift 2 ;;
        --quick)     QUICK_MODE=true; shift ;;
        --diff)      DIFF_ONLY=true; shift ;;
        --verbose)   VERBOSE=2; shift ;;
        --help|-h)   usage ;;
        *)           echo "Unknown option: $1"; usage ;;
    esac
done

# =============================================================================
# SOURCE FRAMEWORK / CHARGER LE FRAMEWORK
# =============================================================================

source "${TESTS_DIR}/_common.sh"

# =============================================================================
# HANDLE --diff / GÉRER --diff
# =============================================================================

if [[ "${DIFF_ONLY}" == "true" ]]; then
    diff_reports
    exit 0
fi

# =============================================================================
# BANNER / BANNIÈRE
# =============================================================================

echo ""
echo -e "${BOLD}${BLUE}"
echo "  ╔══════════════════════════════════════════════════════════╗"
echo "  ║                                                          ║"
echo "  ║   CR380 — Docker Swarm Lab                               ║"
echo "  ║   Orchestration et mise à l'échelle / Orchestration      ║"
echo "  ║   Suite de tests automatisés / Automated Test Suite       ║"
echo "  ║                                                          ║"
echo "  ╚══════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "  ${DIM}Mode     : ${MODE}${NC}"
echo -e "  ${DIM}Date     : $(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo -e "  ${DIM}Log      : ${LOG_FILE}${NC}"
echo -e "  ${DIM}Lab      : ${RUN_LAB:-all}${NC}"
echo -e "  ${DIM}Reset    : ${RESET_LAB:-none}${NC}"

log "=========================================="
log "CR380 Docker Swarm Lab Test Suite"
log "Mode: ${MODE}"
log "Lab: ${RUN_LAB:-all}"
log "Reset: ${RESET_LAB:-none}"
log "=========================================="

# =============================================================================
# DEFINE TEST ORDER / DÉFINIR L'ORDRE DES TESTS
# =============================================================================

# FR: Liste ordonnée de tous les scripts de test
# EN: Ordered list of all test scripts
ALL_TESTS=(
    "00-preflight.sh"
    "01-swarm-init.sh"
    "02-overlay-network.sh"
    "03-database-stack.sh"
    "04-webapp-stack.sh"
    "05-monitoring.sh"
    "06-horizontal-scaling.sh"
    "99-teardown.sh"
)

# Quick mode: skip preflight/init if swarm already active
# FR: Mode rapide : sauter les tests initiaux si Swarm est déjà actif
if [[ "${QUICK_MODE}" == "true" ]] && command -v docker &>/dev/null && docker info --format '{{.Swarm.LocalNodeState}}' 2>/dev/null | grep -q "active"; then
    echo -e "  ${DIM}Quick mode: Swarm already active, skipping Labs 00-01${NC}"
    ALL_TESTS=("${ALL_TESTS[@]:2}")
    # Mark init labs as passed for dependency tracking
    TEST_RESULTS["00"]="pass"
    TEST_RESULTS["01"]="pass"
fi

# =============================================================================
# HANDLE --lab / GÉRER --lab
# =============================================================================

if [[ -n "${RUN_LAB}" ]]; then
    # Find the matching test file
    target_file=""
    for test_file in "${ALL_TESTS[@]}"; do
        if [[ "${test_file}" == "${RUN_LAB}-"* ]]; then
            target_file="${test_file}"
            break
        fi
    done

    if [[ -z "${target_file}" ]]; then
        echo -e "  ${RED}Lab ${RUN_LAB} not found in test suite${NC}"
        echo "  Available labs:"
        for test_file in "${ALL_TESTS[@]}"; do
            echo "    ${test_file%%-*}"
        done
        exit 1
    fi

    # Mark all previous tests as passed (assume they ran before)
    for test_file in "${ALL_TESTS[@]}"; do
        local_num="${test_file%%-*}"
        if [[ "${local_num}" < "${RUN_LAB}" ]]; then
            TEST_RESULTS["${local_num}"]="pass"
        fi
    done

    ALL_TESTS=("${target_file}")
fi

# =============================================================================
# HANDLE --reset / GÉRER --reset
# =============================================================================

if [[ -n "${RESET_LAB}" ]]; then
    target_file=""
    for test_file in "${ALL_TESTS[@]}"; do
        if [[ "${test_file}" == "${RESET_LAB}-"* ]]; then
            target_file="${test_file}"
            break
        fi
    done

    if [[ -z "${target_file}" ]]; then
        echo -e "  ${RED}Lab ${RESET_LAB} not found in test suite${NC}"
        exit 1
    fi

    echo -e "  ${YELLOW}Reset mode: running teardown first...${NC}"

    # Mark all previous tests as passed
    for test_file in "${ALL_TESTS[@]}"; do
        local_num="${test_file%%-*}"
        if [[ "${local_num}" < "${RESET_LAB}" ]]; then
            TEST_RESULTS["${local_num}"]="pass"
        fi
    done

    ALL_TESTS=("${target_file}")
fi

# =============================================================================
# EXECUTE TESTS / EXÉCUTER LES TESTS
# =============================================================================

for test_file in "${ALL_TESTS[@]}"; do
    test_path="${TESTS_DIR}/${test_file}"

    if [[ ! -f "${test_path}" ]]; then
        echo -e "  ${YELLOW}⊘ Test file not found: ${test_file} — skipping${NC}"
        continue
    fi

    # Source and run the test script
    # FR: Charger et exécuter le script de test
    # Each test script defines a run_test() function that we call
    source "${test_path}"
    run_test
done

# =============================================================================
# FINALIZE / FINALISER
# =============================================================================

finalize_report
print_final_summary

# Exit with non-zero if any test failed
if (( TOTAL_FAIL > 0 )); then
    exit 1
fi

exit 0
