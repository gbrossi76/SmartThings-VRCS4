# VRCS4-M0Z
SmartThings Edge Driver for Leviton VRCS4-M0Z (Beta)
Edge Driver implements the Leviton VRCS4 device as a group of 4 on/off switches controlled by corresponding buttons on the VRCS4 device. Using SmartThings allows you to configure routines to integrate each switch to control other SmartThings devices.

The VRCS4-M0Z is an older device and discontinued by Leviton. I have a couple of them, they have yet to fail, and are very convenient to use as a 4-switch device in a single gang footprint. While originally intended as a Scene Controller by Leviton, this was converted to a 4-port switch using a Groovy DTH several years ago. I have adapted this into an Edge Driver and added a few refinements.

This driver supports the Leviton VRCS4-M0Z model switch consisting of 4 buttons (with LEDs) and a dimmer toggle.

The device exposes four independent On/Off switches which can be controlled either from the device or via the SmartThings UI
LEDs are automatically controlled based on the state of the switch
Enabling Sync (in the Settings) allows multiple VRCS4 switches to be paired for 3-way or multi-way operation. Any device with Sync enabled, will mirror switch operations on all device that have Sync enabled. Out of box, Sync is disabled such that each Leviton VRCS4 device is managed independently.
The following is NOT integrated with SmartThings and relies on the Z-Wave associations to function
– Dimming Up/Down (the fifth button) can be enabled to control dimming (see Settings below).
Note that this driver will NOT support the VRCS4-MRZ model which includes a embedded load switch.

Fingerprint

id: “Leviton ZRCS4”
deviceLabel: Leviton 4 Button Switch
manufacturerId: 0x001D
productType: 0x0802
productId: 0x0261
