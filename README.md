# core_hideintrunk

Standalone-Ressource fuer FiveM. Der Spieler kann sich zu Fuss in den
Kofferraum eines Fahrzeugs legen und sich darin transportieren lassen.
Typische Anwendung im Rollenspiel: Entfuehrungen, Schmuggel, Verstecken
vor einer Verfolgung.

Kein Framework erforderlich. Laeuft ohne ESX, QBCore oder sonstige
Abhaengigkeiten.

---

## Urheber

Das Original stammt von **Johnny Pernik** (GitHub:
[wowpanda](https://github.com/wowpanda)), veroeffentlicht Januar 2019
unter <https://github.com/wowpanda/core_hideintrunk> in der Version 0.2.3.
Saemtliche Grundmechanik - Anheften an das Fahrzeugheck, Liegeanimation,
Sperren der Steuerung, Unsichtbarkeit - geht auf ihn zurueck.

Dieses Repository ist ein Fork mit einer Ueberarbeitung durch
[NebelRebell](https://github.com/NebelRebell). Die vorgenommenen
Aenderungen sind weiter unten vollstaendig aufgefuehrt.

## Lizenz

**GNU General Public License Version 3 oder spaeter.** Der vollstaendige
Lizenztext liegt in der Datei [`LICENSE`](LICENSE).

Die Lizenz wurde vom urspruenglichen Autor gewaehlt und bleibt
unveraendert. Wer diese Ressource weitergibt - veraendert oder
unveraendert - muss sie ebenfalls unter der GPL-3.0 stellen, den
Quelltext mitliefern und die Urhebervermerke erhalten. Eine Nutzung in
einem geschlossenen, nicht quelloffenen Skriptpaket ist damit nicht
zulaessig.

---

## Installation

1. Ordner nach `resources/core_hideintrunk` kopieren.
2. In der `server.cfg` eintragen:

   ```cfg
   ensure core_hideintrunk
   ```

3. Server neu starten.

## Bedienung

| Eingabe | Wirkung |
| :--- | :--- |
| Taste **K** oder `/hideintrunk` | Kofferraum betreten bzw. verlassen |
| **Leertaste** (im Kofferraum) | Unsichtbarkeit ein- und ausschalten |

Die Taste ist im Spiel unter **Einstellungen > Tastenbelegung > FiveM**
frei umbelegbar. Der Standardwert laesst sich in der `config.lua` aendern.

Man muss zu Fuss und in Reichweite eines Fahrzeugs mit Kofferraum stehen;
ein Hinweistext erscheint, sobald ein passendes Fahrzeug in der Naehe ist.

## Konfiguration

Alle Werte liegen in [`config.lua`](config.lua) und sind dort kommentiert:
Standardtaste, Suchradius, Liegeposition und -drehung, Animation,
Oeffnen der Kofferraumklappe, Unsichtbarkeit, im Kofferraum erlaubte
Steuerungen und saemtliche Bildschirmtexte.

---

## Aenderungen gegenueber dem Original

Angabe gemaess GPL-3.0 Abschnitt 5a. Bearbeitet am **2026-07-22** durch
NebelRebell, ausgehend von Commit `b583578` (Version 0.2.3).

### Behobene Fehler

1. **`/hideintrunk` funktionierte nicht.** Das Kommando war im README
   dokumentiert, wurde aber mit dem Commit `fd7f47a` *"Revert changes -
   new version was broken"* aus dem Code entfernt. Es ist jetzt wieder
   vorhanden und ueber `RegisterCommand` umgesetzt.
2. **Unsichtbarkeit liess sich nicht abschalten.** `local visible = true`
   stand innerhalb der Hauptschleife und wurde in jedem Durchlauf
   zurueckgesetzt, wodurch die Abfrage `if visible then` wirkungslos war.
   Der Zustand liegt jetzt ausserhalb der Schleife und die Taste schaltet
   in beide Richtungen. Behebt den offenen Punkt *"disable invisibility
   again"* aus der urspruenglichen To-do-Liste.
3. **Nicht existierende Variable.** Der Ausweichzweig fuer die Animation
   rief `TaskPlayAnim(playerPed, ...)` auf; die Variable hiess ueberall
   sonst `player`, `playerPed` war global und damit `nil`. Der Zweig ist
   durch ein Laden des Animations-Dictionary vor dem Anheften ersetzt.
4. **Unzuverlaessige Fahrzeugerkennung.** `CastRayPointToPoint` arbeitet
   asynchron, das Ergebnis wurde aber im selben Frame per
   `GetRaycastResult` ausgelesen. Ersetzt durch `GetClosestVehicle` mit
   Pruefung auf einen vorhandenen Kofferraumknochen. Behebt zugleich
   *"doesnt fit in every trunk"*, da Fahrzeuge ohne Kofferraum jetzt gar
   nicht erst angeboten werden.
5. **Kofferraumklappe schloss sich waehrend der Fahrt.**
   `SetVehicleDoorShut` wurde nach einem festen `Wait(2000)` innerhalb
   der Schleife aufgerufen, unabhaengig davon, ob jemand darin lag. Die
   Klappe schliesst jetzt beim Aussteigen.
6. **Kein Loesen bei Zustandswechseln.** Starb der Spieler oder
   verschwand das Fahrzeug, blieb er angeheftet und unsichtbar. Es gibt
   jetzt eine Ueberwachung sowie einen `onResourceStop`-Handler, der
   beim Stoppen der Ressource aufraeumt.
7. **Fehlende Netzwerkhoheit.** Die Kofferraumklappe wurde ohne
   `NetworkRequestControlOfEntity` geoeffnet und bewegte sich bei
   fremden Fahrzeugen fuer andere Spieler nicht zuverlaessig.

### Sonstige Aenderungen

- `__resource.lua` durch `fxmanifest.lua` mit `fx_version 'cerulean'`
  und `game 'gta5'` ersetzt.
- Aufteilung in `config.lua` und `client/main.lua`; im Original waren
  alle Werte fest verdrahtet.
- Feste Tastenkombination **ALT+Q** ersetzt durch `RegisterKeyMapping`.
  Die alte Bindung war nicht umbelegbar und kollidierte mit der
  Deckungstaste.
- Die Hauptschleife lief dauerhaft mit `Wait(5)` inklusive Raycast pro
  Durchlauf. Sie laeuft jetzt mit `Wait(500)` und schaltet nur dann auf
  Frame-Takt, wenn tatsaechlich ein Fahrzeug in Reichweite ist.
- Bildschirmtexte waren fest auf Tschechisch und liegen jetzt in der
  Konfiguration.
- Veraltete Text-Natives (`SetTextComponentFormat`,
  `DisplayHelpTextFromStringLabel`) durch
  `BeginTextCommandDisplayHelp`/`EndTextCommandDisplayHelp` ersetzt.

---

## Bekannte Einschraenkungen

- **Die Unsichtbarkeit ist clientseitig.** `SetEntityVisible` wird auf
  dem eigenen Client gesetzt. Ob andere Spieler den versteckten Spieler
  dadurch tatsaechlich nicht mehr sehen, haengt von der Serverumgebung ab
  und ist **nicht zugesichert**. Wer sich darauf verlassen will, sollte
  es auf dem eigenen Server pruefen und die Funktion andernfalls ueber
  `Config.AllowInvisibility = false` abschalten.
- **Rein clientseitige Ressource.** Es gibt keine Serverkomponente und
  damit keine serverseitige Pruefung. Ein manipulierter Client kann sich
  an beliebige Fahrzeuge heften. Fuer Szenarien, in denen das
  missbraucht werden koennte, gehoert die Entscheidung auf den Server
  verlagert.
- **Die Liegeposition passt nicht zu jedem Fahrzeugmodell.** Der Offset
  ist ein Kompromisswert und ueber `Config.Offset` anpassbar. Eine
  Automatik pro Fahrzeugklasse gibt es nicht.
- Eine Begrenzung, wie viele Personen gleichzeitig in einem Kofferraum
  liegen koennen, ist nicht umgesetzt.

## Nicht uebernommene Punkte der urspruenglichen To-do-Liste

`ability to adjust offset` ist ueber die Konfiguration erledigt,
`disable invisibility again` ist behoben. Offen bleiben bewusst:
`server side for 3D text`, `rotate ped 180°`, `create scripted camera`
sowie die Begrenzung der Personenzahl pro Fahrzeugklasse.
