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

Open ret_Cinema from the Addon Compartment menu beside the minimap, the minimap
icon, or `/retcin` (also `/retcinema`). It also appears in the game's addon settings.

- **General:** Show minimap icon. The Addon Compartment entry remains available
  when this icon is hidden. Drag the icon to move it around the minimap.
  **Enable modules** controls Hide UI, Letterbox, Camera Shift, and the Smooth Motion preview, arranged
  horizontally with up to four entries per row. Disabled modules stop immediately
  and their tabs are hidden. Hover a checkbox for its tab description.
  **Keybindings** appears automatically whenever any action module is enabled;
  its checkbox is checked and locked. It disappears when all action modules are
  disabled. All action modules start enabled; Camera Shift starts inactive until
  its key or chat command is used. Credits contain underlined
  links to ret_, Cinematic, and DynamicCam; click a link to copy its address.
  **Ask for it!** above the credits copies the GitHub address for a bug report or
  feature request.
- **Hide UI:** Screenshot mode hides the UI and temporarily switches off world
  names for players, NPCs, pets, and focused units on clients that expose those
  settings. Original values return on Escape, the action's second press, module
  disable, or logout. An unsolicited UI show does not cancel the mode.
  Saved recovery values also protect
  against leaving names disabled after a UI reload or interrupted session.
- **Letterbox:** Bar height, from 0% to 25% of the screen height **per bar**.
  Use the slider or type a percentage in its value field (0.1% steps).
  Enter or leaving the field applies the value; Escape cancels the edit.
  Both bars have the same height. Changes apply immediately to visible bars.
  **Enable animation** smoothly slides the bars in and out (enabled by default).
  **Always On** is a disabled placeholder marked **Under consideration**; it has
  no effect and does not save a setting.
- **Camera Shift:** Set a shoulder offset from -15 to 15 in 0.1 steps with the
  slider or the editable value to its right. Press Enter or leave the field to
  apply a typed value; Escape cancels the edit. Values outside the range are
  clamped, and invalid input keeps the previous value. Decimal dots and commas
  are accepted. The slider configures the next activation; changing it while
  Camera Shift is active smoothly updates the view. On the first key press,
  the addon remembers the live camera offset (including a nonzero value set by
  another addon) and applies the slider value. Press again to restore the saved
  offset and camera-centering preferences. Both directions use a short smooth
  transition (0.35 seconds). Reversing a transition starts at its current position.
  Disabling the module also restores
  them. Camera Shift starts inactive after login or reload. Unsupported clients
  show a message and disable the slider.
  **Always On** is also a disabled placeholder marked **Under consideration**.
- **Smooth Motion:** This tab is under development. Its checkbox and smoothing
  slider are disabled placeholders. Opening the tab builds only its settings
  preview; it has no runtime effects or keybindings.
- **Keybindings:** Hide UI, Show Letterbox, and Camera Shift. All are toggles. Click a key
  slot, then press a key combination. Right-click a slot to clear it; Escape
  cancels capture. Bindings can also be set under Key Bindings > AddOns >
  ret_Cinema. Assigning a used key replaces its previous action.
  Check actions in the **Combined** column to include them in **Combined key**.
  This binding appears in its own container below all individual actions when at
  least one is checked. Hover **Combined Key** for its explanation.
  Its key toggles all checked actions; the individual bindings still work.
  The static preview below it lists the selected chat commands on separate lines.
  **Copy macro text** opens a selected, read-only copy field. Ctrl+C copies its
  text and closes the window after the key is released.
  Unchecking every action hides the
  combined controls and makes the combined binding inactive, while retaining its
  assigned keys for later use. Disabled action modules are excluded from the
  preview and execution without discarding their selections. Keybindings is
  enabled automatically while any action module is enabled. Saved keys are
  retained when all action modules are disabled.
  Each action has a **Key** column. Once its first key is assigned, a second
  slot appears directly below it, separated by **or**. Both keys trigger the same
  action. Combined Key has its own **Module / Key / Exit all** headers; individual
  actions use **Module / Key / Combined**, with a divider between actions.
  The **Exit all**
  checkbox on the Combined Key row makes its second press exit every active
  module, including modules not checked in Combined, with their exit animations.
  This preference is saved across sessions. Binding status text is 1.5 times
  the standard font size.

## Exiting cinematic mode

Press **Escape** to end all active ret_Cinema effects: restore the original UI
visibility and name settings, remove the bars, restore the previous camera
offset and centering settings. This works for
Combined Key and individual actions, including when the UI remains visible.
Camera returns smoothly, and bars slide out when their animation is enabled.
An unfinished entry animation reverses from its current position. Repeated
Escape presses do not restart a return animation.

Modes remain active while zooming and while entering or leaving combat.
The Escape listener responds to the actual key, rather than treating native
special-window closures as an exit. Ordinary window closures or automatic UI
shows do not end a mode. Keybinding assignments cannot be changed in combat;
this restriction does not disable the active effects or existing shortcuts.

Combined Key remembers which actions were selected and their on/off states at
the first press. With **Exit all** unchecked, pressing it again restores those states, even if the selected
checkboxes changed in between. Escape clears this snapshot so the next Combined
Key press starts a fresh mode. Disabling all action modules also clears it.

To keep your old shortcuts, assign **Ctrl+Alt+F** to **Hide UI** and
**Ctrl+Alt+G** to **Show Letterbox**. Existing bindings are not changed during
installation. Keybindings use the game's current account/character binding set.

Hide UI combines the game's screenshot visibility function with temporary
world-name overrides, rather than relying on the visibility function alone.
Letterbox bars remain visible while the UI is hidden, and their binding still
works. Use Escape or the addon shortcut to restore screenshot mode; the normal
Alt+Z UI toggle does not terminate the addon modes.

Module choices, camera offset, bar height, animation, combined selections, and minimap preferences are saved
across sessions. Letterbox starts off on login or UI reload.
Screenshot mode restores original name settings.

Chat commands (each action toggles on/off):

- `/retcin hideui`
- `/retcin showletterbox`
- `/retcin camerashift`
- `/retcin combined` (all checked actions)
- `/retcin` (open settings)

The `/retcinema` alias accepts the same commands.

## Performance

There are no periodic timers, world scans, or permanent OnUpdate callbacks.
Screen layout updates on display/scale events; keyboard settings listen for
binding changes only while their tab is visible. An OnUpdate callback runs only
while dragging the minimap icon or animating the bars/camera, and is removed as
soon as the drag or animation ends. The Escape handler is armed only while
ret_Cinema has active effects or a pending combined restoration.
Bars are allocated on first use, and settings pages are built only when opened.
Disabled modules have no periodic work or animation callbacks. A lightweight
visibility hook remains after using Hide UI to keep screenshot mode active if
the game shows the UI automatically. Disabling modules does not unload Lua code or delete frames that
already exist. A reload avoids allocating unused pages and bars for the saved
disabled configuration. Since the addon already does very little while idle,
disabling modules is not expected to produce a large idle CPU or memory saving.
The addon does not load DynamicCam's code or libraries.

## Editing the description and font size

Edit `## Notes:` in `ret_Cinema.toc` to change General's addon description and
the description shown in the addon list. General reads the TOC metadata directly;
there is no separate copy of this text in Lua. Reload the UI after changing it.

In `Options.lua`, `DESCRIPTION_FONT_SCALE = 1.5` controls all tab descriptions,
relative to the standard WoW text size. Credits and binding status messages have
their own font sizes. Each entry in the `ns.modules` table in `Core.lua` has:

- `description`: the larger yellow heading in the module tab and its checkbox tooltip.
- `hint`: an optional standard-size yellow explanation below that heading.
- `name`: the module name shown on its tab and in General.

For example, find `id = "keybindings"` and edit `description = "Assign keys to Modules."`
or `hint = "Modules can be combined into one key"`. Keep the text inside its
quotation marks and reload the UI to see changes. All tab descriptions and hints
share the `ModuleDescription` layout in `Options.lua`; individual controls and
other labels are in that file's `builders` functions. Addon UI text is English-only.
Increment `## Version:` in the TOC for each batch of addon changes.

## Credits

Inspired by the screenshot and letterbox features of Cinematic by Andrew Casals.
[Original Cinematic](https://github.com/andrewcasals/Cinematic).
Shoulder-offset behavior is inspired by
[DynamicCam](https://github.com/Mpstark/DynamicCam) by mpstark and LudiusMaximus.
ret_Cinema implements its own minimal controls without zoom curves or a dependency.
