# SmartThings Edge Driver for Leviton VRCS4-M0Z and VRCS4-MRZ(Beta)

Edge Driver implements the Leviton VRCS4 device as a group of 4 on/off switches controlled by corresponding buttons on the VRCS4 device. Using SmartThings allows you to configure routines to integrate each switch to control other SmartThings devices.
The VRCS4 is an older device and discontinued by Leviton. I have a couple of them, they have yet to fail, and are very convenient to use as a 4-switch device in a single gang footprint. While originally intended as a Scene Controller by Leviton, this was converted to a 4-port switch using a Groovy DTH several years ago. I have adapted this into an Edge Driver and added a few refinements.
This driver supports the Leviton VRCS4-M0Z and VRCS4-MRZ models of the switch consisting of 4 buttons (with LEDs) and a dimmer toggle.  
M0Z consists of 4 switches and a dimmer toggle.  The device does not contain an embedded load.
MRZ consists of 4 switches, dimmer toggle and includes an embedded load.  When you pair the MRZ into SmartThings, two devices are actually created. The scene controller which will use the VRCS4 driver and a Z-Wave switch which will control the internal load.
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


  - id: "Leviton ZRCS4-M0Z"
    deviceLabel: Leviton 4 Button Switch
    genericType: 0x01
    specificType:
      - 0x00
    commandClasses:
      supported:
        - 0x2D
```


## To install

* Use the channel link (https://bestow-regional.api.smartthings.com/invite/3X213RRZ9yjR?) to enroll install the driver on your hub.
* Use the SmartThings app to exclude your device (there is currently no way to switch from a Groovy DTH to an Edge driver except by deleting and then adding the device).
* Use Add device → Scan nearby in the SmartThings app to include your device. Your device should pick up this driver if the fingerprint matches.

## Code

github.com: 
https://github.com/harobinson/VRCS4-M0Z

## Settings

* Sync: Turning on Sync will create an equivalent of an n-way switch for all VRCS4’s in your hub what have the Sync option available. E.g. turning on a switch will be mirrored on every other Sync’d VRCS4 (corresponding switch will be turned on and LED will be lit).
* Dimming Duration: Number of seconds to change level from 100 to 0 when dimming switch is held down (default = 8 seconds)

## Caveats
* Automation Routines:  While you can select any button in the IF clause, only the Switch 1 can be selected in the THEN clause.
* Scenes:  Only Switch 1 can be selected for an Action in a scene.
* You can alternatively use Rules which doesn’t have this restriction.  This has been reported as a bug/feature to SmartThings.

## Rules
As the switches simply control their internal state, it is natural to associate the switch state with other physical switches or devices.  The rule template below will mirror a VRCS4 button with a dimming switch.  The rule consists of six actions:
* If the VRCS4 button changes to On, then set the target switch to On.
* If the VRCS4 button changes to Off, then set the target switch to Off.
* If the VRCS4 button’s dimming level changes, then change dimming level of target switch.
* If the target switch changes to On, then set VRCS4 button to On.
* If the target switch changes to Off, then set VRCS4 button to Off.
* If the target switch dimming level changes, then change dimming level of the VRCS4.

To use the rules:
* Import the file "ruleTemplate.json"
* Substitute all occurrences of <VRCS4 Switch> to the VRCS4 device id.  “Make sure to remove the angle brackets.”
* Select “main, switch2, switch3, or switch4” in the component field currently marked <main, switch2, switch3, or switch4>, remove the angle brackets
* Create a separate rule for each switch (main, switch2, switch3, and switch4)
* Install the rule either using the smartthings cli or using the Smartthings API Browser — https://api-browser-plus.pinsky.us
* Repeat for each button.

### Note:  
* I have sometimes encountered the “flashing” phenomena where the rule seems to loop forever in an off/on sequence.  I can solve this by disabling the rule and then re-enabling it.  Possible with the Smartthings Browser.

## Internal implementation

Basic operation is as follows:
* Associations are configured for groups 1-8 with groups 1 and 5 association with the first button, group 2 and 6 for the second button, and so forth (Association:Set)
* ssociations are only configured to the hub device and not to the target devices.  Target devices are controlled using SmartThings events
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


## Bugs

* Rotating button on first press from SmartThings UI.  When the driver is first initialized, pressing a switch ON may result in constantly rotating button.  Pressing Back Arrow and reselecting the device will clear the condition and operations will work correctly after this initial behavior.


## Acknowledgments

* Brian Dalhem (@bdahlem) for the original DTH groovy code.
* Jason Brown (@j9brown) for documenting Leviton proprietary command for LED control.
* The SmartThings community (@jdroberts, @h0ckeysk8er, @philh30) for answering my newbie questions on edge drivers.

