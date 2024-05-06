# N7 Zeds Changelog

## `1.2.x` Features

### `1.2.0`

- Although custom skins are turned on by default, it is now possible to switch them off and get back to original textures by setting `bUseOriginalZedSkins` to `True` in configuration file.

### `1.2.x` Fixes

#### `1.2.1`

- Fixed issue with vanilla textured stalkers blinking and not going invisible.

## `1.3.x` Features

### `1.3.0`

- Mutate API has been extended with mutator-specific console commands to allow in-game ZEDs configuration.

## `1.4.x` Features

### `1.4.0`

- **Major rework of the Patriarch**:
  + **Addition of new patriarch's behaviours**:
    * Patriarch might want to destroy pipe bombs when there are players nearby.
    * Patriarch might want to destroy welded doors when there are players nearby.
    * Patriarch might want to radial attack players circling around him during chaingun attack (He won't though until he gets damaged).
    * Patriarch might want to evade significant damage by switching places with one of the alive pseudos.
    * Patriarch might want to go on invisible hunt right after healing. 
  + **Updates to existing behaviours**:
    * Radial attack animation has been trimmed so patriarch won't waste time boasting.
    * Patriarch's chaingun attack has been reconsidered. Depending on distance and configuration settings he can do three types of chaingun attack:
       1. Stationary burst fire - More accurate, yet less mobile. More likely to be chosen when the patriarch is attacking from larger distance.
       2. Walking auto fire - Less accurate, but allows for chasing players at mid-range distances.
       3. Running auto fire - Inaccurate, but efficient when it comes to killing players in close quarters combat. Activates only after patriarch gets damaged severely during 2nd type attack.
    * Patriarch shoots a little less rounds per chaingun attack.
    * Patriarch is no longer invincible when escaping/healing - though the exact percentage of ignored incoming damage is configured.
    * Patriarch is no longer invincible when using shield - the exact percentage of absorbed incoming damage is configured.
    * Patriarch is no longer vulnerable to commando attacks when invisible. Commando does the same damage as other perks.
    * Cooldown for rocket launcher attack has been increased.
    * Patriarch's pseudos are now spawned at random locations rather than around the patriarch.
    * Patriarch's teleportation point is now by default further from the enemy player than it used to be + it is now configurable.
    * Conditions for force charge have been slightly changed to consider cooldown.
- **Other ZEDs' behaviour changes**:
  + **Husks**:
    * Can do either moving or stationary attack depending on distance to the target player (Stationary is preferred when close enough to players and there is no need in shortening the distance).
  + **Fleshpounds**
    * Can settle down after killing a player or after certain timeout (given he is far enough from the player he is charging at).
  + **Sirens**
    * Scream causes less screen shaking.
- **Major configuration changes**:
  + Each ZED can be set a custom display name.
  + **Patriarch**:
    * All of the boolean configuration settings for patriarch (`bCanKite`, `bSpawnPseudos`, `bUseShield`, `bUseTeleport` etc.) have been removed due to redundancy. Those are replaced with chance settings.
    * Large number of settings have been added to patriarch's combat stages configuration allowing huge variety of behaviour adjustments. More in [`CONFIG.md`](./CONFIG.md).
    * Added setting for patriarch's HP configuration.
    * Added setting for patriarch's chaingun damage configuration.
  + **Stalkers**:
    * Added min/max spawned pseudos configuration settings.
  + **Husks**:
    * Added firing interval settings.
    * Added moving attack chance setting.
  + **Sirens**:
    * Added custom damage type enable/disable setting. (Allows for turning off the agony effect).
  + **Fleshpound**
    * Added chance setting of settling down after killing a player.
    * Added setting of distance at which fleshpound stops charging at player (works only if fleshpound has been raged by damage).
- **Major changes to custom skins pack**: Clot, Bloat, Gorefast, Crawler, Siren, Scrake, Fleshpound.

### `1.4.x` Fixes

#### `1.4.0`

- Fixed patriarch replacement in the sandbox.
- Fixed patriarch not charging at nearby players when shot during stationary chaingun attack.
- Fixed patriach's pseudos overriding each other when spawning was to occur multiple times at different healing stages.
- Fixed siren's attack not pulling players.
- Fixed siren's attack damaging players after decapitation.
- Fixed husk trying to shoot when falling.
- Fixed husk's moving attack not being interrupted by stunning.
- Fixed fleshpound's device light not changing fully to red when he gets raged by explosions.
- Fixed fleshpound's spinning when raging and other ZEDs are around.
- Fixed fleshpound's unraging before door bashing.

#### `1.4.1`

- Custom skins pack upgraded to v1.1.0
