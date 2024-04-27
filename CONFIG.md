# `N7ZedsMut.ini` configuration

## Description

Configuration file allows for setting replacement rules for individual ZEDs or reverting back to default skins.

Also, some ZEDs have configurable properties that can be changed in the `.ini` file.
Here are some hints on what those are supposed to do.

Apart from it, there can also be [Mutate API related settings](./MUTATE.md).

## Default Config

```ini
; ===== ZEDS REPLACEMENT SETTINGS =====
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

; ===== MUTATE API SETTINGS =====
; Access settings for Mutate API commands
; -- 0 = Everyone, 1 = Admin Only
;
[N7ZedsMut.N7ZedsConfigMutateAPI]
flagAdminOnlyCommand[0]=0   ; zeds.help
flagAdminOnlyCommand[1]=0   ; zeds.cfg
flagAdminOnlyCommand[2]=0   ; zeds.skins
flagAdminOnlyCommand[3]=0   ; zeds.clot
flagAdminOnlyCommand[4]=0   ; zeds.crawl
flagAdminOnlyCommand[5]=0   ; zeds.gore
flagAdminOnlyCommand[6]=0   ; zeds.stalk
flagAdminOnlyCommand[7]=0   ; zeds.sc
flagAdminOnlyCommand[8]=0   ; zeds.fp
flagAdminOnlyCommand[9]=0   ; zeds.bloat
flagAdminOnlyCommand[10]=0  ; zeds.siren
flagAdminOnlyCommand[11]=0  ; zeds.husk
flagAdminOnlyCommand[12]=0  ; zeds.boss
flagAdminOnlyCommand[13]=0  ; zeds.all

; Prefix that prepends commands (purely for commands uniqueness purposes, can be any)
Prefix=zeds.

; Commands execution messages
MsgSuccessTemplate=%KEY% set to %VALUE%
MsgAccessDenied=Access Denied

; ===== TO BE IGNORED =====
[XGame.xPawn]
[UnrealGame.UnrealPawn]
[Engine.Pawn]

; ===== ZEDS SETTINGS =====
; CustomMenuName - Zed's display name. Leave empty if default names are preferred.

[N7ZedsMut.N7_Clot]
CustomMenuName=N7 Clot

[N7ZedsMut.N7_Bloat]
CustomMenuName=N7 Bloat

[N7ZedsMut.N7_Gorefast]
CustomMenuName=N7 Gorefast

[N7ZedsMut.N7_Crawler]
CustomMenuName=N7 Crawler

; MinPseudos - Min number of pseudos to be spawned.
; MaxPseudos - Max number of pseudos to be spawned.
; -- In case MaxPseudos=0 - no pseudos will be spawned.
[N7ZedsMut.N7_Stalker]
MinPseudos=0
MaxPseudos=3
CustomMenuName=N7 Stalker

[N7ZedsMut.N7_PseudoStalker]
CustomMenuName=N7 Pseudo Stalker

; MinFireInterval             - Min time between fire shots.
; MaxFireInterval             - Max time between fire shots.
; MovingAttackChance          - Chance of moving attack.
; MovingAttackCertainDistance - Distance starting from which moving attack will always be chosen (if not disabled by setting MovingAttackChance=0).  
[N7ZedsMut.N7_Husk]
MinFireInterval=2.000000
MaxFireInterval=4.000000
MovingAttackChance=0.500000
MovingAttackCertainDistance=2000
CustomMenuName=N7 Husk

; bUseCustomDamageType - Use custom damage type with the agony effect.
[N7ZedsMut.N7_Siren]
CustomMenuName=N7 Siren
bUseCustomDamageType=False

[N7ZedsMut.N7_Scrake]
CustomMenuName=N7 Scrake

; RageStopDistance            - Min distance to player at which raged fleshpound will want to give up raging. 
; RageStopAfterKillChance     - Chance fleshpound will settle down after killing a player.
[N7ZedsMut.N7_Fleshpound]
CustomMenuName=N7 Fleshpound
RageStopDistance=750
RageStopAfterKillChance=0.340000

; PatHealth                     - Patriarch's base HP before players count/difficulty multipliers are applied.
; CGDamage                      - Chaingun damage.
;
; CombatStages[n]               - Group of settings for patriarch's behaviour during n-th stage (n - Number of syringes used).
; -- if a certain setting is omitted - its value defaults to 0.
; -- Distance values are in Unreal Units (uu): 1uu = 0.75in, 1m = 52.5uu.
; -- Chance/Threshold values are in floating point numbers from 0.0 to 1.0.
; -- Cooldown/Duration/Rate values are in floating point numbers: 1.0 = 1s.
;
; ===== COMBAT STAGES PROPERTIES =====
;
; MinPseudos                    - Min number of pseudos to be spawned.
; MaxPseudos                    - Max number of pseudos to be spawned.
; -- In case MaxPseudos=0 - no pseudos will be spawned
;
; KiteChance                    - Chance of successful melee kiting.
;
; ChargeCooldown                - Min time between non-forced patriarch charges at players.
; ForceChargeCooldown           - Min time between forced patriarch charges at players (forced - in response to incoming damage from players).
; ForceChargeDamageThreshold    - Damage as % of current health to make patriarch force charge at players.
; MaxChargeGroupDistance        - Max distance from which patriarch might want to charge at group of players.
; MaxChargeSingleDistance       - Max distance from which patriarch might want to charge at single player.
; RadialAttackCirclersChance    - Change of patriarch radial attacking players circling around him during his chaingun attack (if he's damaged).
;
; CGShots                       - Shots per single chaingun attack.
; CGFireRate                    - Chaingun firerate, time between shots in seconds. Less the value - higher the firerate.
; CGRunChance                   - Chance of patriarch speeding up towards players during moving chaingun attack.
; CGRunDamageThreshold          - Damage as % of current health to make patriarch speed up towards players during moving chaingun attack.
; CGMoveChance                  - Chance of moving chaingun attack.
; CGChargeAtNearbyChance        - Chance of chaingun attack interruption and charging at nearby attacking player.
;
; PseudoSwitchChance            - Chance of patriarch switching places with one of the alive pseudos to avoid taking significant damage. Damage is taken by the pseudo.
; PseudoSwitchCooldown          - Min time between patriarch damage evasions/switches.
; PseudoSwitchDamageThreshold   - Damage as % of current health to make patriarch want to evade next incoming damage by switching places with pseudos.
;
; RLShots                       - Shots per single rocket launcher attack.
; RLFireRate                    - Rocket launcher firerate, time between shots in seconds. Less the value - higher the firerate.
;
; ShieldChance                  - Chance of patriarch activating shield which absorbs incoming damage.
; ShieldDuration                - Duration of the shield in seconds.
; ShieldCooldown                - Min time between shield usages.
;
; ShootObstacleChance           - Chance of patriarch wanting to destroy some obstacles (Doors and pipes with players nearby). 
; ShootObstacleMaxDistance      - Max distance from which patriarch should spot the potential obstacles.
;
; SneakAroundOnHealChance       - Chance of patriarch chosing invisible hunt right after healing
; SneakAroundCooldown           - Min time between invisible hunts.
;
; TeleportChance                - Chance of patriarch teleporting to current target player when they are far enough to reach.
; TeleportCooldown              - Min time between patriarch teleportations.
; TeleportMinDistance           - Min distance to the target the patriarch might want to teleport from.
; TeleportMinApproachDistance   - Min distance to the player the patriarch is able to teleport to. 
; TeleportMaxApproachDistance   - Max distance to the player the patriarch is able to teleport to.
;
; ShieldIgnoreDamageRate        - % of ignored damage in shield state.
; EscapingIgnoreDamageRate      - % of ignored damage in escaping state.
; HealingIgnoreDamageRate       - % of ignored damage in healing state.
;
[N7ZedsMut.N7_Boss]
CustomMenuName=N7 Patriarch
PatHealth=4000
CGDamage=5.000000

CombatStages[0]=(MinPseudos=0,MaxPseudos=0,KiteChance=1.000000,ChargeCooldown=5.000000,ForceChargeCooldown=5.000000,ForceChargeDamageThreshold=0.100000,MaxChargeGroupDistance=400,MaxChargeSingleDistance=700,RadialAttackCirclersChance=0.100000,CGShots=75,CGFireRate=0.050000,CGRunChance=0.100000,CGRunDamageThreshold=0.150000,CGMoveChance=0.100000,CGChargeAtNearbyChance=0.5,PseudoSwitchChance=0.000000,PseudoSwitchCooldown=3.000000,PseudoSwitchDamageThreshold=0.000000,RLShots=1,RLFireRate=0.500000,ShieldChance=0.000000,ShieldDuration=0.000000,ShieldCooldown=5.000000,ShootObstacleChance=0.100000,ShootObstacleMaxDistance=2000,SneakAroundOnHealChance=0.25,SneakAroundCooldown=20.0,TeleportChance=0.000000,TeleportCooldown=20.000000,TeleportMinDistance=1250,TeleportMinApproachDistance=500,TeleportMaxApproachDistance=800,ShieldIgnoreDamageRate=0.250000,EscapingIgnoreDamageRate=0.700000,HealingIgnoreDamageRate=1.000000)

CombatStages[1]=(MinPseudos=0,MaxPseudos=0,KiteChance=0.500000,ChargeCooldown=5.000000,ForceChargeCooldown=4.000000,ForceChargeDamageThreshold=0.100000,MaxChargeGroupDistance=450,MaxChargeSingleDistance=750,RadialAttackCirclersChance=0.200000,CGShots=100,CGFireRate=0.040000,CGRunChance=0.250000,CGRunDamageThreshold=0.150000,CGMoveChance=0.250000,CGChargeAtNearbyChance=0.4,PseudoSwitchChance=0.000000,PseudoSwitchCooldown=3.000000,PseudoSwitchDamageThreshold=0.000000,RLShots=1,RLFireRate=0.400000,ShieldChance=0.000000,ShieldDuration=0.000000,ShieldCooldown=5.000000,ShootObstacleChance=0.200000,ShootObstacleMaxDistance=2000,SneakAroundOnHealChance=0.35,SneakAroundCooldown=20.0,TeleportChance=0.000000,TeleportCooldown=20.000000,TeleportMinDistance=1250,TeleportMinApproachDistance=500,TeleportMaxApproachDistance=800,ShieldIgnoreDamageRate=0.500000,EscapingIgnoreDamageRate=0.600000,HealingIgnoreDamageRate=1.000000)

CombatStages[2]=(MinPseudos=0,MaxPseudos=0,KiteChance=0.250000,ChargeCooldown=5.000000,ForceChargeCooldown=3.500000,ForceChargeDamageThreshold=0.100000,MaxChargeGroupDistance=500,MaxChargeSingleDistance=800,RadialAttackCirclersChance=0.300000,CGShots=100,CGFireRate=0.035000,CGRunChance=0.400000,CGRunDamageThreshold=0.150000,CGMoveChance=0.400000,CGChargeAtNearbyChance=0.3,PseudoSwitchChance=0.000000,PseudoSwitchCooldown=3.000000,PseudoSwitchDamageThreshold=0.000000,RLShots=2,RLFireRate=0.300000,ShieldChance=0.030000,ShieldDuration=1.000000,ShieldCooldown=5.000000,ShootObstacleChance=0.400000,ShootObstacleMaxDistance=2000,SneakAroundOnHealChance=0.5,SneakAroundCooldown=17.5,TeleportChance=0.100000,TeleportCooldown=20.000000,TeleportMinDistance=1250,TeleportMinApproachDistance=500,TeleportMaxApproachDistance=800,ShieldIgnoreDamageRate=0.750000,EscapingIgnoreDamageRate=0.500000,HealingIgnoreDamageRate=0.800000)

CombatStages[3]=(MinPseudos=3,MaxPseudos=5,KiteChance=0.100000,ChargeCooldown=5.000000,ForceChargeCooldown=3.000000,ForceChargeDamageThreshold=0.100000,MaxChargeGroupDistance=500,MaxChargeSingleDistance=850,RadialAttackCirclersChance=0.500000,CGShots=125,CGFireRate=0.030000,CGRunChance=0.500000,CGRunDamageThreshold=0.150000,CGMoveChance=0.500000,CGChargeAtNearbyChance=0.2,PseudoSwitchChance=0.600000,PseudoSwitchCooldown=3.000000,PseudoSwitchDamageThreshold=0.100000,RLShots=3,RLFireRate=0.200000,ShieldChance=0.050000,ShieldDuration=2.000000,ShieldCooldown=5.000000,ShootObstacleChance=0.500000,ShootObstacleMaxDistance=2000,SneakAroundOnHealChance=0.75,SneakAroundCooldown=15.0,TeleportChance=0.150000,TeleportCooldown=20.000000,TeleportMinDistance=1250,TeleportMinApproachDistance=500,TeleportMaxApproachDistance=800,ShieldIgnoreDamageRate=1.000000,EscapingIgnoreDamageRate=0.400000,HealingIgnoreDamageRate=0.700000)

[N7ZedsMut.N7_PseudoBoss]
CustomMenuName=N7 Pseudo Patriarch
```
