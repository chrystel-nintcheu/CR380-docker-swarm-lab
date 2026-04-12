@echo off
:: =============================================================================
:: CR380 — Provisionner une VM Multipass pour les labs Docker Swarm
::         Provision a Multipass VM for Docker Swarm Labs
:: =============================================================================
:: Usage: cloud-init\provision-multipass.bat [nom-vm / vm-name]
:: =============================================================================
setlocal

:: ---------------------------------------------------------------------------
:: Chemins / Paths
:: ---------------------------------------------------------------------------
set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..") do set "PROJECT_DIR=%%~fI"

:: ---------------------------------------------------------------------------
:: Nom de la VM / VM name
:: ---------------------------------------------------------------------------
if "%~1"=="" (set "VM_NAME=cr380-swarm-lab") else (set "VM_NAME=%~1")

echo %VM_NAME%| findstr /R "^[a-zA-Z][-a-zA-Z0-9]*$" >nul
if errorlevel 1 (
    echo ERREUR : Nom de VM invalide : %VM_NAME%
    echo ERROR  : Invalid VM name: %VM_NAME%
    echo         Format attendu / Expected format: ^[a-zA-Z^][-a-zA-Z0-9]*
    exit /b 1
)

set "CLOUD_INIT=%SCRIPT_DIR%user-data-fresh.yaml"

:: ---------------------------------------------------------------------------
:: Prerequis / Prerequisites
:: ---------------------------------------------------------------------------
multipass version >nul 2>nul
if errorlevel 1 (
    echo ERREUR : Multipass non installe ou service arrete.
    echo ERROR  : Multipass not installed or service stopped.
    echo         Installer depuis / Install from: https://multipass.run
    echo         Verifier que C:\Program Files\Multipass\bin est dans le PATH.
    echo         Verify C:\Program Files\Multipass\bin is on your PATH.
    exit /b 1
)

if not exist "%CLOUD_INIT%" (
    echo ERREUR : Fichier cloud-init introuvable : %CLOUD_INIT%
    echo ERROR  : cloud-init file not found: %CLOUD_INIT%
    exit /b 1
)

:: ---------------------------------------------------------------------------
:: Conflit VM / VM conflict check
:: ---------------------------------------------------------------------------
multipass info "%VM_NAME%" >nul 2>nul
if not errorlevel 1 (
    echo ERREUR : La VM '%VM_NAME%' existe deja.
    echo ERROR  : VM '%VM_NAME%' already exists.
    multipass info "%VM_NAME%" 2>nul | findstr /C:"Deleted" >nul
    if not errorlevel 1 (
        echo         La VM est en etat Deleted. Executez / VM is in Deleted state. Run:
        echo           multipass purge
    ) else (
        echo         Pour la supprimer / To remove it:
        echo           multipass delete %VM_NAME% ^&^& multipass purge
    )
    exit /b 1
)

:: ---------------------------------------------------------------------------
:: Lancement / Launch
:: ---------------------------------------------------------------------------
echo ==> Lancement de la VM '%VM_NAME%'... (2-5 min, soyez patient)
echo ==> Launching VM '%VM_NAME%'... (2-5 min, be patient)

multipass launch --name "%VM_NAME%" --cloud-init "%CLOUD_INIT%" --cpus 2 --memory 4G --disk 20G 22.04
if errorlevel 1 (
    echo ERREUR : Le lancement a echoue.
    echo ERROR  : Launch failed.
    echo         Nettoyage / Cleaning up...
    multipass delete "%VM_NAME%" >nul 2>nul
    multipass purge >nul 2>nul
    exit /b 1
)

echo ==> En attente de cloud-init... / Waiting for cloud-init...
echo     (Ctrl+C pour annuler si bloque / Ctrl+C to abort if stuck)
multipass exec "%VM_NAME%" -- cloud-init status --wait
if errorlevel 1 (
    echo ERREUR : cloud-init a echoue dans la VM.
    echo ERROR  : cloud-init failed inside the VM.
    echo         Consultez les logs / Check logs:
    echo           multipass exec %VM_NAME% -- cat /var/log/cloud-init-output.log
    exit /b 1
)

:: ---------------------------------------------------------------------------
:: Succes / Success
:: ---------------------------------------------------------------------------
echo.
echo ==> La VM '%VM_NAME%' est prete.
echo ==> VM '%VM_NAME%' is ready.
echo.
echo     Connexion / Connect:
echo       multipass shell %VM_NAME%
echo.
echo     Puis executez / Then run:
echo       cd CR380-docker-swarm-lab ^&^& sudo bash run-labs.sh --learn
echo.
echo     (Optionnel / Optional) Monter le repertoire local / Mount local directory:
echo       multipass mount "%PROJECT_DIR%" %VM_NAME%:/home/ubuntu/CR380-docker-swarm-lab
echo     (Requiert le support mount Multipass / Requires Multipass mount support)

endlocal & exit /b 0
