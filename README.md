# SimpleCooldownTracker

> ## ⚠️ Deprecated / retired — does not work on WoW Forever
>
> This addon is **archived and non-functional in combat**. It is kept only in case the client's addon restrictions change.
>
> **Why:** the Forever client treats combat information as "secret" for addons. In combat:
> - aura lists cannot be read (`GetUnitAuraInstanceIDs`, `GetUnitAuras` and `GetAuraDataByIndex` all error with *"Auras cannot be accessed when secret"*),
> - the `UNIT_AURA` event payload is secret,
> - spell IDs from cast events are secret values,
> - `COMBAT_LOG_EVENT_UNFILTERED` cannot be registered by addons,
> - `C_Secrets.ShouldAurasBeSecret()` returns `true`.
>
> That leaves no way for an addon to learn which crowd control is on a unit during combat, which is the whole purpose of this addon. Out of combat the aura APIs work, but that is too late to be useful.
>
> **If you want this on Classic Era**, use the original: [shirsig/ccc](https://github.com/shirsig/ccc).
>
> If the restrictions are ever relaxed, the code here (aura-event based, v2.0.0) is a reasonable starting point. `/sct debug`, `/sct trace` and `/sct probe` were added to diagnose exactly this.

Progress bars for your own crowd controls (polymorph, traps, stuns, fears...) on your target, focus and nameplates, for **WoW Forever**.

> **Credit:** this addon is inspired by **ccc** by **Simon Hirsig** ([shirsig/ccc](https://github.com/shirsig/ccc)), a Classic Era addon. The bar layout, colours and slash commands are adapted from it. v1.0 was a straight port; the Forever client hides spell IDs and the combat log from addons, so v2.0 is a rewrite on top of aura events. All credit for the original idea and design goes to Simon. See `UPSTREAM_CHANGES.txt` for the ccc version this started from (v1.2.12).

## How it works

It reads your crowd-control debuffs through the aura API (using the client's `CROWD_CONTROL` filter and duration objects), so it works within the "secret value" restrictions. A bar appears for each CC you applied, with the unit name, icon and remaining time.

### Not in v2 (compared to ccc)

- **Diminishing returns bars.** They need spell IDs and the combat log, which the client no longer exposes.
- Custom PvP duration / talent calculations (the client reports the real duration directly, so these aren't needed).

## Install

Copy the `SimpleCooldownTracker` folder into your Forever `Interface/AddOns` directory.

## Commands

`/sct` (or `/ccc`):

| Command | Effect |
| --- | --- |
| `unlock` / `lock` | Show draggable placeholder bars / lock them |
| `invert` | Fill instead of drain |
| `growth up\|down` | Direction new bars stack |
| `scale 0.5-3` | Bar scale |
| `alpha 0-1` | Bar opacity |
| `plates` | Toggle tracking of nameplate units |
| `all` | Show all of your debuffs, not only CCs |
| `debug` | Print what the addon sees on your target (for bug reports) |
