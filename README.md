# Multiplexer
Six multitasking additions to iOS

http://moreinfo.thebigboss.org/moreinfo/depiction.php?file=multiplexerDp

### Features
- Secondary app in Reachability (Reach App)
- iOS 9-like "slide over" (Swipe Over)
- Mission Control with multiple desktops (Mission Control)
- Windowed multitasking (Empoleon)
- An app in a Notication Center tab (Quick Access)
- Backgrounding features (Aura)

### Wiki
See /wiki for some code tutorials.

### iOS 9 Update Status
- Empoleon: working
- fs daemon: working
- SwipeOver: fixed
- Reachability: fixed
- GestureSupport: fixed
- Backgrounding: fixed
- KeyboardSupport: hackily fixed but it works now
- MissionControl: initialization broken, otherwise fixed
- NCApp: fixed
- assertiond hooks: unknown
- backboardd hooks: unknown
- fake phone mode: unknown

see the update_status file for more info on the iOS 9 changes.

### API
There is a full public API (as opposed to the private/interval api and headers) that allows anyone to create addons, widgets, and tweaks (Tweakception!) for Multiplexer. 
The public api can be found in public_api. This api is less likely to change or be removed as opposed to the other headers and stuff.
For the end user's ease of use, please register your extensions with -[Multiplexer registerExtension:forMultiplexerVersion:]. I hope to also move the core functions into extensions, provide api requirements, etc at some point.

Currently it is only compatible with iOS 8, however some measures have been taken to ease the process of making it compatible with other iOS editions (whether future or past).
There are some "options" or features that are in here but are disabled or otherwise removed because either they don't work or there's no point having them. 
