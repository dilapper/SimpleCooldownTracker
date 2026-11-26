# SimpleCooldownTracker

Progress bars for your own crowd controls and their diminishing returns, for **WoW Forever**.

> **This is a port, not an original work.** All design and code are by **Simon Hirsig** ([shirsig](https://github.com/shirsig/ccc), `simon.hirsig@gmail.com`), who wrote the Classic Era addon **ccc**. This repository only converts it to run on the Forever client (new addon name, TOC, and API compatibility shims). Please credit the original author. See `UPSTREAM_CHANGES.txt` for the upstream version this was based on (ccc v1.2.12).

## What it does

- Only your own CCs are shown, even when the affected unit is not your target.
- Reapplication is detected even when the unit is not your target.
- Diminishing returns, special PvP durations, spell ranks, talents and combo points are taken into account.
- Green bars are active debuffs; yellow/orange/red bars are diminishing returns at 1/2, 1/4 and immune.

## Install

Copy the `SimpleCooldownTracker` folder into your Forever `Interface/AddOns` directory.

## Commands

`/sct` (or `/ccc`) with: `lock`, `unlock`, `invert`, `growth up|down`, `scale 0.5-3`, `alpha 0-1`, `aoe target|all`, `ignore <name>`, `ignore`.

Unlock the bars to drag them into position, then lock them again.

## Changes from ccc

- Renamed to SimpleCooldownTracker (saved variables are `SimpleCooldownTracker_settings`; existing ccc settings are not migrated).
- Forever TOC (`16001`) and a `Compat.lua` shim for relocated APIs.
