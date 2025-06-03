#!/bin/bash
#
# Hilfsskript zum Starten des Containers.
#
# Dieses Skript vereinfacht das Starten des Containers durch
# automatisches Einbinden eines Verzeichnisses mit den Berechtigungen
# des aktuellen Benutzers.
#


# Vorgabe für das Ausgabeverzeichnis
DEFAULT_OUTPUT_DIR="${HOME}/Videos"

DOCKER_IMAGE="ard-plus-dl"
START_SCRIPT="start-ard-plus-dl.sh"

scriptFile=$(realpath "$0")
scriptDir=$(dirname "${scriptFile}")

showError() {
  echo -e "FEHLER: $*" >&2
}
exitOnError() {
  [ "$1" ] && showError "$*"
  echo "ABORTED."
  exit 1
}
showSyntax() {
  [ "$1" ] && showError "$*\n"

  cat >&2 <<+++
Syntax:
  $(basename "${scriptFile}") [-f|--force] \\
            [--bash] [--root] \\
            [--dir {output-dir}] \\
            [{dl-options}]

-f|--force:
  Neubau des Docker-Images erzwingen.
--bash:
  Interaktive Bash öffnen anstatt Starten von ard-plus-dl.sh.
--root:
  Ausführen als root
--dir {output-dir}
  Hier kann ein Verzeichnis angegeben werden, unterhalb dessen die
  Video-Dateien abgelegt werden sollen. Als Vorgabe wird
    '${DEFAULT_OUTPUT_DIR}'
  verwendet. Im Container wird dies auf das Verzeichnis 
    '${HOME}/output'
  abgebildet.
{dl-options}:
  Befehlszeilenoptionen für ard-plus-dl.sh, typischerweise:
    {ardplus-video-url} {ardplus-login-name} {ardplus-password}
+++
  exit 1
}

showHelp() {
  cat >&2 <<+++
Startet ard-plus-dl.sh von marco79cgn in einem Docker-Container;
man muss sich nicht mehr um irgendwelche Abhängigkeiten kümmern.

+++
  showSyntax
}

forceCreateImage=
startScript="${START_SCRIPT}"
runInteractive=
runAsRoot=
cmdlineArgs=
outputDir="${DEFAULT_OUTPUT_DIR}"
while [ "$1" ]
do
  case "$1"
  in
    -f|--force)
      forceCreateImage=y
      ;;
    --bash)
      startScript="bash"
      runInteractive="-it"
      ;;
    --interactive)
      runInteractive="-it"
      ;;
    --root)
      runAsRoot="--user root"
      ;;
    --dir)
      shift
      [ "$1" ] || showSyntax "Wert zu --dir muss angegeben werden."
      [ -d "$1" ] || showSyntax "Das angegebene Verzeichnis existiert nicht (--dir '$1')."
      outputDir="$1"
      ;;
    -h|--help)
      showHelp
      ;;
    -*)
      showSyntax "Nicht unterstütztes Argument: $1"
      ;;
    *)
      [ "${cmdlineArgs}" ] && cmdlineArgs="${cmdlineArgs} "
      cmdlineArgs="${cmdlineArgs}${1}"
      ;;
    esac
  shift
done

# Argumente verifizieren
[ "${outputDir}" ] || showSyntax "Default-Ausgabeverzeichnis '${outputDir}' existiert nicht. Per '--dir' ein gültiges Verzeichnis angeben."

# --force: Wenn das Image bereits existiert, dann verwerfen wir es
if [ "${forceCreateImage}" ]
then
  echo "INFO: --force: Bereits existierendes Image '${DOCKER_IMAGE}' wird gelöscht."
  if docker image inspect "${DOCKER_IMAGE}" >/dev/null 2>&1
  then
    docker image rm "${DOCKER_IMAGE}" || exitOnError "Altes Image '${DOCKER_IMAGE}' kann nicht gelöscht werden."
  fi
fi

# Existiert das Image? Wenn nein, dann bauen wir es nun.
if ! docker image inspect "${DOCKER_IMAGE}" >/dev/null 2>&1
then
  echo "INFO: Der Docker-Container wird nun gebaut ..."
  docker build --tag "${DOCKER_IMAGE}" \
    --build-arg="DEFAULT_USER=$(id -un)" \
    --build-arg="DEFAULT_USER_ID=$(id -u)" \
    --build-arg="DEFAULT_GROUP=$(id -gn)" \
    --build-arg="DEFAULT_GROUP_ID=$(id -g)" \
    --build-arg="DEFAULT_HOME_DIR=${HOME}" \
    "${scriptDir}" \
    || exitOnError "Image kann nicht erzeugt werden."
fi

# Befehl im Image starten.
eval docker run --rm ${runInteractive} ${runAsRoot} \
        --name "${DOCKER_IMAGE}" \
        --volume "${outputDir}:${HOME}/output" \
        "${DOCKER_IMAGE}" \
        "${startScript}" "${cmdlineArgs}" \
        || exitOnError "${DOCKER_IMAGE}-Container kann nicht gestartet werden."

