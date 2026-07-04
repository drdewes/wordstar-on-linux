#!/bin/sh
# install.sh — richtet WordStar 7.0 (DOS) unter Linux mit DOSBox-X ein.
#
# Was das Skript tut:
#   1. prueft, ob die noetigen Programme da sind (dosbox-x, mtools, rsync)
#   2. fragt, wo deine WordStar-Dateien liegen (der Ordner mit WS.EXE)
#   3. baut daraus ein 600-MB-FAT16-Festplatten-Image (damit WordStar korrekt
#      speichern kann) und legt es in ~/.local/share/wordstar/ ab
#   4. installiert die Konfiguration und die Helfer-Skripte (wordstar, ws-docs,
#      ws-lpt-print) nach ~/.local/bin
#
# Es laedt NICHTS aus dem Internet und braucht kein root/sudo.
# WordStar selbst ist NICHT dabei — die besorgst du dir separat (Robert J.
# Sawyers kostenloses "Complete WordStar 7.0 Archive"), siehe README.
set -eu

SHARE="$HOME/.local/share/wordstar"
BIN="$HOME/.local/bin"
HERE="$(cd "$(dirname "$0")" && pwd)"

say()  { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31mFehler:\033[0m %s\n' "$*" >&2; exit 1; }

# --- 1) Abhaengigkeiten -----------------------------------------------------
say "Pruefe benoetigte Programme ..."
missing=""
command -v dosbox-x   >/dev/null 2>&1 || missing="$missing dosbox-x"
command -v mcopy      >/dev/null 2>&1 || missing="$missing mtools"
command -v mpartition >/dev/null 2>&1 || missing="$missing mtools"
command -v rsync      >/dev/null 2>&1 || missing="$missing rsync"
if [ -n "$missing" ]; then
	warn "Es fehlen:$missing"
	cat <<EOF

Bitte zuerst installieren. Beispiele je nach Distribution:
  Arch/Manjaro:   sudo pacman -S dosbox-x mtools rsync
                  (dosbox-x ggf. aus dem AUR, z.B. 'yay -S dosbox-x')
  Debian/Ubuntu:  sudo apt install dosbox-x mtools rsync
  Fedora:         sudo dnf install dosbox-x mtools rsync

Fuer den PDF-Druck (optional) zusaetzlich 'ghostscript' (liefert ps2pdf).
Danach install.sh erneut starten.
EOF
	exit 1
fi
command -v ps2pdf >/dev/null 2>&1 || warn "ghostscript (ps2pdf) fehlt — der PDF-Druck (ws-lpt-print) geht dann nicht. Optional."

# --- 2) WordStar-Dateien finden ---------------------------------------------
SRC="${1:-}"
if [ -z "$SRC" ]; then
	cat <<EOF

Wo liegt dein WordStar-7-Programmordner (der mit WS.EXE darin)?
Das ist im Sawyer-Archiv der Ordner "WS".
Beispiel: /home/du/Downloads/wordstar-archive/WS
EOF
	printf 'Pfad: '
	read -r SRC
fi
SRC="${SRC%/}"
[ -d "$SRC" ] || die "Ordner nicht gefunden: $SRC"
if [ ! -f "$SRC/WS.EXE" ] && [ ! -f "$SRC/ws.exe" ]; then
	die "In '$SRC' liegt keine WS.EXE. Bitte den richtigen Ordner (mit WS.EXE) angeben."
fi
say "WordStar-Dateien: $SRC"

# --- 3) Zielstruktur + Image bauen ------------------------------------------
mkdir -p "$SHARE"
IMG="$SHARE/wordstarhd.img"
if [ -f "$IMG" ]; then
	warn "Es gibt schon ein Image: $IMG"
	printf 'Neu bauen und ueberschreiben? [j/N] '
	read -r a; case "$a" in j|J|y|Y) : ;; *) die "Abgebrochen (dein Image bleibt unangetastet)." ;; esac
fi

say "Baue FAT16-Festplatten-Image (600 MB) ..."
# Geometrie 609 Zyl. x 32 Koepfe x 63 Sektoren -> ~600 MB, Partition ab Sektor
# 63. Genau diese Geometrie erwartet DOSBox-X bei IMGMOUNT -> mountet zuverlaessig.
CYL=609; HEADS=32; SEC=63
truncate -s $((600*1024*1024)) "$IMG"
RC="$(mktemp)"
trap 'rm -f "$RC"; [ -n "${STAGE:-}" ] && rm -rf "$STAGE"' EXIT
printf 'drive z: file="%s" cylinders=%d heads=%d sectors=%d mformat_only partition=1\n' \
	"$IMG" "$CYL" "$HEADS" "$SEC" > "$RC"
export MTOOLSRC="$RC"
mpartition -I z: >/dev/null 2>&1 || true
mpartition -c -t "$CYL" -h "$HEADS" -s "$SEC" z:
mformat -v WORDSTAR z:                        # FAT16 (Groesse < 2 GB)

# --- WordStar in ein Staging kopieren (grosse Nicht-DOS-Ordner weglassen) ----
# Handbuecher, Windows-Tools und Archive gehoeren nicht ins DOS-Image (zu gross,
# unter DOS nutzlos). Die eigentlichen Programm- + Druckertreiberdateien bleiben.
say "Bereite WordStar-Dateien vor (ohne Handbuecher/Windows-Tools) ..."
STAGE="$(mktemp -d)"
rsync -a \
	--exclude 'MANUALS/' --exclude 'REF/' --exclude 'vDosPlus/' \
	--exclude 'PrintFilePrinter/' --exclude 'CompuServe WordStar Forum Library/' \
	--exclude 'WFW/' --exclude 'HIJAAK/' --exclude 'LegacyFileConverter/' \
	--exclude 'DOSBox-X/' \
	"$SRC"/ "$STAGE"/

say "Kopiere WordStar ins Image ..."
mmd z:/WS z:/TEXTE
# -s = rekursiv, -m = Zeitstempel, -o = ohne Rueckfrage ueberschreiben
mcopy -s -m -o "$STAGE"/* z:/WS/ >/dev/null 2>&1 || \
	die "Konnte WordStar-Dateien nicht ins Image kopieren."

# PostScript-Prolog-/Formulardateien zusaetzlich in den WS-Wurzelordner legen,
# falls WordStar sie beim Drucken direkt dort sucht.
for ps in WSPROL LETTER BORDER LOGO BOX; do
	for f in "$SRC/PRINTERS/PS/$ps.PS" "$SRC/PRINTERS/PS/$ps.ps"; do
		[ -f "$f" ] && mcopy -o "$f" z:/WS/ >/dev/null 2>&1 || true
	done
done
say "Image fertig: $IMG"

# --- 4) Konfiguration + Skripte installieren --------------------------------
say "Installiere Konfiguration ..."
sed "s#__HOME__#$HOME#g" "$HERE/config/dosbox-x-wordstar.conf" > "$SHARE/dosbox-x-wordstar.conf"

say "Installiere Skripte nach $BIN ..."
mkdir -p "$BIN"
for s in wordstar ws-docs ws-lpt-print; do
	install -m 0755 "$HERE/scripts/$s" "$BIN/$s"
done

case ":$PATH:" in
	*":$BIN:"*) : ;;
	*) warn "$BIN ist nicht in deinem PATH. Fuege in ~/.bashrc oder ~/.zshrc hinzu:"
	   printf '      export PATH="$HOME/.local/bin:$PATH"\n' ;;
esac

printf '\n\033[1;32mFertig!\033[0m WordStar 7.0 ist eingerichtet.\n'
cat <<EOF

  Starten:            wordstar
  Dokumente holen:    ws-docs           (aus dem Image nach ~/Dokumente/wordstar)
  Drucken -> PDF:     in WordStar mit dem PS-Treiber drucken (^P), das PDF
                      landet automatisch in ~/Dokumente/wordstar

In WordStar speicherst du deine Texte im Ordner  C:\\TEXTE
(dann findest du sie mit 'ws-docs' schnell wieder).

Tipp: WordStar startet im Vollbild. Fuer einen Screenshot besser im Fenster
starten:  wordstar -set "sdl fullscreen=false"

Viel Spass mit einem Stueck Software-Geschichte!
EOF
