# Überblick

[marco79cgn](https://gist.github.com/marco79cgn) stellt als GitHub GIST das Skript [`ard-plus-dl.sh`](https://gist.github.com/marco79cgn/b09e26beaaf466cb04f9d74122866048), das unter Zuhilfenahme von [yt-dlp](https://github.com/yt-dlp/yt-dlp) das Herunterladen von Videos bei ARDplus zu einem Kinderspiel macht.

Allerdings benötigt das Skript diverse Hilfsprogramme - vor allem curl. Leider arbeiten nicht alle Versionen von curl wie benötigt, je nach verwendetem Betriebssystem muss mehr oder weniger aufwändig die korrekte Version beschafft werden.

Um diese Konflikte zu vermeiden, hat marco79cgn vorgeschlagen, das Skript in Form eines Docker-Images zur Verfügung zu stellen - dies erledigt zum Beispiel dieses Projekt hier.

# Struktur

Das Docker-Image wird mit folgenden Dateien verwaltet:

- `Dockerfile` beschreibt den Inhalt des Images.
- `start-ard-plus-dl.sh` ist ein Hilfsskript, das in das Image eingebettet wird (Docker-Startskript).
- `ardplus-dl-docker.sh` vereinfacht den Umgang mit dem Docker-Image:
  - Beim ersten Start wird das Docker-Image automatisch erzeugt und die jeweils aktuellsten Versionen von `yt-dlp` und `ard-plus-dl.sh` heruntergeladen.
  - Das Ausgabeverzeichnis wird mit den Berechtigungen des aktuellen Benutzers im Docker-Container eingebunden - so gibt es keinerlei Zugriffsprobleme auf die heruntergeladenen Dateien.

Diese drei Dateien müssen in einem beliebigen Verzeichnis abgelegt werden - Schreibzugriff ist keiner erforderlich.

# Verwendung

Alle für das Image benötigte Dateien (siehe ["Struktur"]) müssen in einem beliebigen Verzeichnis abgelegt werden - Schreibzugriff ist keiner erforderlich. `ardplus-dl-docker.sh` muss jedoch ausführbar gemacht werden.

Sofern Docker korrekt installiert ist, können sofort Videos heruntergeladen werden.

## Image herunterladen

```bash
git clone https://github.com/profhccaesar/docker-ard-plus-dl.git [{dir}]
chmod +x ./docker-ard-plus-dl
```
Konkretes Beispiel:

```bash
myuser@mypc:~$ git clone https://github.com/profhccaesar/docker-ard-plus-dl.git ./docker-ard-plus-dl
chmod +x ./docker-ard-plus-dl
```



## Download durchführen

Das Docker-Image wird dabei automatisch gebaut:

```bash
ard-plus-dl-docker.sh {options} {ard-plus-url} {username} {password}
```

- Mit `{options}`  kann der Aufruf des Docker-Containers gesteuert werden, beschrieben im Abschnitt ["Optionen"](#optionen); die weiteren Parameter werden direkt an `ard-plus-dl.sh` weitergereicht.

Konkretes Beispiel:

```bash
myuser@mypc:~$ cd docker-ard-plus-dl
myuser@mypc:~/docker-ard-plus-dl$ ./ard-plus-dl-docker.sh 'https://www.ardplus.de/details/a0S010000037hjZ-kommissar-dupin-bretonischer-ruhm' 'myuser' 'mypassword'
INFO: Der Docker-Container wird nun gebaut ...
[+] Building 1.1s (18/18) FINISHED                     docker:default
 => [internal] load build definition from Dockerfile             0.0s
 ...
 => => naming to docker.io/library/ard-plus-dl                   0.0s
Lade Film Kommissar Dupin: Bretonischer Ruhm (2023)...
myuser@mypc:~$
```

Die Dateien werden dann im Verzeichnis `Videos` des aktuellen Benutzers abgelegt:

```bash
myuser@mypc:~$ ls -l ~/Videos
insgesamt 3065180
-rw-r--r-- 1 myuser myuser        601 Jun  3 16:26  ard-plus-token
-rw-r--r-- 1 myuser myuser       7221 Jun  3 16:26  content-result.txt
-rw-r--r-- 1 myuser myuser 3138723990 Feb 28 06:01 'Kommissar Dupin: Bretonischer Ruhm (2023).mp4'
```

Es kann auch ein beliebiges anderes Verzeichnis für die Ausgabe verwendet werden; dieses Verzeichnis muss jedoch existieren. Beispiel:

```bash
myuser@mypc:~/docker-ard-plus-dl$ ./ard-plus-dl-docker.sh --dir ~/Downloads 'https://www.ardplus.de/details/a0S010000037hjZ-kommissar-dupin-bretonischer-ruhm' 'myuser' 'mypassword'
```

### Optionen

Das Skript kennt einige Optionen, die vornehmlich für die Fehlersuche gedacht sind:

```bash
myuser@mypc:~/docker-ard-plus-dl$ ./ard-plus-dl-docker.sh --help
Startet ard-plus-dl.sh von marco79cgn in einem Docker-Container;
man muss sich nicht mehr um irgendwelche Abhängigkeiten kümmern.

Syntax:
  ard-plus-dl-docker.sh [-f|--force] \
            [--bash] [--root] \
            [--dir {output-dir}] \
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
    '/home/myuser/Videos'
  verwendet. Im Container wird dies auf das Verzeichnis 
    '/home/myuser/output'
  abgebildet.
{dl-options}:
  Befehlszeilenoptionen für ard-plus-dl.sh, typischerweise:
    {ardplus-video-url} {ardplus-login-name} {ardplus-password}
```

Beispiele:

- `--bash` - Shell im Container öffnen und den Download von Hand starten:

  ```bash
  myuser@mypc:~/docker-ard-plus-dl$ ./ard-plus-dl-docker.sh --bash
  myuser@e82819d3cc5a:~$ cd output
  myuser@e82819d3cc5a:~/output$ ard-plus-dl.sh 'https://www.ardplus.de/details/a0T010000005zBQ-raumpatrouille-orion' 'myuser' 'mypassword'
  ...
  ```

- `--bash --root` - Shell mit root-Rechten öffnen und den Container modifizieren:

  ```bash
  myuser@mypc:~/docker-ard-plus-dl$ ./ard-plus-dl-docker.sh --bash --root
  root@3f6f044466e9:/home/myuser# apt-get install -y vim
  ...
  root@3f6f044466e9:/home/myuser# vi /usr/local/bin/ard-plus-dl.sh
  ```
