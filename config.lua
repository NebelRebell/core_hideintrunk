-- core_hideintrunk - Konfiguration
--
-- Copyright (C) 2019 Johnny Pernik (github.com/wowpanda)
-- Copyright (C) 2026 NebelRebell (github.com/NebelRebell)
-- Lizenz: GNU GPL v3 oder spaeter, siehe LICENSE.
--
-- Neu hinzugefuegt am 2026-07-22 durch NebelRebell. Im Original waren alle
-- Werte fest im Skript verdrahtet.

Config = {}

-- Standardtaste zum Betreten und Verlassen des Kofferraums.
-- Wird ueber RegisterKeyMapping gesetzt und ist im Spiel unter
-- Einstellungen > Tastenbelegung > FiveM frei umbelegbar.
-- Das Original nutzte fest ALT+Q; das liess sich nicht umbelegen und
-- kollidierte mit der Deckungstaste.
Config.DefaultKey = 'K'

-- Umkreis in Metern, in dem nach einem passenden Fahrzeug gesucht wird.
Config.SearchRadius = 3.5

-- Liegeposition relativ zum Fahrzeugmittelpunkt.
-- Passt nicht bei jedem Fahrzeugmodell gleich gut; bei Bedarf anpassen.
Config.Offset = { x = 0.0, y = -2.2, z = 0.5 }

-- Rotation des Spielers im Kofferraum in Grad.
Config.Rotation = { x = 0.0, y = 0.0, z = 0.0 }

-- Animation im Kofferraum.
Config.Animation = {
  dict = 'timetable@floyd@cryingonbed@base',
  name = 'base',
}

-- Kofferraumklappe beim Einsteigen oeffnen und beim Aussteigen schliessen.
Config.OpenTrunkDoor = true

-- Unsichtbarkeit per Taste erlauben.
-- Achtung: Die Sichtbarkeit wird clientseitig gesetzt. Ob andere Spieler
-- den versteckten Spieler dadurch tatsaechlich nicht mehr sehen, haengt
-- von der Serverkonfiguration ab und ist nicht zugesichert. Siehe README.
Config.AllowInvisibility = true

-- Steuerungs-ID fuer die Unsichtbarkeit (22 = Leertaste).
Config.InvisibilityControl = 22

-- Steuerungen, die im Kofferraum weiterhin erlaubt bleiben.
-- Format: { controlGroup, controlId }
Config.AllowedControls = {
  { 0, 0 },   -- Kamera umschalten
  { 0, 249 }, -- Push-to-Talk
  { 2, 1 },   -- Kamera horizontal
  { 2, 2 },   -- Kamera vertikal
  { 0, 177 }, -- Zurueck / Escape-Ersatz
  { 0, 200 }, -- Pausemenue
}

-- Bildschirmtexte. Das Original war fest auf Tschechisch.
Config.Text = {
  hint_enter      = 'Kofferraum: Taste zum Verstecken druecken',
  hint_inside     = 'Leertaste: unsichtbar  ~n~  Taste erneut: aussteigen',
  hint_inside_novis = 'Taste erneut druecken zum Aussteigen',
  no_vehicle      = 'Kein passendes Fahrzeug in der Naehe.',
  in_vehicle      = 'Das geht nur zu Fuss.',
  no_control      = 'Fahrzeug reagiert nicht, bitte erneut versuchen.',
}
