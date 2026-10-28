# ret_Cinema

A standalone addon for WoW Forever and WoW Retail. The same files are used for
both clients. No dependency on Cinematic, DynamicCam, or any external library.

Declared client interface versions: Forever 1.60.1 (`16001`), Retail 12.1.0
(`120100`), and Retail 12.1.5 (`120105`).

## Installation

Copy this entire `ret_Cinema` folder directly into the game's `Interface/AddOns`
folder. The resulting path must be `Interface/AddOns/ret_Cinema/ret_Cinema.toc`.
WoW does not discover addons nested inside another addon's folder.

Install a copy in each client you play:

- **Retail:** `_retail_/Interface/AddOns/ret_Cinema/`
- **Forever:** `_forever_/Interface/AddOns/ret_Cinema/` (or
  `_classic_beta_/Interface/AddOns/ret_Cinema/` for the Forever beta).

Each client stores its own preferences and keybindings independently.

Restart the game if it was running during installation. Enable ret_Cinema in
the addon list. Disable Cinematic to stop its CPU usage and avoid overlapping
letterbox effects.

## Settings

Open ret_Cinema from the Addon Compartment, the minimap icon, or `/retcin`
(`/retcinema` is also supported). The main **ret_Cinema** page links to its native
child categories, in order: **General**, **Effect**, **Lens**, **Profiles**, **Support**.
Lens appears only while at least one enabled Effect also has **Apply Effect to Lens**
checked. Disabling an Effect retains its saved Apply preference but removes its
Lens row; if no eligible Effects remain, the Lens category disappears.

**General** contains the description, minimap switch, Effect switches and credits.
**Effect** groups the **HideUI**, **Letterbox**, **CameraShift**, **FOV**, and
**SmoothMotion** tabs, wrapping after at most four tabs per row. It contains no
Lens tab. Effect controls are created only when their enabled tab is opened.

Page titles use the standard `GameFontHighlightHuge` and
`Options_HorizontalDivider` styling. The visible **ret_** prefix is lime green
(`#9ACD32`) in addon titles, credits and text. Other hyperlinks are white; Lens
navigation stays blue. Tabs for Effects under consideration are orange, while
unavailable controls remain gray. Identifiers, paths and copied URLs are unchanged.

### General

The description reads `## Notes:` directly from `ret_Cinema.toc`.
**Show minimap icon** controls the draggable minimap button.
**Enable Effect modules:** enables or disables each Effect's runtime and settings
tab. Disabling an Effect immediately stops its work and restores its temporary
changes. Existing Lens assignments are retained. Enable switches use four cells
per row. A Lens row requires both the General enable switch and the Effect's own
**Apply Effect to Lens** switch.

The General hint is: "Turn on the Permanent Effect as well as applying this
Effect to your Lens." Permanent and Lens settings are independent.

Credits include icon 136034 and links to ret_, Cinematic, and DynamicCam.
**Need a bug fix or a new feature? Ask for it!** above the credits provides the GitHub issue address for a bug
report or feature request. Links open a selected, read-only address field;
Ctrl+C copies it and closes the field after the key is released.

### HideUI

Temporarily hides the interface and world names for players, NPCs, pets, and
focused units on clients exposing those settings. Exact original values return
on a second Lens-button press, Esc, Effect disable, or logout. Automatic UI shows
and combat do not cancel the Effect.

**Permanent Hide UI** is a disabled placeholder. Its tooltip reads:
"Not sure yet you really need this :)".
**Apply Effect to Lens** makes HideUI available in Lens and through `/retcin hideui`.

### Letterbox

**Permanent Letterbox** enables persistent black bars with their own **Permanent bar height**
slider and editable percentage. **Apply Effect to Lens** reveals a separate
**Lens bar height** control. **Enable animation** appears next to **Apply Effect to Lens**
only while Apply is checked.
Each bar supports 0–25% of screen height in 0.1% steps.

The permanent height may be greater or smaller than the Lens height. Activating
Lens smoothly moves the bars to its height; a second press or Esc restores the
current permanent height, or removes the bars if Permanent Letterbox is disabled.
Turning off Apply removes only the Lens Effect and leaves permanent bars intact.
Saved permanent bars reappear at login or reload; the Lens Effect starts inactive.

### CameraShift

Before consent, only **Allow Blizzard experimental camera feature** is shown.
Checking it reveals **Permanent CameraShift** and **Apply Effect to Lens** above
the consent box, and a standard-size yellow explanation below it. Their separate
controls are named **Permanent shoulder camera offset** and **Lens shoulder camera
offset**, from -15 to 15 in 0.1 steps. Consent is saved; withdrawing it hides the
controls and restores the original camera settings. The consent checkbox reserves
the same position as when both control groups are expanded, so it never jumps.

CameraShift changes only shoulder offset and the two motion-sickness settings
needed for it. It does not run `ActionCam full` or enable unrelated ActionCam
features. Camera changes can cause visual discomfort. After explicit consent,
ret_Cinema dismisses `EXPERIMENTAL_CVAR_WARNING` only immediately following its own
camera CVar writes. It leaves unrelated warnings alone. Blizzard's warning has no
acceptance operation beyond dismissing the dialog; its Disable button resets
experimental CVars ([Blizzard dialog source](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_StaticPopup_Game/GameDialogDefs.lua)).
Warning timing and appearance still require an in-game check on Retail and Forever.

Activating a Lens remembers the live camera settings and smoothly applies its
chosen offset. A second press or Esc returns to Permanent CameraShift when enabled,
otherwise to the saved settings. Both directions use a 0.35-second transition.
Changes to permanent settings while a Lens is active take effect when that Lens
exits. Disabling the Effect, withdrawing consent, or logging out restores the
original camera immediately. Login/reload first recovers an interrupted original
snapshot, then reapplies the saved permanent preference. Zooming and combat do not
cancel Lens Effects.

For both numeric controls, Enter or leaving the field commits an edit, and Esc
cancels it. Decimal commas and dots are accepted. Out-of-range values are clamped;
invalid values leave the current setting unchanged. Unsupported clients disable
camera controls and show a message.

### FOV and SmoothMotion

Both Effects are under consideration and have orange tabs. Their Permanent and
Apply controls and sliders are inactive placeholders. FOV shows **Permanent FOV**,
**Apply FOV to Lens**, and a field-of-view slider; SmoothMotion shows a smoothing
slider. Neither creates a runtime Effect, Lens row, shortcut or camera CVar change.

### Lens

The table has **Effect**, **Lens button**, and **Add to Combined Lens** columns.
With two or more Combined Lenses, the last column becomes **Add to a specific
Combined Lens**, with a numbered checkbox for each lens. Hover a checkbox to see
both the Effect name and the target Combined Lens number. Click a slot, then press a key combination. Right-click clears the slot;
Esc cancels capture. An individual Effect offers a second slot below its first,
separated by **or**, once the first key is assigned. Unassigned slots show
**Not bound** in gray. Binding status text is 1.5 times the standard font size.
Bindings cannot be edited during combat; existing shortcuts and Effects still work.

The Combined Lens container remains below the individual Effects. **Add another
Combined Lens** adds another configuration, up to five. The first lens is named
**Combined Lens** until a second is added, then becomes **Combined Lens 1**.
Each lens always offers two binding slots and its own exit selector. Dividers
separate the configurations inside the same container. New lenses start with no
Effects selected and do not change existing selections or keys.

Hover an Effect name for its chat command; hover a Combined Lens name for its
numbered command. Chat commands and shortcuts call the same toggle functions;
they do not execute a stored macro.

The **Second Button press exit:** selector provides:

- **All Lenses**: a second Combined press ends every active temporary Lens Effect,
  including Effects not added to Combined, playing their exit animations.
- **Only added Lenses**: restores the states captured for the Effects added when
  Combined was first pressed. Unselected Lens Effects stay as they are.

Permanent Effects remain the baseline in either case. Esc ends all temporary Lens
Effects and returns to permanent/original settings. Esc retains its normal game
menu behavior. Each Combined Lens remembers its own activation snapshot, including
when lenses share Effects. Esc and **All Lenses** clear all Combined snapshots.
Disabling or unapplying an Effect removes it from every active snapshot.
The first Combined Lens retains its old binding ID; lenses 2–5 have separate IDs.
Bindings remain in the game's current account/character binding set.

## Chat commands

Each command toggles its Lens Effect; the Effect must be enabled in General and
have **Apply Effect to Lens** checked. CameraShift also requires consent.

- `/retcin hideui`
- `/retcin showletterbox`
- `/retcin camerashift`
- `/retcin combinedlens` or `/retcin combinedlens1` (first Combined Lens)
- `/retcin combinedlens2` through `/retcin combinedlens5` (only after adding them)
- `/retcin` (settings)

`/retcinema` accepts the same commands. The redundant `/retcin combined` alias
has been removed, along with the unused macro-text generation helper.

## Profiles

The **Profiles** child category provides an active-profile selector, **Create New**,
**Export**, **Import**, **Copy from profile**, and **Delete Profile** controls.
New profiles use default settings and become active immediately. Copy replaces
the active profile's preferences with those of the selected source, retaining the
active profile's name. Deletion requires confirmation; the active profile cannot
be deleted. Changes are blocked in combat.

Existing settings automatically become the **Default** profile. Preferences are
saved when switching profiles or logging out. Before changing profiles, temporary
Effects and original camera/name CVars are restored; the new profile's permanent
Effects are then applied. Recovery snapshots and experimental-camera consent are
account-wide and excluded from copies and exports. WoW key assignments remain in
the game's current binding set and are not changed by profile operations.

Exports use the versioned `RETCINEMA_PROFILE:2|...` format, including the Combined
Lens count and each lens's selections and exit policy. Version 1 exports remain
supported and import with one Combined Lens. Imports are parsed as
data, never executed, and validate required fields, types, ranges, names, size,
and duplicates. Import creates and activates a new profile, adding an Imported
suffix if the name already exists. Unknown fields and formats are rejected.

## Support

The **Support** child category has a CurseForge placeholder marked **Coming soon**
until a project URL is available. **boosty.to / Copy link** provides
`https://boosty.to/ret_ro`. The Retail Horde recipient is
**Хардрес-РевущийФьорд**; its copy button preserves the exact in-game identifier.

## Performance and recovery

Disabled Effects have no animation callbacks or periodic work. Settings pages
and their optional permanent controls are built only when opened or needed.
Bars and the camera animator are allocated on first use. An OnUpdate callback
runs only during a transition or minimap drag, and is removed on completion.
Permanent Effects have no continuous Lua updates while stationary.

The Escape listener is shown only while temporary Lens Effects or a Combined
snapshot is active. Lens listens for binding updates only while its page is open;
hidden pages do not build newly added Combined controls until opened.
A small visibility hook keeps HideUI active if the game shows the interface.
Camera-warning handling is installed only after a consented camera write and
checks only the named warning and proximity to ret_Cinema's own writes.

Original names and camera CVars are recovered on ordinary logout or reload.
Abnormal process termination cannot guarantee that saved state reached disk.
Disabling an Effect does not unload its Lua or destroy already-created frames;
a reload avoids creating unused settings and runtime frames. The addon does not
load DynamicCam libraries.

## Editing UI text

Change `## Notes:` in `ret_Cinema.toc` for General's addon description. Change
`ns.generalHint`, `ns.lens`, or entries in `ns.effects` in `Core.lua` for the
corresponding headings, hints, and Effect names. `description` is the larger
yellow heading, and `hint` is the standard-size yellow explanation below it.
Other labels and controls are in `Options.lua`.

`DESCRIPTION_FONT_SCALE = 1.5` in `Options.lua` controls description size relative
to the normal WoW font. All addon UI text is English-only. Increment `## Version:`
in the TOC for every batch of addon changes, then reload the UI.
`ns.ColorRet` and `ns.retColor` in `Core.lua` define the visible prefix color;
`## Title:` in the TOC uses the same color for the game's addon list.

## Credits

Inspired by the screenshot and letterbox features of Cinematic by Andrew Casals.
[Original Cinematic](https://github.com/andrewcasals/Cinematic).
Shoulder-offset behavior is inspired by
[DynamicCam](https://github.com/Mpstark/DynamicCam) by mpstark and LudiusMaximus.
ret_Cinema implements its own minimal controls without zoom curves or a dependency.
