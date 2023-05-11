# `N7ZedsMut.ini` configuration

## Description

Configuration file allows for setting replacement rules for individual ZEDs as well as reverting back to default skins.

Moreover, some ZEDs have configurable properties that can be changed in the `.ini` file.
Here are some hints on what those are supposed to do.

Apart from it, there can also be [Mutate API related settings](./MUTATE.md).

## Config Example

```ini
; Replacement rules
[N7ZedsMut.N7ZedsMut]
bEnableAutoReplacement=True
bUseOriginalZedSkins=False
bReplaceClot=True
bReplaceCrawler=True
bReplaceGorefast=True
bReplaceStalker=True
bReplaceScrake=True
bReplaceFleshpound=True
bReplaceBloat=True
bReplaceSiren=True
bReplaceHusk=True
bReplaceBoss=True

; Stalker
[N7ZedsMut.N7_Stalker]
; Whether or not Stalkers will spawn pseudo squads
bSpawnPseudos=True

; Those are generated automatically
; Irrelevant for the mutator
[XGame.xPawn]
[UnrealGame.UnrealPawn]
[Engine.Pawn]

; Patriarch
[N7ZedsMut.N7_Boss]
; Each of the CombatStages corresponds to the number of healing syringes used by Patriarch.
; bCanKite - Allow Patriarch to be kited using move to/move from exploit, KiteChance - Chance that kite won't fail (Works if only bCanKite=True)
; bSpawnPseudos - Allow Patriarch to spawn pseudos after healing, MinPseudos/MaxPseudos - Limits for possible spawned pseudos
; bUseShield - Allow Patriarch to turn on shield upon being damaged, ShieldChance - Chance of enabling shield, ShieldDuration - Duration of a shield in seconds
; bUseTeleport - Allow Patriarch to teleport to a target which is far enough, TeleportChance - Chance of teleporting
; CGShots - Chaingun shots per attack, CGFireRate - Chaingun fire rate, RLShots - Rocket Launcher shots per attack, RLFireRate - Rocket Launcher fire rate
CombatStages[0]=(bCanKite=True,bSpawnPseudos=False,bUseShield=False,bUseTeleport=False,CGShots=75,RLShots=1,MinPseudos=0,MaxPseudos=0,KiteChance=1.000000,CGFireRate=0.050000,RLFireRate=0.500000,ShieldChance=0.000000,ShieldDuration=0.000000,TeleportChance=0.000000)
CombatStages[1]=(bCanKite=False,bSpawnPseudos=False,bUseShield=False,bUseTeleport=False,CGShots=100,RLShots=1,MinPseudos=0,MaxPseudos=0,KiteChance=0.350000,CGFireRate=0.040000,RLFireRate=0.400000,ShieldChance=0.000000,ShieldDuration=0.000000,TeleportChance=0.000000)
CombatStages[2]=(bCanKite=False,bSpawnPseudos=False,bUseShield=True,bUseTeleport=True,CGShots=100,RLShots=2,MinPseudos=0,MaxPseudos=0,KiteChance=0.200000,CGFireRate=0.035000,RLFireRate=0.300000,ShieldChance=0.050000,ShieldDuration=1.000000,TeleportChance=0.100000)
CombatStages[3]=(bCanKite=False,bSpawnPseudos=True,bUseShield=True,bUseTeleport=True,CGShots=125,RLShots=3,MinPseudos=3,MaxPseudos=5,KiteChance=0.100000,CGFireRate=0.030000,RLFireRate=0.200000,ShieldChance=0.050000,ShieldDuration=2.000000,TeleportChance=0.150000)
```
