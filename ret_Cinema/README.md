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
Its child categories are **Effect**, **Lens**, **Profiles**, and **Support**.
**LiteRP** appears after enabling it in Advanced Cinematographer.
There is no separate General category.

Lens appears only while at least one enabled Effect also has **Apply … to Lens**
checked. Disabling an Effect retains its saved Apply preference but removes its
Lens row; if no eligible Effects remain, the Lens category disappears.

**Effect** shows one centered selector for the current Effect. Its dropdown lists
enabled **HideUI**, **Letterbox**, **CameraShift**, **FOV**, and **SmoothMotion**.
The selected Effect uses the standard yellow text, with previous/next arrows
beside its selector. Disabled Effects are skipped and navigation wraps around.
There is no extra divider beneath the selector. Effect controls are created only
when their enabled page is opened.
The current page number and total number of enabled Effects appear beside the selector.
Descriptions and hints have a blank-line gap before the controls.

Page titles use the standard `GameFontHighlightHuge` and
`Options_HorizontalDivider` styling. The visible **ret_** prefix is lime green
(`#9ACD32`) in addon titles, credits and text. **Cinema** in the addon title,
other hyperlinks and Lens navigation are blue. Functional **FOV** uses the normal
active text colors; **SmoothMotion** remains gray. Other options
under consideration are orange. **[Experimental]** uses the native raid leader chat color,
warning text uses the system chat color, and **LiteRP** uses the emote chat color.
Identifiers, paths and copied URLs are unchanged.

### Main ret_Cinema page

The description reads `## Notes:` directly from `ret_Cinema.toc`.
**Show minimap icon** controls the draggable minimap button.
**Enable Effect:** enables or disables each Effect's runtime and settings
tab. Disabling an Effect immediately stops its work and restores its temporary
changes. Existing Lens assignments are retained. Enable switches use four cells
per row. A Lens row requires both the main-page enable switch and the Effect's own
**Apply … to Lens** switch.

The main-page hint is: "Turn on the Permanent Effect as well as applying this
Effect to your Lens." Permanent and Lens settings are independent.

The addon starts in Simple mode: opaque bars up to 25%, standard animation
durations, one key slot and capacity for up to three Combined Lenses (starting with one).
**Advanced Cinematographer** appears
beside **Show minimap icon**, with a permanent button beside its checkbox.
The button stays gray and disabled until checked. Its window uses **+ / −** disclosure buttons for the normal
**Effect → HideUI / Letterbox / CameraShift / FOV** and **Lens** groups. Their
names are yellow; these buttons do not change feature preferences. Checkboxes
expose optional settings without enabling the actual Effect or RP action.
The experimental LiteRP switch uses a raid leader-colored **[Experimental]** marker
and an emote-colored **LiteRP** name. Its children
have no repeated markers. **Move** and **Stay** are yellow headings with disclosure
buttons in Advanced and no enable switches or runtime gates. Select the individual
Walk, Sit, Lay, Lean and GoOffline settings to show on LiteRP. Their separate
checkboxes on that page enable the actions. Hiding an action stops its runtime
work while retaining its saved preference; collapsing a disclosure group only
hides that group within Advanced and preserves availability.
Controls are built only when their group is expanded:

- **HideUI:** Hide interface elements and Hide creature names controls.
- **Letterbox:** **Custom Letterbox transparency**, **Custom Letterbox animation duration**, and permission to raise each bar to 50%.
- **CameraShift:** **Custom CameraShift animation duration**, Head bob and Follow the target controls.
- **FOV:** **Custom FOV animation duration**.
- **Lens:** **Additional keybind button** and **Combined Lenses up to 5**.
- **LiteRP:** walking, posture and cinematic logout integration.

Expose the individual settings you need, then configure them on the corresponding page. The master switch and all feature
preferences are stored per profile. Switching back to Simple mode exits temporary
Lenses, caps visible bars at 25%, and hides advanced controls. Stored values,
additional Lens configurations and game keybindings are retained. Hidden Combined
Lens shortcuts are inactive until revealed again. The second-key option controls
the editor; previously assigned native game keys are retained.
Clicking the Advanced button again closes its window. Esc is consumed by the
topmost addon dialog, closing only that dialog and leaving game settings open;
other keys continue to propagate.
Advanced, gear, GoOffline, profile, copy-link and Too-Doo windows have a 90% opaque
background and a top-right close button, without a redundant bottom Close button. Advanced has a yellow title and a header divider. Two more blank text lines precede the feedback link on the main page.

Credits include icon 136034 and links to ret_, Cinematic, and DynamicCam.
**Need a bug fix or a new feature? Ask for it!** above the credits provides the GitHub issue address for a bug
report or feature request. Links open a selected, read-only address field;
Ctrl+C copies it and closes the field after the key is released.

### HideUI

Temporarily hides the interface and world names for players, NPCs, pets, and
focused units on clients exposing those settings. Exact original values return
on a second Lens-button press, Esc, Effect disable, or logout. Automatic UI shows
and combat do not cancel the Effect.

**Permanent HideUI** is a disabled placeholder. Its tooltip reads:
"Not sure yet you really need this :)".
**Apply … to Lens** makes HideUI available in Lens and through `/retcin hideui`.
HideUI hides both the interface and creature names by default. Advanced exposes
**Hide interface elements** and **Hide creature names** beneath **Apply HideUI to
Lens** while Apply is checked. Checking either control hides that part; clearing
it leaves that part visible. The same names and semantics apply to every Combined
Lens. Hiding a control through Advanced clears its actual checkbox and restores
standard HideUI behavior, which hides both parts. The HideUI gear is disabled
until at least one of these controls is exposed.

Applying another Combined Lens with identical HideUI settings keeps the UI hidden
without briefly restoring it. Ordinary overlapping Lenses retain shared ownership
until the last one is restored. An Escape Button can exit an identical scene;
when another Lens has added an Effect, its first press replaces that scene with
its own Effects, and the next press exits.

### Letterbox

**Permanent Letterbox** enables persistent black bars with their own **Permanent bar height**
slider and editable percentage. **Apply … to Lens** reveals a separate
**Lens bar height** control. Letterbox animations are always enabled; the old
**Enable animation** switch and preference are removed. Each control occupies
less than half the available row width, leaving room for another beside it.
Each bar supports 0–25% of screen height in 0.1% steps, or up to 50% with the
corresponding Advanced option. Two 50% bars cover the entire screen.
**Custom Letterbox animation duration** appears when exposed in Advanced.
Checking it reveals the duration slider and exact-value input and enables that
layer's saved custom duration. Unchecking it uses the default duration without
erasing the saved value. Permanent, ordinary Lens and additional Combined Lens
settings keep independent enable states and durations.
Advanced controls provide opacity from 0–100% and transition duration from 0.1–5
seconds, independently for permanent settings, the ordinary Lens and each
additional Combined Lens.
Disabling Permanent Letterbox uses the default return duration (0.5 seconds),
regardless of the saved duration for its now-inactive permanent settings.

The permanent height may be greater or smaller than the Lens height. Activating
Lens smoothly moves the bars to its height; a second press or Esc restores the
current permanent height, or removes the bars if Permanent Letterbox is disabled.
Turning off Apply removes only the Lens Effect and leaves permanent bars intact.
Saved permanent bars reappear at login or reload; the Lens Effect starts inactive.

### CameraShift

Follow the target enables native enemy and interaction focus and temporarily
removes the combat-only target-follow restriction (`CameraFollowTargetCombat`)
on clients exposing it. The previous value is restored when focus is no longer
used, on Lens exit and on Effect disable. Friendly-target tracking needs an
in-game check on each client; this does not replace the game camera with a
scripted tracking loop. Unsupported CVars are left untouched.

Enabling **CameraShift** in **Enable Effect:** on the main page also grants consent
to its experimental camera changes. The checkbox tooltip explains this choice.
Without prior consent, CameraShift starts disabled until the checkbox is enabled.
The Effect page contains **Permanent CameraShift** and **Apply … to Lens**
with their compact, editable **Permanent shoulder camera offset** and
**Lens shoulder camera offset** sliders, from -15 to 15 in 0.1 steps. There is no
separate permission checkbox or camera-settings explanation block on this page.

CameraShift changes shoulder offset, the two motion-sickness settings needed for
it, and the selected **Head bob** and **Follow the target** options. Enable their
individual features in Advanced Cinematographer to expose these checkboxes. They
are available for permanent settings, the ordinary Lens and additional Combined
Lenses. All original values, including target focus and head movement, are restored
when the effect ends. Unsupported options are disabled on clients lacking their CVars.
It does not run `ActionCam full`. Camera changes can cause visual discomfort. After explicit consent,
ret_Cinema dismisses `EXPERIMENTAL_CVAR_WARNING` only immediately following its own
camera CVar writes. It leaves unrelated warnings alone. Blizzard's warning has no
acceptance operation beyond dismissing the dialog; its Disable button resets
experimental CVars ([Blizzard dialog source](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_StaticPopup_Game/GameDialogDefs.lua)).
Warning timing and appearance still require an in-game check on Retail and Forever.

Activating a Lens remembers the live camera settings and smoothly applies its
chosen offset. A second press or Esc returns to Permanent CameraShift when enabled,
otherwise to the saved settings. Lens shoulder camera offset defaults to **1**;
Permanent shoulder camera offset defaults to **1.5**. The default transition lasts 0.5 seconds;
Advanced controls allow 0.1–5 seconds, including the animated return on Esc.
Changes to permanent settings while a Lens is active take effect when that Lens
exits. Disabling the Effect, withdrawing consent, or logging out restores the
original camera immediately. Login/reload first recovers an interrupted original
snapshot, then reapplies the saved permanent preference. Zooming and combat do not
cancel Lens Effects.

For both numeric controls, Enter or leaving the field commits an edit, and Esc
cancels it. Option tooltips end with a separate **Default:** line (Checked or Unchecked).
Every default hint appears at the end of its tooltip, after one blank line,
for example **Default: 0.5**. Reset buttons appear only when their value differs
from the default, and disappear immediately after a successful reset.
An undo-arrow button beside every precise numeric input restores its default.
Decimal commas and dots are accepted. Out-of-range values are clamped;
invalid values leave the current setting unchanged. Unsupported clients disable
camera controls and show a message.

### FOV

**Permanent FOV** and **Apply … to Lens** provide independent field-of-view
sliders and editable values. FOV is also available as an individual Lens, through
`/retcin fov`, and in every Combined Lens. The allowed range comes from
`GetCameraFOVDefaults()`, the same API used by Blizzard's graphics settings; clients
without this API use a 60–90 fallback. The `cameraFov` CVar must exist for controls
to be usable. Leaving the Lens returns to permanent FOV or the exact pre-effect
value. Transitions and their return on Esc use a smooth 0.5-second animation
by default. **Custom FOV animation duration** in Advanced exposes the identically named checkbox
on the Effect page and in Combined Lens settings. Checking it enables the custom
duration and reveals its slider/input; clearing it restores the default duration. The duration supports
0.1–5 seconds, independently for Permanent FOV, the ordinary Lens and each
additional Combined Lens. Disabling the Advanced duration option restores the
0.5-second default while preserving custom preferences. Transitions start from
the live FOV so reversing a transition never jumps. There is no
animation callback after it finishes. Disabling FOV, changing profile and logging
out immediately restore the original CVar and stop the animator.

### SmoothMotion

SmoothMotion remains a placeholder with inactive Permanent/Apply controls and
smoothing slider. It has no runtime action and retains gray styling.

### Lens

The table has **Effect**, **Lens button**, and **Add to Combined Lens** columns.
With two or more Combined Lenses, the last column becomes **Add to a specific
Combined Lens**, with numbered checkboxes arranged horizontally for each Effect.
With one visible Lens, checkbox 1 stands alone with its gear to the right.
When an additional Lens exists, checkboxes **1–5** share one centered framed
container. Every checkbox has its own gear to the right, and small vertical
dividers and small gaps separate the checkbox/gear pairs. Empty persisted CL2–5 slots do not
expose a container or membership numbers. **+** temporarily reveals the next slot
so Effects or Escape Button can be assigned. The new empty Combined Lens is
visible below the existing Lens immediately. Leaving Lens discards an empty reveal
unless it was selected as Escape Button. Hiding a
slot keeps its configuration and native bindings. Combined Lens effect summaries are
centered on that same column axis.
Hover a checkbox to see
both the Effect name and the target Combined Lens number. Click a slot, then press a key combination. Right-click clears the slot;
Esc cancels capture. With **Additional keybind button** enabled, an individual Effect offers a second slot below its first,
separated by **or**, once the first key is assigned. Unassigned slots show
**Not bound** in gray. Binding status text is 1.5 times the standard font size.
Bindings cannot be edited during combat; existing shortcuts and Effects still work.

The Combined Lens container remains below the individual Effects. Empty Combined
Lens rows are hidden and built only after an eligible Effect is selected in their
membership column. Clearing the last member hides the row without erasing settings
or native bindings. The add/remove controls remain available. Small **+** and
**-** buttons sit together at its bottom. **+** adds another configuration, up to
three in Simple mode or five with **Combined Lenses up to 5**; **-** hides the last
additional lens, down to one. Both buttons remain
visible and disable at their limits; hiding is blocked in combat. Hiding an active
lens restores its activation snapshot and keeps its settings, selections and game
keybindings. **+** reveals the same slot with those preferences and shortcuts.
A shortcut for a hidden slot performs no Lens action until the slot is shown again.

The first lens is named **Combined Lens** until a second is added, then becomes
**Combined Lens 1**. Each lens offers a second binding slot when that Advanced feature is enabled and its own
**Escape Button** checkbox beneath its two key slots. To the right of the first
slot, a comma-separated list shows the enabled Effects selected for that lens.
Dividers separate the configurations inside the same
container. Fresh slots start with no Effects selected; re-shown slots retain theirs.

Every membership checkbox has a gear button, including Combined Lens 1.
It opens that specific Lens's Effect settings window with a
centered selector listing only the checked lenses for that Effect, including CL1,
with a current/total page counter and previous/next arrows. The arrows wrap over
only the selected lenses. Letterbox, CameraShift and FOV have independent
values and enabled advanced controls. HideUI has its exposed Advanced switches.
There is no Apply checkbox or Use Effect settings switch in these dialogs;
membership is managed by the table. Changes apply
on the next activation. Editing Combined Lens 1 edits the main Effect settings
that this Lens already uses; CL2–5 keep independent values.
A gear is disabled when its own checkbox is unchecked or that Effect has no
exposed settings. Clicking the same gear again, or pressing Esc, closes the window.
Clicking another gear switches directly to that Lens.

Custom numeric settings are saved with the profile and do not change other
lenses or permanent settings. Activating a custom Effect replaces its current
Lens value if already active; exiting restores the prior Lens value and active
state. Esc and Escape Button restore permanent/original settings as usual.

Hover an Effect name for its chat command; hover a Combined Lens name for its
numbered command. Chat commands and shortcuts call the same toggle functions;
they do not execute a stored macro.

Only one Combined Lens can be **Escape Button**. Once selected, the other
Escape Button checkboxes disappear; clear the selected one to choose another.
Existing profiles with multiple flags retain the first flagged Lens in numerical
order. An empty Combined Lens can be the Escape Button: its key immediately exits
all temporary Lens Effects, while keeping permanent settings. Empty Lenses without
this flag disappear when leaving Lens; their stored native bindings are retained.

For a nonempty Combined Lens, **Escape Button** controls its second press:

- Checked: the first press applies its Effects. On a later press, if only that
  Lens's Effects and values remain, it exits all temporary Effects immediately
  with their return animations. If other Effects or values remain, that press
  replaces them with this Lens; the next press exits. The decision uses the
  current scene, even if another Lens button was pressed in between.
- Unchecked: restores only the states captured for its selected Effects at entry.
  Unselected Lens Effects keep their current state.

While an RP action owns an Effect, that Effect ignores individual and Combined
Lens buttons. Unrelated Effects can still toggle. Escape Button temporarily uses
ordinary restoration for those unrelated Effects, preserving its saved preference.
The physical **Esc** key exits all active Lens Effects and RP scenes and consumes
that press, so the game menu does not open. Permanent Effects remain the baseline.
After Esc dismisses Walk, movement alone does not reapply it: switch Run/Walk again
or explicitly resynchronize the mode to begin another RP action. Esc during
GoOffline also cancels the native logout countdown. With no temporary scene active,
Esc has its normal game behavior. An open addon dialog consumes Esc first and
leaves the active Lens intact.

Each Combined Lens remembers its activation snapshot, including shared Effects.
Esc and a checked Escape Button clear the applicable Combined snapshots.
Disabling or unapplying an Effect removes it from every active snapshot.
The first Combined Lens retains its old binding ID; lenses 2–5 have separate IDs.
Bindings remain in the game's current account/character binding set.

### Animation timing

All three Effect duration defaults are **0.5 seconds**. Saved custom values remain
unchanged. CameraShift and FOV use the same smoothstep curve and reach their CVar
targets at the configured time; the local behavior test verifies both at 0.25 and
0.5 seconds. These CVar values do not measure the camera's rendered position.
Client-side smoothing or another camera addon may still affect visible motion;
this cannot be confirmed without an in-game observation.

Letterbox scales duration by `abs(target - current) / span`, where span includes
the configured main Lens height and current/permanent heights. A short movement
between heights can therefore finish before a CameraShift animation configured
with the same duration. This timing rule and CameraShift's animation mechanics
are unchanged in 1.1.13; only the requested defaults changed.

## Chat commands

Each command toggles its Lens Effect; the Effect must be enabled on the main ret_Cinema page and
have **Apply … to Lens** checked. CameraShift also requires consent.

- `/retcin hideui`
- `/retcin showletterbox`
- `/retcin camerashift`
- `/retcin fov`
- `/retcin combinedlens` or `/retcin combinedlens1` (first Combined Lens)
- `/retcin combinedlens2` through `/retcin combinedlens5` (only after adding them)
- `/retcin` (settings)

`/retcinema` accepts the same commands. `/retcin combinedlens` and
`/retcin combinedlens1` address the same first lens. The old `/retcin combined`
alias and unused macro-text generation helper remain removed.

## LiteRP

LiteRP names and navigation use the native emote chat color, including hover and
selection states in the game navigation list. The existing description is followed
by its hint and exactly one blank text line before the content. A bordered container
splits the page vertically:
**Move / Walk** on the left and **Stay / Sit / Lay / Lean / GoOffline** on the right.
Move and Stay are headings, with no checkboxes or runtime gates. Older gate
preferences are validated for version-9 imports and discarded.
Only actions exposed in Advanced appear here; separator lines divide visible actions.

**Move → Walk** keeps its selected Lens active while walk mode is enabled, including
when the character stops moving. Native Run/Walk changes update the known mode;
the existing game binding is never replaced. On initial synchronization, movement
speed is sampled after native actions in short bounded checks. While stationary,
an unknown initial mode is not guessed: move once to synchronize, or use **Walking
mode is currently enabled** to match the current mode explicitly. This helper is
smaller and gray, with a system chat-colored Warning prefix in its tooltip. This checkbox
synchronizes the addon and does not change game movement. Once the mode is known,
no speed polling or movement ticker is needed, and speed buffs do not change it.

**Stay** provides separate **Sit**, **Lay** and **Lean** checkboxes, each revealing
its own Lens selector beneath the checkbox, matching Walk. Native sit actions and `/sit`, `/lay`, `/sleep`, `/lean`
emotes are recognized while stationary on the ground. Moving or `/stand` ends the
pose. Switching poses replaces the previous pose's Lens. If walk mode is still
active, ending a pose returns to the walking Lens; otherwise it returns to the
scene captured before LiteRP. Special native animation restrictions still need
client testing because this is action-based detection, not a direct posture query.

**GoOffline** has an enable checkbox, a label and a settings gear. When unchecked,
its label is gray and its gear is hidden. When checked, the label is white, the
gear is visible and a Lens/Combined Lens selector appears beneath it. **No Lens**
is the migration/default choice. The gear opens a separate settings window with editable
starting/minimum and maximum bar heights, plus the duration and growth rate of
three stages. The window is created on first use; clicking again or pressing Esc
closes it. Selecting a Lens applies it during the countdown. GoOffline's own
Letterbox stages override the selected Lens's Letterbox animation and prevent
its keybindings from changing the action. Canceling logout restores the previous
scene or resumes the underlying Walk/Stay action. While GoOffline hides UI, it
uses alpha instead of hiding UIParent, preserving native logout-popup behavior
and restoring the exact original alpha afterward. The native CAMP/QUIT popup
ignores parent alpha during GoOffline, so its countdown and native cancellation
controls stay visible even with HideUI. This also works if HideUI was active before
logout. The popup's original alpha behavior is restored on cancellation or shutdown.
Every field has a default tooltip; its undo button appears only for non-default values. Defaults add 2 percentage points per second for 10 seconds, then
3 for 6 seconds, then 4 for 3 seconds, capped at 50% per bar. Existing bars can
provide a higher starting value. The native countdown is always 20 seconds; a
longer configured plan is cut short, and a shorter plan holds its final height.
Canceling the native logout/quit countdown stops GoOffline growth immediately
and restores the previous bars in **0.15 seconds**, regardless of a longer saved
Letterbox duration. The native `CancelLogout` call is observed with a secure
post-hook, alongside `LOGOUT_CANCEL`. Only an explicit physical Esc exit from an
active GoOffline scene calls `CancelLogout`; ordinary Lens keys do not cancel the
native countdown. Opening
the game menu alone does not start the preset, and immediate logout has no countdown.

LiteRP is the child category; Walk, Stay and GoOffline are its actions.
While any action owns the scene, Combined Lenses temporarily use ordinary toggle
behavior for unrelated Effects, preserving their saved Escape Button preferences.
RP-owned Effects remain protected until their action ends. Hidden, disabled or empty targets do not activate
effects. LiteRP unregisters events and removes its countdown callback when unused.
Its runtime is initialized on first enabling the Advanced feature, and each native
hook is installed only when its corresponding integration is needed. Preferences
are saved with the profile.
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

Exports use `RETCINEMA_PROFILE:11|...`, including Advanced options, individual Stay
targets, GoOffline stages, optional-action visibility, custom-duration enable
states, FOV, camera options and independent Combined Lens values. Old profiles
keep configured RP actions visible and retain previously customized durations.
Versions 1–9 remain supported; version 1 imports with one
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

A narrower **Too-Doo** button sits directly below Version. It opens a local feature browser with statuses such
as Available, Experimental, Planned and Under consideration. Planned items include
**Improve descriptions and tooltips** and **Add a 'Like ret_' profile**. This is a
roadmap entry; the profile is not created automatically. Click a feature to read
its description. A blank gap separates Too-Doo from Support Development.
It is built only on first use, sends no votes or messages, and runs no background work.

## Performance and recovery

Disabled Effects have no animation callbacks or periodic work. Settings pages
and their optional permanent controls are built only when opened or needed.
Bars and the camera animator are allocated on first use. An OnUpdate callback
runs only during a transition, enabled logout countdown or minimap drag, and is removed on completion.
Permanent Effects have no continuous Lua updates while stationary. Hidden
Letterbox bars unregister their screen/scale events and size handler; their layout
is refreshed when shown again. Unrelated popups return immediately from the camera
warning hook.
The FOV animator is also lazy and removes its callback after each transition.
LiteRP runtime functions, hooks and event frames are initialized only on first
enabling its Advanced feature; disabled integrations do not install unused hooks.

The Escape listener is shown only while temporary Lens Effects or a Combined
snapshot is active. Lens listens for binding updates only while its page is open;
hidden pages do not build newly added Combined controls until opened.
A small visibility hook keeps HideUI active if the game shows the interface.
Camera-warning handling is installed only after a consented camera write and
checks only the named warning and proximity to ret_Cinema's own writes.

Original names, camera and FOV CVars are recovered on ordinary logout or reload.
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
`ns.ChatColor`, `ns.ChatText` and `ns.FormatText` use native chat colors for
Experimental markers, warnings and LiteRP. Use the same feature names in Advanced,
Effect and per-Combined Lens settings.

## Credits

Inspired by the screenshot and letterbox features of Cinematic by Andrew Casals.
[Original Cinematic](https://github.com/andrewcasals/Cinematic).
Shoulder-offset behavior is inspired by
[DynamicCam](https://github.com/Mpstark/DynamicCam) by mpstark and LudiusMaximus.
ret_Cinema implements its own minimal controls without zoom curves or a dependency.
