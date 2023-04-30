# SmartThings Edge Driver for Leviton VRCS4-M0Z

Edge Driver implements the Leviton VRCS4 device as a group of 4 on/off switches controlled by corresponding buttons on the VRCS4 device. Using SmartThings allows you to configure routines to integrate each switch to control other SmartThings devices.
This driver supports the Leviton VRCS4-M0Z model of the switch consisting of 4 buttons (with LEDs) and a dimmer toggle.  
M0Z consists of 4 switches and a dimmer toggle.  The device does not contain an embedded load.
The basic features of the VRCS4 as implemented in this driver.
* The device exposes four independent On/Off dimming switches which can be controlled either from the device or via the SmartThings UI
* LEDs are automatically controlled based on the state of the switch (LED is on when the switch is on)
* Enabling Sync (in Settings) allows multiple VRCS4 switches to be paired for 3-way or multi-way operation. Any device, with Sync enabled, will mirror switch operations on all device that have Sync enabled. Out of box, Sync is disabled such that each Leviton VRCS4 device is managed independently.
* Dimming is supported using the bottom button.  Dimming up will automatically turn the switch on if it is currently off.  Dimming Duration in the Settings panel allows you to control the dimming rate.  For example, setting the Dimming Duration to 10 will result in a full dimming cycle (from 100 to 0) taking 10 seconds.  The default is 8 seconds.
* Dashboard displays the state of Switch 1.

## Fingerprints

```
  - id: "Leviton ZRCS4"
    deviceLabel: Leviton 4 Button Switch
    manufacturerId: 0x001D
    productType: 0x0802
    productId: 0x0261
```


## To install

* XXX
* Use the SmartThings app to exclude your device (there is currently no way to switch from a Groovy DTH to an Edge driver except by deleting and then adding the device).
* Use Add device → Scan nearby in the SmartThings app to include your device. Your device should pick up this driver if the fingerprint matches.

## Code

github.com: 
https://github.com/gbrossi76/SmartThings-VRCS4

## Settings

* Sync: Turning on Sync will create an equivalent of an n-way switch for all VRCS4’s in your hub what have the Sync option available. E.g. turning on a switch will be mirrored on every other Sync’d VRCS4 (corresponding switch will be turned on and LED will be lit).
* Dimming Duration: Number of seconds to change level from 100 to 0 when dimming switch is held down (default = 8 seconds)


## Internal implementation

Basic operation is as follows:
* Associations are configured for groups 1-8 with groups 1 and 5 association with the first button, group 2 and 6 for the second button, and so forth (Association:Set)
* Associations are only configured to the hub device and not to the target devices.  Target devices are controlled using SmartThings events
* Z-Wave Scenes (different than SmartThings Scenes) are configured in the same manner; associating each scene with the corresponding group (SceneControllerConf:Set)
* A top button press will send messages for group 1 if the LED is off, and group 5 if the LED is off.  Button 2 ties with group 2 and group 6, and so forth.
* A button press results in a SceneActivation message with the corresponding scene provided as a parameter.
* The appropriate SmartThings component event is generated to turn the switch on or off as appropriate.
* Debounce logic as the Leviton device typically generates multiple SceneActivation messages per button press.
* LEDs are controlled by using a proprietary Leviton command to the device.  
* The dimming button issues SmartThings switchLevel events 

If Sync is configured on multiple Leviton switches, both the SmartThings switch state, dimming levels, and LEDs are mirrored across all sync’ed devices.
The SmartThings UI displays 4 switches (Switch 1, Switch 2, Switch 3, and Switch 4) that can be controlled either from the SmartThings UI (LEDs are sync’ed) or on the physical device. You can connect them to a SmartThings device using automations (see limitations above) or rules.  Rules see the switches as main, switch2, switch3, and switch4.
You may see some LED flashes during operation but I observed that latency is acceptable.


## Acknowledgments

* (@harobison) for the original EDGE driver code.
* Brian Dalhem (@bdahlem) for the original DTH groovy code.
* Jason Brown (@j9brown) for documenting Leviton proprietary command for LED control.
