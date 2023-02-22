-- LEVITON VRCS4-M0Z EDGE DRIVER FOR SMARTTHINGS
-- 
-- Copyright 2023, Henry Robinson
-- Based on contributions by Brian Dahlem, Copyright 2014
-- Acknowledgements:
--  Jeff Brown (j9brown) for decoding Leviton LED commands
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.


local capabilities = require "st.capabilities"
local ZwaveDriver = require "st.zwave.driver"
local utils = require "st.utils"
local defaults = require "st.zwave.defaults"
local log = require "log"

--- handle functions to throttle commands
local throttle_send = require "throttle_send"

--- @type st.zwave.CommandClass
local cc = require "st.zwave.CommandClass"
local Basic = (require "st.zwave.CommandClass.Basic")({ version = 1})
local SwitchBinary = (require "st.zwave.CommandClass.SwitchBinary")({ version = 2})
local Association = (require "st.zwave.CommandClass.Association") ({version = 2})
local SceneControllerConf= (require "st.zwave.CommandClass.SceneControllerConf")({ version = 1})
local SceneActuatorConf= (require "st.zwave.CommandClass.SceneActuatorConf")({ version = 1})
local SceneActivation= (require "st.zwave.CommandClass.SceneActivation")({ version = 1})
local SwitchMultilevel= (require "st.zwave.CommandClass.SwitchMultilevel")({ version = 3})
local Configuraiton = (require "st.zwave.CommandClass.Configuration") ({version = 1})
local ManufacturerProprietary = (require "st.zwave.CommandClass.ManufacturerProprietary")({ version = 1})
local ManufacturerSpecific = (require "st.zwave.CommandClass.ManufacturerSpecific")({ version = 1})
local zw = require "st.zwave"

local switchNames = {"main", "switch2", "switch3", "switch4"}


local ZWAVE_LEVITON_VRCS4_FINGERPRINTS = {
  {mfr = 0x001D, prod = 0x0802, model = 0x0261} -- Leviton ZRCS4
}

local function can_handle_LEVITON_VRCS4(opts, driver, device, ...)
  for _, fingerprint in ipairs(ZWAVE_LEVITON_VRCS4_FINGERPRINTS) do
   if device:id_match(fingerprint.mfr, fingerprint.prod, fingerprint.model) then
      return true
      end
    end
 return false
end

-- helper functions 

-- pace the commands to the device
local function queue_command (device, cmd)
  local cmds = {}
  table.insert (cmds, { msg = cmd })
  throttle_send (device, cmds)
end

-- determine which devices should receive commands based in Sync Option
local function build_device_list (driver, device)
  local deviceList = {device}
  if (not device.preferences.sync) then
    return deviceList 
    end
  local devices = driver:get_devices()
  for index = 1,#devices do
    if (devices[index].preferences.sync) and (devices[index] ~= device) then
      table.insert (deviceList, devices[index])
      end
  end
  return deviceList
end

-- update the LED bit
-- 1) Retrieve the latest state for each switch and build the bitmap
-- 2) The bitmap is the last byte of the command (green is the last 4 bits)
-- 3) If we have sync enabled and multiple devices, update the LEDs for each device
-- 4) Setting the LED will enable/disable scene for each switch (controlled by lit LED)

local function update_LEDs (driver, device) 
  local bitmap = 0
  for i = 4,1,-1 do
    bitmap = bitmap << 1
    local state = device:get_latest_state (switchNames[i], "switch", "switch")
    bitmap = (state == "off") and bitmap or (bitmap | 1)
  end
-- LEDs get set, but get an unsupported command response from device
  local cmdString = string.format("\x1D\x0D\x01\xFF%c", bitmap)
  local devices = build_device_list (driver, device)
  for index = 1,#devices do
    devices[index]:send(zw.Command(0x91, 0x00, cmdString))
  end
end

-- Event handlers -- many are not received but kept here just in case we see them

local function basic_set_handler(self, device, cmd)
  log.debug("------ Unexpected Received basic set handler")
end


local function basic_report_handler(self, device, cmd)
  log.debug("------ Unexpected Received basic report handler")
end

local function switch_binary_report_handler(self, device, cmd)
  log.debug("------ Unexpected received switch report handler")
end

local function association_report_handler(self, device, cmd)
  log.debug("------ Unexpected received association report")
  end

local function association_groupings_report_handler(self, device, cmd)
  log.debug("------Unexpected received association groupings report")
  end


local function scene_controller_handler(self, device, cmd)
  log.debug("------ Unexpected received Scene Controller Conf report")
end

local function scene_actuator_conf_get_handler(self, device, cmd)
  log.debug("------ Unexpected received Scene_Actuator_Conf_Get")
end

local function scene_actuator_conf_report_handler(self, device, cmd)
  log.debug("------ Unexpected received Scene_Actuator_Conf_Report")
end

local function configuration_report_handler(self, device, cmd)
  log.debug("------ Unexpected received Configuration_Report")
end

local function switch_multilevel_handler(self, device, cmd)
  log.debug("------ Dimming was pressed.")
end

local function proprietary_handler(self, device, cmd)
  log.debug("------ Received mfg proprietary")
end

local function confReport_handler(self, device, cmd)
  log.debug("------ Unexpected Received conf report")

end

-- button (switch) was pressed 
-- Normalize to button 1-4, translate scenes 5-8 to button 1-4
-- If LED is off, then you get scenes 1-4
-- If LED is on, then you get scenes 5-8
-- don't care as we use the SmartThings state and toggle it if a button is pressed
-- Updating the bitmap will sync LED and SmartThings state to keep them in sync

local function scene_activation_handler(self, device, cmd)
  log.debug("------ Received Scene_Activation")
    local devices = build_device_list (self, device)
    log.debug ("Number of linked devices: ", #devices)

  local button = cmd.args.scene_id
  button = (button > 4) and (button - 4) or button
-- Allow for debounce, may get multiple messages for same press
-- Ignore if same scene within 2 seconds
  if ((button == device:get_field("lastScene")) and (os.difftime(os.time(), device:get_field("lastTime"))<2)) then
    log.debug("Repeated press")
  else
  -- Update history to new setting
    device:set_field("lastScene", button)
    device:set_field("lastTime", os.time())
    local switchState = device:get_latest_state (switchNames[button], "switch", "switch")
-- toggle the switch
    local action = ((switchState == "on") and capabilities.switch.switch.off) or capabilities.switch.switch.on
-- apply the new state to all devices
    for index = 1,#devices do
      devices[index]:emit_component_event(device.profile.components[switchNames[button]], action())
    end
    update_LEDs (self, device)
  end
end

-- Switch was selected using the SmartThings app
-- 1) Build the list of devices that should be updated based on Sync option
-- 2) emit the event to turn on the switch
-- 3) update LED's

local function handle_on(driver, device, command)
  local devices = build_device_list (driver, device)
  for index = 1,#devices do
    devices[index]:emit_component_event(device.profile.components[command.component], capabilities.switch.switch.on())
    end
  update_LEDs (driver, device)
end


local function handle_off(driver, device, command)
  local devices = build_device_list (driver, device)
  for index = 1,#devices do
    devices[index]:emit_component_event(device.profile.components[command.component], capabilities.switch.switch.off())
    end
  update_LEDs (driver, device)
end

-- primarily used to associate the hub so that messages can be collected
-- If user selects to associate a switch with the scene for dimming, then add that device

local function set_associations (self, device)
  log.debug ("Updating associations")
  local hub = device.driver.environment_info.hub_zwave_id or 1
  log.debug ("Hub address: ", hub)
  for button = 1,4 do
    local node = device.preferences[switchNames[button]]
    log.debug ("Current setting for button ", button, "is: ", node)
    if (node ~= device:get_field ("switchAssoc"..button)) then
      log.debug ("Updating switch info for ", button, " value is :", node, "old value is: ", device:get_field("switchAssoc"..button))
      queue_command (device, Association:Remove({grouping_identifier = button, node_ids = {}}))
      queue_command (device, Association:Remove({grouping_identifier = button+4, node_ids = {}}))

      queue_command (device, Association:Set({grouping_identifier = button, node_ids = {hub, node}}))
      queue_command (device, Association:Set({grouping_identifier = button+4, node_ids = {hub, node}})) 
      queue_command (device, SceneControllerConf:Set({group_id = button, scene_id = button; dimming_duration = "default"}))
      queue_command (device, SceneControllerConf:Set({group_id = button+4, scene_id = button+4; dimming_duration = "default"}))
--     queue_command (device, SceneControllerConf:Get({group_id = button}))
--     queue_command (device, SceneControllerConf:Get({group_id = button+4}))
      device:set_field ("switchAssoc"..button, node, {persist = true})
      end
  end
end
  

local function device_added (self, device)
  log.debug ("*** device was added")
end

local function device_info_changed (self, device)
  log.debug("+++ device info was changed")
-- check if Settings were changed.
  set_associations (self, device)
  end

local do_configure = function(self, device)

  device:refresh()
  queue_command (device, ManufacturerSpecific:Get ({}))

  for button = 1, 4 do
    device:emit_component_event(device.profile.components[switchNames[button]], capabilities.switch.switch.off())
    device:set_field ("switchAssoc"..button, nil, {persist = true})
  end
  update_LEDs (self, device)
 -- device:emit_component_event(device.profile.components["main"], capabilities.switch.switch.off())
  device:set_field("lastScene", nil)
  device:set_field("lastTime", os.time())
  log.debug ("*** Fully configured device ****")

end

local driver_template = {
  NAME = "Leviton VRCS4",
  zwave_handlers = {
    [cc.BASIC] = {
      [Basic.SET] = basic_set_handler,
      [Basic.REPORT] = basic_report_handler
      },
    [cc.SWITCH_BINARY] = {
      [SwitchBinary.REPORT] = switch_binary_report_handler
    },
    [cc.ASSOCIATION] = {
    --  [Association.Groupings_REPORT] = association_handler
      [0x06] = association_groupings_report_handler,
      [Association.REPORT] = association_report_handler
    },
    [cc.SCENE_CONTROLLER_CONF] = {
      [SceneControllerConf.REPORT] = scene_controller_handler,
      [SceneControllerConf.GET] = scene_controller_handler
    }, 
    [cc.SCENE_ACTUATOR_CONF] = {
      [SceneActuatorConf.GET] = scene_actuator_conf_get_handler,
      [SceneActuatorConf.REPORT] = scene_actuator_conf_report_handler
    },
    [cc.SCENE_ACTIVATION] = {
      [SceneActivation.SET] = scene_activation_handler
    },
    [cc.SWITCH_MULTILEVEL] = {
 
      [0x04] = switch_multilevel_handler,
      [0x05] = switch_multilevel_handler
      },
  [cc.MANUFACTURER_PROPRIETARY] = {
    [0x00] = proprietary_handler
    },
 [cc.MANUFACTURER_SPECIFIC] = {
 --     -- GET
      [0x04] = proprietary_handler,
 --     -- REPORT
      [0x05] = proprietary_handler
      }
  },
    supported_capabilities = {
    capabilities.switch
  },
  --]]
    capability_handlers = {
    [capabilities.switch.ID] = {
      [capabilities.switch.commands.on.NAME] = handle_on,
      [capabilities.switch.commands.off.NAME] = handle_off,
      }
    },
    lifecycle_handlers = {
    init = do_configure,
    added = device_added,
    infoChanged = device_info_changed

  },
  can_handle = can_handle_LEVITON_VRCS4,

}

--[[
  The default handlers take care of the Command Classes and the translation to capability events 
  for most devices, but you can still define custom handlers to override them.
]]--

defaults.register_for_default_handlers(driver_template, driver_template.supported_capabilities)
local buttonSwitch = ZwaveDriver("Z-Wave Leviton 4-Button Scene Controller", driver_template)
buttonSwitch:run()
