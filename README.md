# N7Zeds mutator for Killing Floor

Inspired by **SuperZombieMut** and **HardPat** mutators whose purpose was to enhance ZEDs behaviour making the game more challenging
this mutator goes further and adds a bunch of features to original ZEDS and fixes some well-known issues/exploits.

## Table of Contents

- [1. Features](#features)
  - [1.1. General](#general)
  - [1.2. Gorefast](#gorefast)
  - [1.3. Crawler](#crawler)
  - [1.4. Stalker](#stalker)
  - [1.5. Husk](#husk)
  - [1.6. Siren](#siren)
  - [1.7. Scrake](#scrake)
  - [1.8. Fleshpound](#fleshpound)
  - [1.9. Patriarch](#patriarch)
- [2. Fixes](#fixes)
- [3. Changelog](#changelog)
- [4. Contacts](#contacts)

## Features

### General

- Speed of some ZEDs increased.
- Each ZED's replacement rules can be configured individually.
- All ZEDs skins retextured (based on Grittier Zeds replacement pack).
- [`1.2.0`] Alternative skins can be switched off in favour of vanilla textures.
- [`1.3.0`] Mutate API extended to allow in-game ZEDs configuration. ([`MUTATE.md`](./MUTATE.md))

> More information on configuration in [`CONFIG.md`](./CONFIG.md)

### Gorefast

- Gorefasts start charging from a larger distance.
- Gorefasts attack constantly, without pause.

### Crawler

- Crawlers are more aggressive as their attacking behaviour got more agile and chaotic.

### Stalker

- Stalkers attack constantly, without pause.
- Having spawned, Stalkers might spawn a couple of fake projections that act like regular stalkers but die from any insignificant damage or when the host stalker gets killed.
- Pseudo Stalkers are always invisible. When attacking/dying they expose their pseudo nature by switching appearance to holographic effect (the same effect used to reveal stalkers when Commando perk is selected).

### Husk

- Husks attack when moving.
- Husks' projectiles can hit mid-air targets.
- Husks' firerate is less predictable, but more frequent overall.

### Siren

- Siren's scream cannot be interrupted.
- Sirens cause agony screen effect when screaming.

### Scrake

- Scrakes are constantly raged.

### Fleshpound

- Fleshpounds' device has dynamic lighting.
- Once a fleshpound gets raged it won't settle down until dead.

### Patriarch

- Patriarch now has moving chaingun attack, chaingunning with no stops.
- Patriarch shoots several rockets during one attack.
- Patriarch's rockets can hit targets mid-air.
- Patriarch gets invisible and non-blocking when escaping/healing. Only commandos can see and damage him in this state.
- Patriarch got one new melee animation (actually old, but unused). All melee animation rates increased to 1.25.
- Patriarch spawns a squad of pseudos after 3rd heal. Pseudo patriarchs behave similarly to pseudo stalkers.
- Patriarch's impale attack range is increased.
- Patriarch, with a small chance, can teleport to a target if it's far enough.
- Patriarch, with a small chance, can use shield for a couple of seconds.

## Fixes

- Stalkers cannot be kited.
- Gorefasts cannot be kited.
- Patriarch cannot be kited after 1st heal.
- Patriarch will not proceed with charging once his health level gets low.

## Changelog

All the changes and updates starting from version `1.2.0` can be found in the separate [`CHANGELOG.md`](./CHANGELOG.md) file.

## Contacts

For questions/concerns/recommendations you can contact me via steam or email:

**Steam Profile:** [N7n](https://steamcommunity.com/id/NSHoffman/)

**Email:** [hoffmanmyst@gmail.com](mailto:hoffmanmyst@gmail.com)
