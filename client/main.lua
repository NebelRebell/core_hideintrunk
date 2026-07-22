-- core_hideintrunk - Clientlogik
--
-- Copyright (C) 2019 Johnny Pernik (github.com/wowpanda)
-- Copyright (C) 2026 NebelRebell (github.com/NebelRebell)
-- Lizenz: GNU GPL v3 oder spaeter, siehe LICENSE.
--
-- Geaendert am 2026-07-22 durch NebelRebell gegenueber dem Original
-- client.lua (Version 0.2.3). Die Aenderungen sind im README unter
-- "Aenderungen gegenueber dem Original" einzeln aufgefuehrt.

local isHiding = false
local isInvisible = false
local hidingVehicle = nil

--- Laedt ein Animations-Dictionary und wartet, bis es verfuegbar ist.
-- @param dict string
-- @return boolean true, wenn das Dictionary geladen wurde
local function loadAnimDict(dict)
  if HasAnimDictLoaded(dict) then
    return true
  end

  RequestAnimDict(dict)

  -- Begrenzter Versuch, damit ein fehlerhafter Dictionary-Name den
  -- Thread nicht dauerhaft blockiert.
  for _ = 1, 100 do
    if HasAnimDictLoaded(dict) then
      return true
    end
    Wait(10)
  end

  return false
end

--- Zeigt einen Hilfetext oben links an.
-- @param text string
local function showHelp(text)
  BeginTextCommandDisplayHelp('STRING')
  AddTextComponentSubstringPlayerName(text)
  EndTextCommandDisplayHelp(0, false, true, -1)
end

--- Sucht das naechstgelegene Fahrzeug mit Kofferraum.
-- Ersetzt den Raycast des Originals: CastRayPointToPoint arbeitet
-- asynchron, das Ergebnis wurde dort im selben Frame ausgelesen und war
-- damit unzuverlaessig.
-- @param ped number
-- @return number|nil Fahrzeug-Handle
local function findTrunkVehicle(ped)
  local coords = GetEntityCoords(ped)
  local vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, Config.SearchRadius, 0, 71)

  if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then
    return nil
  end

  -- Fahrzeuge ohne Kofferraumknochen (Motorraeder, manche Anhaenger)
  -- werden uebersprungen.
  if GetEntityBoneIndexByName(vehicle, 'boot') == -1 then
    return nil
  end

  return vehicle
end

--- Fordert die Netzwerkhoheit ueber eine Entity an.
-- Ohne Hoheit werden Aenderungen am Fahrzeug (Kofferraumklappe) nicht
-- zuverlaessig zu anderen Spielern uebertragen.
-- @param entity number
-- @return boolean
local function requestControl(entity)
  if not NetworkGetEntityIsNetworked(entity) then
    return true
  end

  if NetworkHasControlOfEntity(entity) then
    return true
  end

  NetworkRequestControlOfEntity(entity)

  for _ = 1, 20 do
    if NetworkHasControlOfEntity(entity) then
      return true
    end
    Wait(50)
  end

  return false
end

--- Loest den Spieler vom Fahrzeug und stellt den Ausgangszustand her.
local function leaveTrunk()
  if not isHiding then
    return
  end

  local ped = PlayerPedId()

  DetachEntity(ped, true, true)
  SetEntityVisible(ped, true, false)
  SetEntityCollision(ped, true, true)
  ClearPedTasks(ped)
  ClearAllHelpMessages()

  if Config.OpenTrunkDoor and hidingVehicle and DoesEntityExist(hidingVehicle) then
    if requestControl(hidingVehicle) then
      SetVehicleDoorShut(hidingVehicle, 5, false)
    end
  end

  isHiding = false
  isInvisible = false
  hidingVehicle = nil
end

--- Versteckt den Spieler im Kofferraum des uebergebenen Fahrzeugs.
-- @param vehicle number
local function enterTrunk(vehicle)
  local ped = PlayerPedId()

  if Config.OpenTrunkDoor then
    if requestControl(vehicle) then
      SetVehicleDoorOpen(vehicle, 5, false, false)
    else
      showHelp(Config.Text.no_control)
    end
  end

  RaiseConvertibleRoof(vehicle, false)

  -- Dictionary vor dem Anheften laden, damit die Animation ohne
  -- sichtbare Verzoegerung startet.
  local hasAnim = loadAnimDict(Config.Animation.dict)

  ClearPedTasksImmediately(ped)

  AttachEntityToEntity(
    ped, vehicle, -1,
    Config.Offset.x, Config.Offset.y, Config.Offset.z,
    Config.Rotation.x, Config.Rotation.y, Config.Rotation.z,
    false, false, false, false, 20, true
  )

  if hasAnim then
    -- Flag 1 = Schleife, damit die Liegepose dauerhaft gehalten wird.
    TaskPlayAnim(ped, Config.Animation.dict, Config.Animation.name, 1.0, -1, -1, 1, 0, false, false, false)
  end

  isHiding = true
  isInvisible = false
  hidingVehicle = vehicle
end

--- Schaltet zwischen Verstecken und Verlassen um.
local function toggleHide()
  if isHiding then
    leaveTrunk()
    return
  end

  local ped = PlayerPedId()

  if GetVehiclePedIsIn(ped, false) ~= 0 then
    showHelp(Config.Text.in_vehicle)
    return
  end

  if IsPedDeadOrDying(ped, true) then
    return
  end

  local vehicle = findTrunkVehicle(ped)

  if not vehicle then
    showHelp(Config.Text.no_vehicle)
    return
  end

  enterTrunk(vehicle)
end

-- Kommando und Tastenbindung.
-- Das Kommando /hideintrunk war im README des Originals dokumentiert,
-- wurde dort aber mit dem Commit "Revert changes - new version was broken"
-- wieder aus dem Code entfernt.
RegisterCommand('hideintrunk', function()
  toggleHide()
end, false)

RegisterKeyMapping('hideintrunk', 'Im Kofferraum verstecken', 'keyboard', Config.DefaultKey)

-- Hinweis anzeigen, solange der Spieler zu Fuss vor einem passenden
-- Fahrzeug steht. Die Suche laeuft mit grossem Intervall; nur wenn
-- tatsaechlich ein Fahrzeug in Reichweite ist, wird pro Frame gezeichnet.
CreateThread(function()
  while true do
    local wait = 500

    if not isHiding then
      local ped = PlayerPedId()

      if GetVehiclePedIsIn(ped, false) == 0 and findTrunkVehicle(ped) then
        showHelp(Config.Text.hint_enter)
        wait = 0
      end
    end

    Wait(wait)
  end
end)

-- Steuerung und Zustandsueberwachung, solange der Spieler versteckt ist.
CreateThread(function()
  while true do
    local wait = 500

    if isHiding then
      wait = 0

      local ped = PlayerPedId()

      -- Fahrzeug verschwunden oder Spieler gestorben: sauber aussteigen.
      if not hidingVehicle or not DoesEntityExist(hidingVehicle) or IsPedDeadOrDying(ped, true) then
        leaveTrunk()
      else
        DisableAllControlActions(0)
        DisableAllControlActions(1)
        DisableAllControlActions(2)

        for _, control in ipairs(Config.AllowedControls) do
          EnableControlAction(control[1], control[2], true)
        end

        if Config.AllowInvisibility then
          showHelp(Config.Text.hint_inside)

          -- Der Zustand liegt bewusst ausserhalb der Schleife. Im Original
          -- wurde "visible" in jedem Durchlauf neu auf true gesetzt,
          -- wodurch die Abfrage wirkungslos war und sich die
          -- Unsichtbarkeit nicht mehr abschalten liess.
          if IsDisabledControlJustPressed(0, Config.InvisibilityControl) then
            isInvisible = not isInvisible
            SetEntityVisible(ped, not isInvisible, false)
          end
        else
          showHelp(Config.Text.hint_inside_novis)
        end
      end
    end

    Wait(wait)
  end
end)

-- Beim Stoppen der Ressource darf der Spieler nicht angeheftet oder
-- unsichtbar zurueckbleiben.
AddEventHandler('onResourceStop', function(resource)
  if resource ~= GetCurrentResourceName() then
    return
  end

  leaveTrunk()
end)
