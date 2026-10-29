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
(`/retcinema` is also supported). The main **ret_Cinema** page contains the
description, minimap switch, Effect switches, Advanced Cinematographer and credits.
Its child categories are **Effect**, **Lens**, **Trigger**, **Profiles**, and **Support**.
There is no separate General category.

Lens appears only while at least one enabled Effect also has **Apply Effect to Lens**
checked. Disabling an Effect retains its saved Apply preference but removes its
Lens row; if no eligible Effects remain, the Lens category disappears.

**Effect** shows one centered selector for the current Effect. Its dropdown lists
enabled **HideUI**, **Letterbox**, **CameraShift**, **FOV**, and **SmoothMotion**.
The selected Effect uses the standard yellow text; there are no side arrows or
extra divider beneath the selector. Effect controls are created only
when their enabled page is opened.
Descriptions and hints have a blank-line gap before the controls.

Page titles use the standard `GameFontHighlightHuge` and
`Options_HorizontalDivider` styling. The visible **ret_** prefix is lime green
(`#9ACD32`) in addon titles, credits and text. **Cinema** in the addon title,
other hyperlinks and Lens navigation are blue. **FOV** and **SmoothMotion** names
are gray in both the main-page switches and the Effect selector. Other options
under consideration and **Experimental** labels are orange. Identifiers, paths and copied URLs are unchanged.

### Main ret_Cinema page

The description reads `## Notes:` directly from `ret_Cinema.toc`.
**Show minimap icon** controls the draggable minimap button.
**Enable Effect:** enables or disables each Effect's runtime and settings
tab. Disabling an Effect immediately stops its work and restores its temporary
changes. Existing Lens assignments are retained. Enable switches use four cells
per row. A Lens row requires both the main-page enable switch and the Effect's own
**Apply Effect to Lens** switch.

The main-page hint is: "Turn on the Permanent Effect as well as applying this
Effect to your Lens." Permanent and Lens settings are independent.

**Advanced Cinematographer** appears beside **Show minimap icon**. Checking it
turns its label into a button opening five gray, disabled options. Its tooltip
reads "Experimental. Allow access to additional options.", with Experimental in
orange. The planned options are:
**Letterbox Transparency**, **Letterbox Animation speed**, **CameraShift Animation
speed**, **Second Lens button**, and **More Combined Lens**. Each disabled checkbox
has an orange **Under consideration** tooltip. The Advanced switch is saved with
the profile; these placeholders do not alter existing Effect or Lens behavior.

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
**Lens bar height** control. Letterbox animations are always enabled; the old
**Enable animation** switch and preference are removed. Each control occupies
less than half the available row width, leaving room for another beside it.
Each bar supports 0–25% of screen height in 0.1% steps.

The permanent height may be greater or smaller than the Lens height. Activating
Lens smoothly moves the bars to its height; a second press or Esc restores the
current permanent height, or removes the bars if Permanent Letterbox is disabled.
Turning off Apply removes only the Lens Effect and leaves permanent bars intact.
Saved permanent bars reappear at login or reload; the Lens Effect starts inactive.

### CameraShift

Enabling **CameraShift** in **Enable Effect:** on the main page also grants consent
to its experimental camera changes. The checkbox tooltip explains this choice.
Without prior consent, CameraShift starts disabled until the checkbox is enabled.
The Effect page contains **Permanent CameraShift** and **Apply Effect to Lens**
with their compact, editable **Permanent shoulder camera offset** and
**Lens shoulder camera offset** sliders, from -15 to 15 in 0.1 steps. There is no
separate permission checkbox or camera-settings explanation block on this page.

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

Both Effects are under consideration and have gray names in the switches and selector. Their Permanent and
Apply controls and sliders are inactive placeholders. FOV shows **Permanent FOV**,
**Apply FOV to Lens**, and a field-of-view slider; SmoothMotion shows a smoothing
slider. Neither creates a runtime Effect, Lens row, shortcut or camera CVar change.

### Lens

The table has **Effect**, **Lens button**, and **Add to Combined Lens** columns.
With two or more Combined Lenses, the last column becomes **Add to a specific
Combined Lens**, with numbered checkboxes arranged horizontally for each Effect.
A fixed extra gap before checkbox 2 separates the first lens from additional ones
and aligns that column across all Effect rows. Hover a checkbox to see
both the Effect name and the target Combined Lens number. Click a slot, then press a key combination. Right-click clears the slot;
Esc cancels capture. An individual Effect offers a second slot below its first,
separated by **or**, once the first key is assigned. Unassigned slots show
**Not bound** in gray. Binding status text is 1.5 times the standard font size.
Bindings cannot be edited during combat; existing shortcuts and Effects still work.

The Combined Lens container remains below the individual Effects. Small **+** and
**-** buttons sit together at its bottom. **+** adds another configuration, up to
five; **-** hides the last additional lens, down to one. Both buttons remain
visible and disable at their limits; hiding is blocked in combat. Hiding an active
lens restores its activation snapshot and keeps its settings, selections and game
keybindings. **+** reveals the same slot with those preferences and shortcuts.
A shortcut for a hidden slot performs no Lens action until the slot is shown again.

The first lens is named **Combined Lens** until a second is added, then becomes
**Combined Lens 1**. Each lens always offers two binding slots and its own
**Escape Button** checkbox beneath its two key slots. To the right of the first
slot, a comma-separated list shows the enabled Effects selected for that lens.
Dividers separate the configurations inside the same
container. Fresh slots start with no Effects selected; re-shown slots retain theirs.

When two or more Combined Lenses exist, each Effect row has a gear button to the
right of its membership checkboxes. It opens an Effect settings window with a
centered **Combined Lens 2–5** selector. Letterbox and CameraShift each show only
the independent height or shoulder-offset slider; there is no Apply checkbox or
Use Effect settings switch in those dialogs. Membership is managed by the table.
HideUI retains its membership checkbox and has no numeric settings. Changes apply
on the next activation; the first Combined Lens uses the main Effect settings.

Custom numeric settings are saved with the profile and do not change other
lenses or permanent settings. Activating a custom Effect replaces its current
Lens value if already active; exiting restores the prior Lens value and active
state. Esc and Escape Button restore permanent/original settings as usual.

Hover an Effect name for its chat command; hover a Combined Lens name for its
numbered command. Chat commands and shortcuts call the same toggle functions;
they do not execute a stored macro.

For each Combined Lens, **Escape Button** controls its second press:

- Checked: the first press applies its Effects. A second consecutive press exits
  all temporary Lens Effects with their return animations. Activating any other
  individual or Combined Lens resets the sequence, so the next press applies its
  Effects again. Permanent settings remain the baseline.
- Unchecked: restores only the states captured for its selected Effects at entry.
  Unselected Lens Effects keep their current state.

Permanent Effects remain the baseline in either case. Esc ends all temporary Lens
Effects and returns to permanent/original settings. Esc retains its normal game
menu behavior. Each Combined Lens remembers its own activation snapshot, including
when lenses share Effects. Esc and a checked **Escape Button** clear all Combined snapshots.
Disabling or unapplying an Effect removes it from every active snapshot.
The first Combined Lens retains its old binding ID; lenses 2–5 have separate IDs.
Bindings remain in the game's current account/character binding set.

## Chat commands

Each command toggles its Lens Effect; the Effect must be enabled on the main ret_Cinema page and
have **Apply Effect to Lens** checked. CameraShift also requires consent.

- `/retcin hideui`
- `/retcin showletterbox`
- `/retcin camerashift`
- `/retcin combinedlens` or `/retcin combinedlens1` (first Combined Lens)
- `/retcin combinedlens2` through `/retcin combinedlens5` (only after adding them)
- `/retcin` (settings)

`/retcinema` accepts the same commands. `/retcin combinedlens` and
`/retcin combinedlens1` address the same first lens. The old `/retcin combined`
alias and unused macro-text generation helper remain removed.

## Trigger

The **Trigger** child page connects one individual or Combined Lens to the game's
**Run/Walk** action. Enable Trigger and select its Lens. The page shows the current
native Run/Walk key and explains when the selected target is unavailable.
Each Run/Walk action toggles the selected Lens while retaining the normal movement
action. The existing keybinding is never reassigned. Changing that binding in
WoW automatically changes which key activates the Trigger.

The implementation post-hooks Blizzard's `ToggleRun`, called by the `TOGGLERUN`
binding ([Blizzard binding source](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_FrameXML/Bindings_Standard.xml)).
The hook is installed only after enabling Trigger. It performs no keyboard polling,
OnUpdate work, timers or new keybinding registrations. Once installed it remains
a lightweight no-op when disabled. Disabled, unapplied, empty or hidden targets
perform no Lens action; the game Run/Walk action still executes. Trigger preferences
are stored per profile. The feature needs an in-game check on both supported clients.

## Profiles

The **Profiles** child category provides an active-profile selector, **Create New**,
**Export**, **Import**, **Copy from profile**, and **Delete Profile** controls.
Selectors display a dropdown arrow and left-aligned value. **Create New** is
right-aligned beneath the active-profile selector.
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

Exports use `RETCINEMA_PROFILE:5|...`, including Trigger preferences and independent
Combined Lens values. Versions 1–4 remain supported; version 1 imports with one
Combined Lens. Existing inherited values are copied into each additional lens
once during migration, while old custom values are preserved. The inheritance
flags are then removed from active settings and new exports.
Old animation preferences are validated on import and then discarded, so an old
export cannot disable Letterbox animations. Imports are parsed as
data, never executed, and validate required fields, types, ranges, names, size,
and duplicates. Import creates and activates a new profile, adding an Imported
suffix if the name already exists. Unknown fields and formats are rejected.

## Support

The **Support** child category has a CurseForge placeholder marked **Coming soon**
until a project URL is available, with the current TOC version beneath it in small
gray text. **boosty.to / Copy link** provides
`https://boosty.to/ret_ro`. The Retail Horde recipient is
**Хардрес-РевущийФьорд**, displayed in the Paladin class color; its copy button
preserves the exact in-game identifier.

Below the character is **Wish Board**, a local feature browser with statuses such
as Under consideration and In development. Click a feature to read its description.
It is built only on first use, sends no votes or messages, and runs no background work.

## Performance and recovery

Disabled Effects have no animation callbacks or periodic work. Settings pages
and their optional permanent controls are built only when opened or needed.
Bars and the camera animator are allocated on first use. An OnUpdate callback
runs only during a transition or minimap drag, and is removed on completion.
Permanent Effects have no continuous Lua updates while stationary. Hidden
Letterbox bars unregister their screen/scale events and size handler; their layout
is refreshed when shown again. Unrelated popups return immediately from the camera
warning hook.

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

The CPU percentage alone cannot identify a live background loop. Blizzard's addon
list tooltip uses session-average profiling, which includes loading and settings
work ([Blizzard profiler display](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_AddOnList/AddonList.lua)).
Current in-game profiling is needed to explain a specific 0.02% reading. The local
behavior tests verify that idle Effects have no OnUpdate handlers or screen events.

## Editing UI text

Change `## Notes:` in `ret_Cinema.toc` for the main page's addon description. Change
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
