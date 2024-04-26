# N7Zeds mutator for Killing Floor

Inspired by **SuperZombieMut** and **KFHardPat** mutators whose purpose was to enhance ZEDs behaviour making the game more challenging
this mutator goes further and adds a bunch of features to original ZEDS and fixes some well-known issues/exploits.

## Table of Contents

- [N7Zeds mutator for Killing Floor](#n7zeds-mutator-for-killing-floor)
  - [Table of Contents](#table-of-contents)
  - [Features](#features)
    - [General](#general)
    - [Gorefast](#gorefast)
    - [Crawler](#crawler)
    - [Stalker](#stalker)
    - [Husk](#husk)
    - [Siren](#siren)
    - [Scrake](#scrake)
    - [Fleshpound](#fleshpound)
    - [Patriarch](#patriarch)
  - [Fixes](#fixes)
  - [Changelog](#changelog)
  - [Credits](#credits)
  - [Contacts](#contacts)

## Features

### General

- New ZEDs behaviour features.
- Modified existing ZEDs behaviours.
- Alternative ZEDs skins (based on Grittier Zeds replacement pack).
- Individual ZED's replacement configuration rules.
<br><br>
- [`1.2.0`] New configuration setting is added to toggle alternative skins on/off.
- [`1.3.0`] Mutate API is added to allow in-game ZEDs configuration. ([`MUTATE.md`](./MUTATE.md))
- [`1.4.0`] Major Patriarch rework and minor additions/fixes in other ZEDs' behaviour. New ZEDs configuration settings.

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

- Husks can do moving attack.
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

- Patriarch's impale attack range has been increased.
- Patriarch's radial attack animation has been trimmed so he won't waste time boasting.
- Patriarch's got one new melee animation (actually old one, but unused). All melee animation rates increased to 1.25.
- Patriarch now has 3 types of chaingun attack: stationary (vanilla) - most accurate; walking - less accurate, but somewhat mobile; running - least accurate, allows for best patriarch mobility when chasing players.
- Patriarch shoots several rockets during one attack. Patriarch's rockets can hit targets mid-air.
- Patriarch is invisible when escaping and healing.
- Patriarch can ignore some incoming damage when escaping or healing.
- Patriarch can spawn a squad of pseudos after heal. Pseudo patriarchs behave similarly to pseudo stalkers.
- Patriarch can teleport to a target if it's far enough.
- Patriarch can activate shield for a couple of seconds.
- Patriarch can destroy pipe bombs when there are players nearby.
- Patriarch can destroy welded doors when there are players nearby.
- Patriarch can radial attack players circling around him during chaingun attack (He won't though until he gets damaged).
- Patriarch can evade significant damage by switching places with one of the alive pseudos.

## Fixes

- Fixed Stalkers kiting.
- Fixed Gorefasts kiting.
- Fixed Patriarch kiting (configurable).
- Fixed Siren's attack damaging players after decapitation.
- Fixed Husk trying to shoot when falling.
- Fixed fleshpound's spinning when raging and other ZEDs are around.

## Changelog

All the changes and updates starting from version `1.2.0` can be found in the separate [`CHANGELOG.md`](./CHANGELOG.md) file.

## Credits

- [Shtoyan](https://github.com/Shtoyan) - For making the world a better place with his [KFHardPat mutator](https://github.com/InsultingPros/KFHardPatF).
- [Scaryghost](https://github.com/scaryghost) - For [SuperZombieMut](https://github.com/scaryghost/SuperZombieMut) which inspired creation of this very mutator.
- [Half-Dead](https://forums.tripwireinteractive.com/index.php?threads/replacement-grittier-classic-style-zeds.80060/) - For Grittier Zeds skin pack.

## Contacts

For questions/concerns/recommendations you can contact me via steam or email:

**Steam Profile:** [N7n](https://steamcommunity.com/id/NSHoffman/)

**Email:** [hoffmanmyst@gmail.com](mailto:hoffmanmyst@gmail.com)
