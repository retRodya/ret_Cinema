# ret_Cinema

A standalone, English-only addon for WoW Forever and WoW Retail. The same files
are used for both clients. No dependency on Cinematic or any external library.

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
- **Letterbox:** Bar height, from 0% to 25% of the screen height **per bar**.
  Both bars have the same height. Changes apply immediately to visible bars.
- **Keybindings:** Hide UI and Show letterbox. Both are toggles. Click a key
  slot, then press a key combination. Right-click a slot to clear it; Escape
  cancels capture. Bindings can also be set under Key Bindings > AddOns >
  ret_Cinema. Assigning a used key replaces its previous action.

To keep your old shortcuts, assign **Ctrl+Alt+F** to **Hide UI** and
**Ctrl+Alt+G** to **Show letterbox**. Existing bindings are not changed during
installation. Keybindings use the game's current account/character binding set.

Hide UI uses the same game function as Cinematic's screenshot mode: the UI,
world names, and nameplates are hidden together and restored on the next press.
Letterbox bars remain visible while the UI is hidden, and their binding still
works. The screenshot binding also stays in sync with the game's Alt+Z toggle.

Bar height and minimap preferences are saved across sessions. Letterbox starts
off on login or UI reload. Screenshot mode never changes saved name or
nameplate settings.

## Performance

There are no periodic timers, world scans, or permanent OnUpdate callbacks.
Screen layout updates on display/scale events; keyboard settings listen for
binding changes only while their tab is visible. An OnUpdate callback runs only
while dragging the minimap icon and is removed when dragging stops.

## Credits

Inspired by the screenshot and letterbox features of Cinematic by Andrew Casals.
This addon implements only those two features and its own small settings panel.
