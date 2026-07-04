# Text zum Einfügen in Claude Code

Du hast [Claude Code](https://claude.com/claude-code) installiert und möchtest,
dass die KI dir WordStar 7.0 komplett einrichtet? Dann kopiere **den ganzen
Block unten** und füge ihn in Claude Code ein. Mehr musst du nicht tun — die KI
fragt dich nach dem, was sie braucht.

*(Copy the block below and paste it into Claude Code — it will do the rest.)*

---

```text
Ich möchte WordStar 7.0 für DOS auf meinem Linux-Rechner einrichten und benutze
dafür das Projekt „wordstar-on-linux". Ich bin kein Programmierer – bitte führe
mich freundlich und in einfachen Worten durch alles und erledige die technischen
Schritte für mich.

Bitte gehe so vor:

1. Klone das Repository, falls noch nicht vorhanden:
   git clone https://github.com/drdewes/wordstar-on-linux.git
   und wechsle hinein. Lies die README.md und install.sh, damit du den Aufbau
   verstehst.

2. Prüfe, ob die benötigten Programme installiert sind: dosbox-x, mtools und
   rsync (sowie ghostscript für den optionalen PDF-Druck). Falls etwas fehlt,
   gib mir den passenden Installationsbefehl für meine Distribution zum Kopieren
   (ich habe kein passwortloses sudo, führe root-Befehle also NICHT selbst aus).

3. WordStar selbst ist aus Copyright-Gründen NICHT im Repo. Erkläre mir kurz,
   dass der Science-Fiction-Autor Robert J. Sawyer das komplette „WordStar 7.0
   Archive" kostenlos veröffentlicht hat (https://www.sfwriter.com/ws7.htm oder
   im Internet Archive: https://archive.org/details/sawyer-wordstar-7-archive-20240812).
   Frage mich, ob ich die Dateien schon habe. Wenn ja, frage nach dem Pfad zum
   Ordner „WS" (darin liegt WS.EXE). Wenn nein, hilf mir beim Herunterladen und
   Entpacken.

4. Führe dann ./install.sh aus (oder rufe es mit dem WS-Ordner als Argument
   auf). Das Skript baut ein 600-MB-FAT16-Festplatten-Image aus meinen
   WordStar-Dateien (nötig, damit WordStar korrekt speichern kann) und
   installiert die Konfiguration und die Helfer-Skripte (wordstar, ws-docs,
   ws-lpt-print).

5. Prüfe, ob ~/.local/bin in meinem PATH ist. Falls nicht, hilf mir, das zu
   ergänzen.

6. Erkläre mir am Ende in einfachen Worten:
   - starten mit „wordstar“
   - in WordStar Texte in den Ordner C:\TEXTE speichern
   - Texte mit „ws-docs“ nach Linux holen
   - zum Drucken/Weitergeben in WordStar mit dem PostScript-Treiber drucken (^P),
     das PDF landet automatisch in ~/Dokumente/wordstar

Wenn beim Starten oder Speichern etwas nicht klappt (z. B. eine Fehlermeldung
in DOSBox-X), lies sie mit mir zusammen und behebe das Problem. Teste nach
Möglichkeit selbst, statt es nur mir zu überlassen. Hinweis: für Screenshots
oder zum Debuggen DOSBox-X besser im Fenster starten
(wordstar -set "sdl fullscreen=false"), nicht im Vollbild.
```

---

Wenn dabei etwas hakt, kannst du deiner KI natürlich einfach in eigenen Worten
sagen, was nicht klappt — sie kennt jetzt den Zusammenhang.
