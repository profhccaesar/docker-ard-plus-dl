
# Aktuell verwendet das neueste Debian Image die "alte" curl-Version
# 7.88, mit der der Zugriff auf die Filmdetails scheitert.
#FROM debian:latest

# Ab Ubuntu 24.04 (ubuntu:noble) ist eine ausreichend neue
# Version von curl enthalten (>= 8.5.0
FROM ubuntu:noble

# === Optionen
ARG YTDLP_GIT_URL="https://github.com/yt-dlp/yt-dlp.git"
ARG ARDPLUS_DOWNLOAD_URL="https://gist.githubusercontent.com/marco79cgn/b09e26beaaf466cb04f9d74122866048/raw/e6b7e821084b0b52406e6cb675821a3ee2794916/ard-plus-dl.sh"

ARG DEFAULT_USER=ardplus-dl
ARG DEFAULT_USER_ID=1000
ARG DEFAULT_GROUP=${DEFAULT_USER}
ARG DEFAULT_GROUP_ID=1000
ARG DEFAULT_HOME_DIR=/home/${DEFAULT_USER}

# === Environment für die Laufzeit setzen

# === Installationen

# Bei älteren Ubuntu Versionen müssen die Paketquellen angepasst werden:
#RUN sed -i -re 's/archive.ubuntu.com/old-releases.ubuntu.com/g' /etc/apt/sources.list

# Aktualisieren
RUN apt-get update && apt-get upgrade -y

# Dash-Müll entsorgen
RUN echo "dash dash/sh boolean false" | debconf-set-selections && \
  DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash

# Benötigte Binaries installieren
RUN apt-get install -y curl jq ffmpeg git python3

# === yt-dlp und ardplus-dl installieren
RUN cd /opt && git clone "${YTDLP_GIT_URL}" yt-dlp && \
  chmod ugo+rx /opt/yt-dlp/yt-dlp.sh && \
  ln -s /opt/yt-dlp/yt-dlp.sh /usr/local/bin/yt-dlp
RUN curl -o /usr/local/bin/ard-plus-dl.sh "${ARDPLUS_DOWNLOAD_URL}" && \
  chmod ugo+rx /usr/local/bin/ard-plus-dl.sh

# === Startskript

ADD ./start-ard-plus-dl.sh /usr/local/bin/
RUN chmod ugo+rx /usr/local/bin/start-ard-plus-dl.sh

# === Benutzer & Gruppen anlegen.
#     Dies ermöglicht es dem Container, den gleichen Benutzernamen
#     und die gleiche ID zu verwenden, unter dem der Container gestartet
#     wird - damit gibt es keine Berechtigungsprobleme beim Ablegen der
#     Vidoe-Dateien auf dem Host.

# Leider hat irgend jemand bei den neueren Ubuntu-Docker-Images hart den
# Benutzer "ubuntu" reingebastelt, den wir zuerst entsorgen müssen, damit
# es keine Kollissionen gibt. Blödsinnigerweise verwendet dieser die ID
# 1000, die auch dem Hauptbenutzer üblicher Desktop-Installationen zugeordnet
# ist.
RUN userdel --force --remove ubuntu

RUN groupadd --gid ${DEFAULT_GROUP_ID} ${DEFAULT_GROUP}
RUN useradd --uid ${DEFAULT_USER_ID} --gid ${DEFAULT_GROUP} \
    --home-dir ${DEFAULT_HOME_DIR} --no-create-home ${DEFAULT_USER}

RUN mkdir ${DEFAULT_HOME_DIR} \
    && chown ${DEFAULT_USER}.${DEFAULT_GROUP} ${DEFAULT_HOME_DIR}

# === Ab jetzt nur noch den definierten Benutzer verwenden!
USER ${DEFAULT_USER}
WORKDIR ${DEFAULT_HOME_DIR}

