class N7_Boss extends KFChar.ZombieBoss_STANDARD
    config(N7ZedsMut);

const NUM_COMBAT_STAGES = 4;

struct CombatStage
{
    var config int
        // Fixed number of chaingun shots
        CGShots,

        // Fixed number of rockets to be shot
        RLShots,

        // Limits of pseudos to be spawned
        MinPseudos,
        MaxPseudos,

        // Charging Distance
        // When multiple enemies
        MaxChargeGroupDistance,
        // When single enemy
        MaxChargeSingleDistance,

        // Teleport Distance
        TeleportMinDistance,
        TeleportMinApproachDistance,
        TeleportMaxApproachDistance,

        // Shooting obstacles distance
        ShootObstacleMaxDistance;

    var config float
        // Chance of melee kiting
        KiteChance,

        ChargeCooldown,

        // Charging from damage
        ForceChargeCooldown,
        ForceChargeDamageThreshold,

        // Chance of moving when attacking with chaingun
        CGMoveChance,
        // Chance of switching to running chaingun attack after being severely damaged
        CGRunChance,
        // Chance of charging at nearby player when damaged enough during chaingun attack
        CGChargeAtNearbyChance,
        // Amount of damage in damage/health ratio needed for patriarch to speed up during chaingun attack
        CGRunDamageThreshold,

        CGFireRate,

        // Rocket Launcher velocity
        RLFireRate,

        // Patriarch can radial attack players circling around patriarch during chaingun attack
        RadialAttackCirclersChance,

        // Patriarch can shoot at pipes or welded doors if there are players nearby
        ShootObstacleChance,

        // Patriarch can activate temporary shield to absorb damage
        ShieldChance,
        ShieldDuration,
        ShieldCooldown,

        // Patriarch's invisible charge
        SneakAroundOnHealChance,
        SneakAroundCooldown,

        // Percentage of damage ignored in different states
        ShieldIgnoreDamageRate,
        EscapingIgnoreDamageRate,
        HealingIgnoreDamageRate,

        // Patriarch can teleport to approach far-away players
        TeleportChance,
        TeleportCooldown,

        // Patriarch can evade large damage shots
        // by switching places with one of the alive pseudos
        PseudoSwitchChance,
        PseudoSwitchCooldown,
        PseudoSwitchDamageThreshold;
};

struct DamageInfo {
    var int Damage;
    var Pawn InstigatedBy;
    var Vector Hitlocation;
    var Vector Momentum;
    var class<DamageType> DamageType;
    var int HitIndex;
};

var config string CustomMenuName;

var config int PatHealth;
var config float CGDamage;
var config CombatStage CombatStages[NUM_COMBAT_STAGES];

// Fallback settings in case of invalid configuration
var const CombatStage DefaultCombatStages[NUM_COMBAT_STAGES];

var int MissileShotsLeft;
var int MissedClawHits;

var int DamageToCharge;
var int DamageToPseudoSwitch;

var float LastDamagedTime;
var float LastShieldTime;
var float LastTeleportTime;
var float LastClawHitMissTime;
var float LastPseudoSwitchTime;

/**
 * Each patriarch has a chance to spawn
 * a squad of pseudos, projections
 * that get killed if the host is dead
 */
var class<N7_PseudoBoss> PseudoClass;
var array<N7_PseudoBoss> PseudoSquad;

var N7_PseudoBoss ClosestPseudo;

var class<BossLAWProj> LAWProjClass;

var const bool bPseudo;
var bool bMovingChaingunAttack;
var bool bRunningChaingunAttack;

replication
{
    reliable if (Role == ROLE_AUTHORITY)
        bMovingChaingunAttack,
        bRunningChaingunAttack;
    reliable if (Role == ROLE_AUTHORITY)
        CustomMenuName;
}

event PreBeginPlay()
{
    super.PreBeginPlay();

    if (!bPseudo && PatHealth > 0)
    {
        default.Health = PatHealth;
        default.HealthMax = PatHealth;
    }
}

simulated function PostBeginPlay()
{
    if (!bPseudo)
        SetupConfig();

    super.PostBeginPlay();
}

simulated function PostNetBeginPlay()
{
    super.PostNetBeginPlay();

    if (CustomMenuName != "")
    {
        default.MenuName = CustomMenuName;
        MenuName = CustomMenuName;
    }
}

// Config validation and setup
function SetupConfig()
{
    local int i;

    if (CGDamage > 0)
        MGDamage = CGDamage;

    for (i = 0; i < NUM_COMBAT_STAGES; i++)
    {
        if (CombatStages[i].CGShots < 0 || CombatStages[i].CGShots > 10000)
            CombatStages[i].CGShots = default.DefaultCombatStages[i].CGShots;
        if (CombatStages[i].RLShots < 0 || CombatStages[i].RLShots > 20)
            CombatStages[i].RLShots = default.DefaultCombatStages[i].RLShots;

        if (CombatStages[i].MinPseudos < 0 || CombatStages[i].MinPseudos > 10 ||
            CombatStages[i].MaxPseudos < 0 || CombatStages[i].MaxPseudos > 10 ||
            CombatStages[i].MinPseudos > CombatStages[i].MaxPseudos)
        {
            CombatStages[i].MinPseudos = default.DefaultCombatStages[i].MinPseudos;
            CombatStages[i].MaxPseudos = default.DefaultCombatStages[i].MaxPseudos;
        }

        if (CombatStages[i].MaxChargeGroupDistance < 0 || CombatStages[i].MaxChargeGroupDistance > 10000)
            CombatStages[i].MaxChargeGroupDistance = default.DefaultCombatStages[i].MaxChargeGroupDistance;

        if (CombatStages[i].MaxChargeSingleDistance < 0 || CombatStages[i].MaxChargeSingleDistance > 10000)
            CombatStages[i].MaxChargeSingleDistance = default.DefaultCombatStages[i].MaxChargeSingleDistance;

        if (CombatStages[i].ChargeCooldown < 0 || CombatStages[i].ChargeCooldown > 100)
            CombatStages[i].ChargeCooldown = default.DefaultCombatStages[i].ChargeCooldown;

        if (CombatStages[i].ForceChargeCooldown < 0 || CombatStages[i].ForceChargeCooldown > 100)
            CombatStages[i].ForceChargeCooldown = default.DefaultCombatStages[i].ForceChargeCooldown;

        if (CombatStages[i].ShieldDuration < 0 || CombatStages[i].ShieldDuration > 10)
            CombatStages[i].ShieldDuration = default.DefaultCombatStages[i].ShieldDuration;
        if (CombatStages[i].ShieldCooldown < 0 || CombatStages[i].ShieldCooldown > 100)
            CombatStages[i].ShieldCooldown = default.DefaultCombatStages[i].ShieldCooldown;

        if (CombatStages[i].SneakAroundCooldown < 0 || CombatStages[i].SneakAroundCooldown > 100)
            CombatStages[i].SneakAroundCooldown = default.DefaultCombatStages[i].SneakAroundCooldown;

        if (CombatStages[i].ShootObstacleMaxDistance < 500 || CombatStages[i].ShootObstacleMaxDistance > 10000)
            CombatStages[i].ShootObstacleMaxDistance = default.DefaultCombatStages[i].ShootObstacleMaxDistance;

        if (CombatStages[i].TeleportCooldown < 0 || CombatStages[i].TeleportCooldown > 100)
            CombatStages[i].TeleportCooldown = default.DefaultCombatStages[i].TeleportCooldown;

        if (CombatStages[i].TeleportMinApproachDistance < 0 || CombatStages[i].TeleportMinApproachDistance > 1000 ||
            CombatStages[i].TeleportMaxApproachDistance < 150 || CombatStages[i].TeleportMaxApproachDistance > 1500 ||
            CombatStages[i].TeleportMinApproachDistance > CombatStages[i].TeleportMaxApproachDistance)
        {
            CombatStages[i].TeleportMinApproachDistance = default.DefaultCombatStages[i].TeleportMinApproachDistance;
            CombatStages[i].TeleportMaxApproachDistance = default.DefaultCombatStages[i].TeleportMaxApproachDistance;
        }

        if (CombatStages[i].TeleportMinDistance < CombatStages[i].TeleportMaxApproachDistance ||
            CombatStages[i].TeleportMinDistance > 10000)
        {
            CombatStages[i].TeleportMinDistance = CombatStages[i].TeleportMaxApproachDistance + 500;
        }

        if (CombatStages[i].PseudoSwitchCooldown < 0 || CombatStages[i].PseudoSwitchCooldown > 100)
            CombatStages[i].PseudoSwitchCooldown = default.DefaultCombatStages[i].PseudoSwitchCooldown;

        CombatStages[i].KiteChance = class'Utils'.static.FRatio(CombatStages[i].KiteChance);
        CombatStages[i].CGMoveChance = class'Utils'.static.FRatio(CombatStages[i].CGMoveChance);
        CombatStages[i].CGRunChance = class'Utils'.static.FRatio(CombatStages[i].CGRunChance);
        CombatStages[i].CGChargeAtNearbyChance = class'Utils'.static.FRatio(CombatStages[i].CGChargeAtNearbyChance);
        CombatStages[i].ShootObstacleChance = class'Utils'.static.FRatio(CombatStages[i].ShootObstacleChance);
        CombatStages[i].ShieldChance = class'Utils'.static.FRatio(CombatStages[i].ShieldChance);
        CombatStages[i].SneakAroundOnHealChance = class'Utils'.static.FRatio(CombatStages[i].SneakAroundOnHealChance);
        CombatStages[i].TeleportChance = class'Utils'.static.FRatio(CombatStages[i].TeleportChance);
        CombatStages[i].PseudoSwitchChance = class'Utils'.static.FRatio(CombatStages[i].PseudoSwitchChance);
        CombatStages[i].RadialAttackCirclersChance = class'Utils'.static.FRatio(CombatStages[i].RadialAttackCirclersChance);

        CombatStages[i].ShieldIgnoreDamageRate = class'Utils'.static.FRatio(CombatStages[i].ShieldIgnoreDamageRate);
        CombatStages[i].EscapingIgnoreDamageRate = class'Utils'.static.FRatio(CombatStages[i].EscapingIgnoreDamageRate);
        CombatStages[i].HealingIgnoreDamageRate = class'Utils'.static.FRatio(CombatStages[i].HealingIgnoreDamageRate);

        CombatStages[i].RLFireRate = class'Utils'.static.FRatio(CombatStages[i].RLFireRate);
        CombatStages[i].CGFireRate = class'Utils'.static.FRatio(CombatStages[i].CGFireRate);

        CombatStages[i].ForceChargeDamageThreshold = class'Utils'.static.FRatio(CombatStages[i].ForceChargeDamageThreshold);
        CombatStages[i].CGRunDamageThreshold = class'Utils'.static.FRatio(CombatStages[i].CGRunDamageThreshold);
        CombatStages[i].PseudoSwitchDamageThreshold = class'Utils'.static.FRatio(CombatStages[i].PseudoSwitchDamageThreshold);
    }
}

simulated function bool HitCanInterruptAction()
{
    return !bWaitForAnim && !bShotAnim;
}

simulated event SetAnimAction(name NewAction)
{
    if (NewAction == '')
    {
        return;
    }

    if (NewAction == 'MeleeClaw' && FRand() > 0.5)
    {
        NewAction = 'MeleeClaw2';
    }

    ExpectingChannel = DoAnimAction(NewAction);

    if (Controller != None)
    {
        BossZombieController(Controller).AnimWaitChannel = ExpectingChannel;
    }

    if (AnimNeedsWait(NewAction))
    {
        bWaitForAnim = True;
    }
    else
    {
        bWaitForAnim = False;
    }

    if (Level.NetMode != NM_Client)
    {
        AnimAction = NewAction;
        bResetAnimAct = True;
        ResetAnimActTime = Level.TimeSeconds + 0.3;
    }
}

simulated function bool AnimNeedsWait(name TestAnim)
{
    if (TestAnim == 'FireMG')
    {
        return !bMovingChaingunAttack;
    }

    return super.AnimNeedsWait(TestAnim);
}

/**
 * Unused MeleeClaw2 animation added
 * Attack animation rate increased
 * Moving chaingun attack animation
 */
simulated function int DoAnimAction(name AnimName)
{
    if (
        AnimName == 'MeleeClaw' ||
        AnimName == 'MeleeClaw2' ||
        AnimName == 'MeleeImpale' ||
        AnimName == 'transition')
    {
        AnimBlendParams(1, 1.0, 0.0,, SpineBone1);
        PlayAnim(AnimName, 1.25, 0.1, 1);

        return 1;
    }
    else if (AnimName == 'RadialAttack')
    {
        AnimBlendParams(1, 0.0);
        PlayAnim(AnimName, 1.25, 0.1);

        return 0;
    }
    else if (AnimName == 'FireMG' && bMovingChaingunAttack)
    {
        AnimBlendParams(1, 1.0, 0.0,, FireRootBone, True);
        PlayAnim(AnimName,, 0.f, 1);

        return 1;
    }
    else if (AnimName == 'FireEndMG')
    {
        AnimBlendParams(1, 0);
    }

    return super(KFMonster).DoAnimAction(AnimName);
}

simulated function AnimEnd(int Channel)
{
    local name Sequence;
    local float Frame, Rate;

    if (Level.NetMode == NM_Client && bMinigunning)
    {
        GetAnimParams(Channel, Sequence, Frame, Rate);

        if (Sequence != 'PreFireMG' && Sequence != 'FireMG')
        {
            super(KFMonster).AnimEnd(Channel);
            return;
        }

        if (bMovingChaingunAttack) {
            DoAnimAction('FireMG');
        }
    }
    else
    {
        super(KFMonster).AnimEnd(Channel);
    }
}

/**
 * The whole purpose of overriding the method below
 * is to provide different material sources
 */

simulated function CloakBoss()
{
    local Controller C;
    local int index;

    if (bZapped)
    {
        return;
    }

    if (bSpotted)
    {
        Visibility = 120;

        if (Level.NetMode == NM_DedicatedServer)
        {
            return;
        }

        Skins[0] = Finalblend'KFX.StalkerGlow';
        Skins[1] = Finalblend'KFX.StalkerGlow';
        bUnlit = True;
        return;
    }

    Visibility = 1;
    bCloaked = True;
    if (Level.NetMode != NM_Client)
    {
        for (C = Level.ControllerList; C != None; C = C.NextController)
        {
            if (C.bIsPlayer && C.Enemy == self)
            {
                C.Enemy = None;
            }
        }
    }

    if (Level.NetMode == NM_DedicatedServer)
    {
        return;
    }

    Skins[0] = default.Skins[2];
    Skins[1] = default.Skins[3];

    if (PlayerShadow != None)
    {
        PlayerShadow.bShadowActive = False;
    }
    Projectors.Remove(0, Projectors.Length);
    bAcceptsProjectors = False;

    if (Level.Game != None && FRand() < 0.10)
    {
        index = Rand(Level.Game.NumPlayers);

        for (C = Level.ControllerList; C != None; C = C.NextController)
        {
            if (PlayerController(C) != None)
            {
                if (index == 0)
                {
                    PlayerController(C).Speech('AUTO', 8, "");
                    break;
                }
                index--;
            }
        }
    }
}

function RangedAttack(Actor A)
{
    local float D;
    local bool bOnlyE, bDesireChainGun;

    if (Controller.LineOfSightTo(A) && FRand() < 0.15 && LastChainGunTime < Level.TimeSeconds)
    {
        bDesireChainGun = True;
    }

    if (bShotAnim)
    {
        return;
    }

    D = VSize(A.Location-Location);
    bOnlyE = (Pawn(A) != None && OnlyEnemyAround(Pawn(A)));

    if (IsCloseEnuf(A))
    {
        bShotAnim = True;

        if (Health > 1500 && Pawn(A) != None && FRand() < 0.5)
        {
            SetAnimAction('MeleeImpale');
        }
        else
        {
            SetAnimAction('MeleeClaw');
        }
    }

    else if (Level.TimeSeconds - LastSneakedTime > GetCombatStage().SneakAroundCooldown)
    {
        if (FRand() < 0.3)
        {
            LastSneakedTime = Level.TimeSeconds - GetCombatStage().SneakAroundCooldown * 0.5 * FMax(FRand(), 0.25);
            return;
        }
        SetAnimAction('transition');
        GoToState('SneakAround');
    }

    else if (
       !bDesireChainGun && D > GetCombatStage().TeleportMinDistance &&
       class'Utils'.static.BChance(GetCombatStage().TeleportChance) &&
       Level.TimeSeconds - LastTeleportTime > GetCombatStage().TeleportCooldown)
    {
        LastTeleportTime = Level.TimeSeconds;
        GoToState('Teleport');
    }

    else if (bChargingPlayer && (bOnlyE || D < 200))
    {
        return;
    }

    else if (
        !bDesireChainGun && !bChargingPlayer &&
        (D < GetCombatStage().MaxChargeGroupDistance || (D < GetCombatStage().MaxChargeSingleDistance && bOnlyE)) &&
        (Level.TimeSeconds - LastChargeTime > (GetCombatStage().ChargeCooldown + 5.0 * FRand())))
    {
        SetAnimAction('transition');
        GoToState('Charging');
    }

    else if (LastMissileTime < Level.TimeSeconds && D > 500)
    {
        if (!Controller.LineOfSightTo(A) || FRand() > 0.75)
        {
            LastMissileTime = Level.TimeSeconds + FRand() * 5;
            return;
        }
        LastMissileTime = Level.TimeSeconds + 7.5 + FRand() * 10;

        bShotAnim = True;
        Acceleration = vect(0, 0, 0);

        SetAnimAction('PreFireMissile');
        HandleWaitForAnim('PreFireMissile');

        GoToState('FireMissile');
    }

    else if (!bWaitForAnim && !bShotAnim && LastChainGunTime < Level.TimeSeconds)
    {
        if (!Controller.LineOfSightTo(A) || FRand() > 0.85)
        {
            LastChainGunTime = Level.TimeSeconds + FRand() * 4;
            return;
        }
        LastChainGunTime = Level.TimeSeconds + 4 + FRand() * 6;

        bShotAnim = True;
        Acceleration = vect(0, 0, 0);

        SetAnimAction('PreFireMG');
        HandleWaitForAnim('PreFireMG');

        MGFireCounter =  GetCombatStage().CGShots + Rand(50);

        GoToState('FireChaingun');
    }
}

function bool FindVisibleObstacle(out Actor TargetObstacle)
{
    local int   NumPlayersNextToPipe,
                NumPlayersNextToTargetPipe,
                NumPlayersNextToDoor,
                NumPlayersNextToTargetDoor;

    local float DistanceToObstacle, MinObstacleBlowDistance;

    local PipeBombProjectile CurrentPipeBomb, TargetPipeBomb;
    local KFDoorMover CurrentDoor, TargetDoor;
    local KFHumanPawn NearbyPlayer;

    if (!class'Utils'.static.BChance(GetCombatStage().ShootObstacleChance) || LastMissileTime >= Level.TimeSeconds)
        return False;

    foreach VisibleActors(class'PipeBombProjectile', CurrentPipeBomb)
    {
        if (CurrentPipeBomb.Damage <= 0 || CurrentPipeBomb.DamageRadius <= 0)
            continue;

        DistanceToObstacle = VSize(Location - CurrentPipeBomb.Location);
        MinObstacleBlowDistance = FMax(CurrentPipeBomb.DamageRadius, LAWProjClass.default.DamageRadius) + 10 + FRand() * 100;

        if (DistanceToObstacle < MinObstacleBlowDistance || DistanceToObstacle > GetCombatStage().ShootObstacleMaxDistance)
            continue;

        foreach CurrentPipeBomb.VisibleCollidingActors(class'KFHumanPawn', NearbyPlayer, CurrentPipeBomb.DamageRadius)
        {
            NumPlayersNextToPipe++;
        }

        if (NumPlayersNextToPipe > 0 && NumPlayersNextToPipe > NumPlayersNextToTargetPipe)
        {
            TargetPipeBomb = CurrentPipeBomb;
            NumPlayersNextToTargetPipe = NumPlayersNextToPipe;
        }

        NumPlayersNextToPipe = 0;
    }

    foreach VisibleActors(class'KFDoorMover', CurrentDoor)
    {
        DistanceToObstacle = VSize(Location - CurrentDoor.Location);
        MinObstacleBlowDistance = LAWProjClass.default.DamageRadius + 10 + FRand() * 100;

        if (!CurrentDoor.bSealed ||
             DistanceToObstacle < MinObstacleBlowDistance ||
             DistanceToObstacle > GetCombatStage().ShootObstacleMaxDistance)
        {
            continue;
        }

        foreach CurrentDoor.VisibleCollidingActors(class'KFHumanPawn', NearbyPlayer, 150.0)
        {
            NumPlayersNextToDoor++;
        }

        if (NumPlayersNextToDoor > 0 && NumPlayersNextToDoor > NumPlayersNextToTargetDoor)
        {
            TargetDoor = CurrentDoor;
            NumPlayersNextToTargetDoor = NumPlayersNextToDoor;
        }
    }

    if (TargetPipeBomb != None)
        TargetObstacle = TargetPipeBomb;
    else if (TargetDoor != None)
        TargetObstacle = TargetDoor;

    return TargetObstacle != None;
}

function AttackVisibleObstacle(Actor TargetObstacle)
{
    if (TargetObstacle == None)
        return;

    Controller.Target = TargetObstacle;
    Controller.Focus = TargetObstacle;

    LastMissileTime = Level.TimeSeconds + 7.5 + FRand() * 10;

    bShotAnim = True;
    Acceleration = vect(0, 0, 0);
    SetAnimAction('PreFireMissile');
    HandleWaitForAnim('PreFireMissile');
    GoToState('FireMissileAtObstacle');
}

function DoorAttack(Actor A)
{
    if (!bShotAnim && A != None && Physics != PHYS_Swimming)
    {
        Controller.Target = A;
        bShotAnim = True;
        Acceleration = vect(0, 0, 0);

        // Melee attack is used to break doors
        SetAnimAction('MeleeImpale');
        HandleWaitForAnim('MeleeImpale');
    }
}

function bool ShouldChargeFromDamage()
{
    local float DamageToHealthRatio, ForceChargeCooldown;

    DamageToHealthRatio = float(DamageToCharge) / float(Health);
    ForceChargeCooldown = GetCombatStage().ForceChargeCooldown * 0.5 + GetCombatStage().ForceChargeCooldown * FRand();

    return !bChargingPlayer
        && (SyringeCount == 3 || Health >= HealingLevels[SyringeCount])
        && Level.TimeSeconds - LastForceChargeTime > ForceChargeCooldown
        && DamageToHealthRatio > GetCombatStage().ForceChargeDamageThreshold;
}

/**
 * ZombieBoss::TakeDamage overridden
 * due to various bugs
 */
function TakeDamage(
    int Damage,
    Pawn InstigatedBy,
    Vector Hitlocation,
    Vector Momentum,
    class<DamageType> DamageType,
    optional int HitIndex)
{
    local KFHumanPawn P;
    local float DamagerDistSq, UsedPipeBombDamScale, DamageToHealthRatio;
    local int OldHealth, NumPlayersSurrounding;
    local bool bDidRadialAttack;

    // Ignore damage instigated by other ZEDs
    if (KFMonster(InstigatedBy) == None)
    {
        // Melee Exploiters check (from ZombieBoss::TakeDamage)
        if (Level.TimeSeconds - LastMeleeExploitCheckTime > 1.0 &&
            (class<DamTypeMelee>(DamageType) != None || class<KFProjectileWeaponDamageType>(DamageType) != None))
        {
            LastMeleeExploitCheckTime = Level.TimeSeconds;

            NumLumberJacks = 0;
            NumNinjas = 0;

            foreach DynamicActors(class'KFHumanPawn', P)
            {
                // look for guys attacking us within 3 meters
                if (VSize(P.Location - Location) < 150)
                {
                    NumPlayersSurrounding++;

                    if (P != None && P.Weapon != None)
                    {
                        if (Axe(P.Weapon) != None || Chainsaw(P.Weapon) != None)
                        {
                            NumLumberJacks++;
                        }
                        else if (Katana(P.Weapon) != None)
                        {
                            NumNinjas++;
                        }
                    }

                    if (!bDidRadialAttack && NumPlayersSurrounding >= 3)
                    {
                        bDidRadialAttack = True;
                        GotoState('RadialAttack');
                        break;
                    }
                }
            }
        }

        if (class<DamTypeCrossbow>(DamageType) == None && class<DamTypeCrossbowHeadShot>(DamageType) == None)
        {
            bOnlyDamagedByCrossbow = False;
        }

        // Pipe bombs damage scaling to prevent killing pat in a single blow (from ZombieBoss::TakeDamage)
        if (class<DamTypePipeBomb>(DamageType) != None)
        {
            UsedPipeBombDamScale = FMax(0, 1.0 - PipeBombDamageScale);
            PipeBombDamageScale += 0.075;

            if (PipeBombDamageScale > 1.0) PipeBombDamageScale = 1.0;

            Damage *= UsedPipeBombDamScale;
        }

        DamageToHealthRatio = float(DamageToPseudoSwitch + Damage) / float(Health);

        if (!bPseudo &&
            !IsInState('Knockdown') &&
            !IsInState('RadialAttack') &&
            !IsInState('Healing') &&
            !IsInState('Escaping') &&
            !IsInState('FireMissile') &&
            !IsInState('FireChaingun') &&
            Level.TimeSeconds - LastPseudoSwitchTime > GetCombatStage().PseudoSwitchCooldown &&
            class'Utils'.static.BChance(GetCombatStage().PseudoSwitchChance) &&
            DamageToHealthRatio > GetCombatStage().PseudoSwitchDamageThreshold &&
            FindClosestPseudo())
        {
            ClosestPseudo.EvasionDamage.Damage = Damage;
            ClosestPseudo.EvasionDamage.InstigatedBy = InstigatedBy;
            ClosestPseudo.EvasionDamage.HitLocation = HitLocation;
            ClosestPseudo.EvasionDamage.Momentum = Momentum;
            ClosestPseudo.EvasionDamage.DamageType = DamageType;
            ClosestPseudo.EvasionDamage.HitIndex = HitIndex;

            DamageToPseudoSwitch = 0;

            SetAnimAction('transition');
            GoToState('EvadeDamage');
            return;
        }

        OldHealth = Health;
        super(KFMonster).TakeDamage(Damage, InstigatedBy, Hitlocation, Momentum, DamageType);

        if (Health <= 0 ||
            IsInState('Escaping') && !IsInState('SneakAround') ||
            IsInState('KnockDown') ||
            IsInState('RadialAttack') ||
            bDidRadialAttack || bPseudo)
        {
            return;
        }

        // Charging from damage (implementation in ZombieBoss::TakeDamage doesn't work properly)
        if (LastDamagedTime > 0 && Level.TimeSeconds - LastDamagedTime > (5.0 + FRand() * 5.0))
        {
            DamageToCharge = 0;
        }

        DamageToCharge += OldHealth - Health;

        if (LastDamagedTime > 0 && Level.TimeSeconds - LastDamagedTime > 3.0)
            DamageToPseudoSwitch = OldHealth - Health;
        else DamageToPseudoSwitch += OldHealth - Health;

        LastDamagedTime = Level.TimeSeconds;

        if (InstigatedBy != None && ShouldChargeFromDamage())
        {
            DamagerDistSq = VSizeSquared(Location - InstigatedBy.Location);

            if (DamagerDistSq < Max(GetCombatStage().MaxChargeGroupDistance, GetCombatStage().MaxChargeSingleDistance))
            {
                DamageToCharge = 0;
                LastForceChargeTime = Level.TimeSeconds;
                GoToState('Charging');

                return;
            }
        }

        // Knockdown (from ZombieBoss::TakeDamage)
        if (SyringeCount < 3 && Health < HealingLevels[SyringeCount])
        {
            bShotAnim = True;
            Acceleration = vect(0, 0, 0);
            SetAnimAction('KnockDown');
            HandleWaitForAnim('KnockDown');
            KFMonsterController(Controller).bUseFreezeHack = True;
            GoToState('KnockDown');

            return;
        }

        // Enable shield
        if (class'Utils'.static.BChance(GetCombatStage().ShieldChance) &&
            Level.TimeSeconds - LastShieldTime > GetCombatStage().ShieldCooldown)
        {
            LastShieldTime = Level.TimeSeconds;
            GoToState('Shield');

            return;
        }
    }
}

function ClawDamageTarget()
{
    local Vector PushDir;
    local name Anim;
    local float Frame, Rate, UsedMeleeDamage;
    local bool bDamagedSomeone, bChargeFromKite;
    local KFHumanPawn P;
    local Actor OldTarget;

    if (MeleeDamage > 1)
    {
        UsedMeleeDamage = (MeleeDamage - (MeleeDamage * 0.05)) + (MeleeDamage * (FRand() * 0.1));
    }
    else
    {
        UsedMeleeDamage = MeleeDamage;
    }

    GetAnimParams(1, Anim, Frame, Rate);

    if (Anim == 'MeleeImpale')
    {
        MeleeRange = ImpaleMeleeDamageRange;
    }
    else
    {
        MeleeRange = ClawMeleeDamageRange;
    }

    if (Controller != None && Controller.Target != None)
        PushDir = (damageForce * Normal(Controller.Target.Location - Location));
    else
        PushDir = damageForce * Vector(Rotation);

    if (Anim == 'MeleeImpale')
    {
        bDamagedSomeone = MeleeDamageTarget(UsedMeleeDamage, PushDir);
    }
    else if (Controller != None)
    {
        OldTarget = Controller.Target;
        foreach DynamicActors(class'KFMod.KFHumanPawn', P)
        {
            if ((P.Location - Location) dot PushDir > 0.0)
            {
                Controller.Target = P;
                bDamagedSomeone = bDamagedSomeone || MeleeDamageTarget(UsedMeleeDamage, damageForce * Normal(P.Location - Location));
            }
        }
        Controller.Target = OldTarget;
    }

    MeleeRange = default.MeleeRange;

    /**
     * Kite fix: charge if melee attack didn't hit the target
     * There's still a chance of avoiding charging
     */
    bChargeFromKite = !class'Utils'.static.BChance(GetCombatStage().KiteChance);

    if (bDamagedSomeone)
    {
        if (MissedClawHits > 0)
        {
            MissedClawHits = 0;
        }

        if (Anim == 'MeleeImpale')
        {
            PlaySound(MeleeImpaleHitSound, SLOT_Interact, 2.0);
        }
        else
        {
            PlaySound(MeleeAttackHitSound, SLOT_Interact, 2.0);
        }
    }
    else if (Controller != None && Controller.Target != None && !IsInState('Escaping'))
    {
        if (Level.TimeSeconds - LastClawHitMissTime < FRand() * 2.0 + 2.0)
        {
            MissedClawHits++;

            if (bChargeFromKite && MissedClawHits > Rand(1) + 1)
            {
                LastClawHitMissTime = Level.TimeSeconds;
                GoToState('Charging');
            }
        }
        else
        {
            MissedClawHits = 1;
            LastClawHitMissTime = Level.TimeSeconds;
        }

    }
}

function SpawnPseudoSquad()
{
    local KFGameType KFGT;

    local array< class<N7_PseudoBoss> > NextPseudoSquad;
    local array<ZombieVolume> ZVols;

    local N7_PseudoBoss CurrentPseudoBoss;
    local ZombieVolume CurrentZVol;
    local Vector TrySpawnPoint;

    local int PseudoSquadSize, MinPseudoSquadSize, MaxPseudoSquadSize, i, j;

    KFGT = KFGameType(Level.Game);

    MinPseudoSquadSize = GetCombatStage().MinPseudos;
    MaxPseudoSquadSize = GetCombatStage().MaxPseudos;

    if (KFGT == None || MaxPseudoSquadSize <= 0 || MaxPseudoSquadSize < MinPseudoSquadSize)
    {
        return;
    }

    PseudoSquadSize = MinPseudoSquadSize + Rand(MaxPseudoSquadSize - MinPseudoSquadSize + 1);

    NextPseudoSquad.Length = 1;
    NextPseudoSquad[0] = PseudoClass;

    for (i = 0; i < KFGT.ZedSpawnList.Length; i++)
    {
        if (KFGT.ZedSpawnList[i].ZombieCountMulti == 1.0 &&
            KFGT.ZedSpawnList[i].CanSpawnInHere(NextPseudoSquad))
        {
            KFGT.ZedSpawnList[i].Reset();
            ZVols[ZVols.Length] = KFGT.ZedSpawnList[i];
        }
    }

    for (i = 0; i < PseudoSquadSize; i++)
    {
        CurrentZVol = ZVols[Rand(ZVols.Length)];
        CurrentPseudoBoss = None;

        for (j = 0; j < CurrentZVol.SpawnPos.Length; j++)
        {
            TrySpawnPoint = CurrentZVol.SpawnPos[j];

            if (!CurrentZVol.PlayerCanSeePoint(TrySpawnPoint, PseudoClass))
                CurrentPseudoBoss = CurrentZVol.Spawn(PseudoClass,,,TrySpawnPoint);

            if (CurrentPseudoBoss != None)
                break;
        }

        if (CurrentPseudoBoss == None)
            CurrentPseudoBoss = Spawn(PseudoClass);

        if (CurrentPseudoBoss != None)
            PseudoSquad[PseudoSquad.Length] = CurrentPseudoBoss;
    }
}

function bool FindClosestPseudo()
{
    local int i;
    local float MinDistanceTo, CurrentDistanceTo;

    if (PseudoSquad.Length == 0)
        return False;

    for (i = 0; i < PseudoSquad.Length; i++)
    {
        if (PseudoSquad[i] != None && PseudoSquad[i].Health > 0)
        {
            CurrentDistanceTo = VSize(PseudoSquad[i].Location - Location);

            if ((MinDistanceTo == 0 && ClosestPseudo == None) || CurrentDistanceTo < MinDistanceTo)
            {
                MinDistanceTo = CurrentDistanceTo;
                ClosestPseudo = PseudoSquad[i];
            }
        }
    }

    return ClosestPseudo != None;
}

function KillPseudoSquad()
{
    local int i;

    if (PseudoSquad.Length == 0)
    {
        return;
    }

    for (i = 0; i < PseudoSquad.Length; i++)
    {
        if (PseudoSquad[i] != None)
        {
            PseudoSquad[i].Died(LastDamagedBy.Controller, LastDamagedByType, Location);
            PseudoSquad[i] = None;
        }
    }

    PseudoSquad.Length = 0;
}

function TogglePseudoSquadActorBlocking(bool bShouldBlockActors)
{
    local int i;

    if (PseudoSquad.Length == 0)
    {
        return;
    }

    for (i = 0; i < PseudoSquad.Length; i++)
    {
        if (PseudoSquad[i] != None)
        {
            PseudoSquad[i].bBlockActors = bShouldBlockActors;
        }
    }
}

/** Don't drop needle on this stage */
simulated function NotifySyringeA()
{
    if (Level.NetMode != NM_Client)
    {
        if (SyringeCount < 3)
        {
            SyringeCount++;
        }
        if (Level.NetMode != NM_DedicatedServer)
        {
            PostNetReceive();
        }
    }
}

/** Spawn pseudo squad after the last healing stage */
simulated function NotifySyringeC()
{
    if (Level.NetMode != NM_DedicatedServer)
    {
        CurrentNeedle = Spawn(class'KFChar.BossHPNeedle');

        if (CurrentNeedle != None)
        {
            AttachToBone(CurrentNeedle,'Rpalm_MedAttachment');
            CurrentNeedle.Velocity = vect(-45, 300, -90) >> Rotation;
            DropNeedle();
        }
    }

    if (!bPseudo && GetCombatStage().MaxPseudos > 0)
    {
        SpawnPseudoSquad();
    }
}

simulated function PlayDying(class<DamageType> DamageType, Vector HitLoc)
{
    super.PlayDying(DamageType, HitLoc);

    if (!bPseudo)
    {
        KillPseudoSquad();
    }

    if (bUnlit)
        bUnlit = !bUnlit;

    if (!bCrispified)
    {
        Skins[0] = default.Skins[0];
        Skins[1] = default.Skins[1];
    }
}

/**
 * Shield state activates when patriarch gets damaged
 * Incoming damage is absorbed in this state
 */
state Shield
{
ignores StartBurnFX, StopBurnFX;

    function TakeDamage(
        int Damage, Pawn InstigatedBy, Vector Hitlocation, Vector Momentum, class<DamageType> DamageType, optional int HitIndex)
    {
        local float DamageIgnoreMultiplier;
        DamageIgnoreMultiplier = 1.0 - GetCombatStage().ShieldIgnoreDamageRate;

        if (KFHumanPawn(InstigatedBy) != None && DamageIgnoreMultiplier != 0)
        {
            super.TakeDamage(Damage * DamageIgnoreMultiplier, InstigatedBy, Hitlocation, Momentum, DamageType, HitIndex);
        }
    }

Begin:
    SetOverlayMaterial(Finalblend'KFX.StalkerGlow', GetCombatStage().ShieldDuration, True);
    Sleep(GetCombatStage().ShieldDuration);

    GoToState('');
}

/** Teleport when patriarch is far enough from players */
state Teleport
{
ignores RangedAttack, StartBurnFX, StopBurnFX;

    function TeleportToPlayers()
    {
        local NavigationPoint NP, TeleportTarget;

        local float BestTeleportDistance, PlayerDistanceToPoint, BossDistanceToPoint;

        if (Controller.Enemy == None && !MonsterController(Controller).FindNewEnemy())
            return;

        for (NP = Level.NavigationPointList; NP != None; NP = NP.NextNavigationPoint)
        {
            PlayerDistanceToPoint = VSize(NP.Location - Controller.Enemy.Location);

            if (!NP.taken && !NP.bBlocked &&
                PlayerDistanceToPoint >= GetCombatStage().TeleportMinApproachDistance &&
                PlayerDistanceToPoint <= GetCombatStage().TeleportMaxApproachDistance &&
                Controller.Enemy.FastTrace(NP.Location, Controller.Enemy.Location + Controller.Enemy.EyePosition()) &&
                FastTrace(NP.Location, Location + EyePosition()))
            {
                BossDistanceToPoint = VSize(NP.Location - Location);

                if (TeleportTarget == None ||
                    BossDistanceToPoint + PlayerDistanceToPoint < BestTeleportDistance + Rand(50))
                {
                    TeleportTarget = NP;
                    BestTeleportDistance = BossDistanceToPoint + PlayerDistanceToPoint;
                }
            }
        }

        if (TeleportTarget == None)
            return;

        TeleportTarget.Accept(self, self.Anchor);
    }

Begin:
    SetOverlayMaterial(Finalblend'KFX.StalkerGlow', 0.75, True);
    Sleep(0.15);

    TeleportToPlayers();

    if (KFMonsterController(Controller) != None)
        KFMonsterController(Controller).ExecuteWhatToDoNext();

    if (Controller != None)
        Controller.WaitForLanding();

    GoToState('');
}

/** Patriarch evades damage switching himself with one
 * of the alive pseudos who takes the damage instead
 */
state EvadeDamage
{
ignores RangedAttack, StartBurnFX, StopBurnFX;

    function DoPseudoSwitch()
    {
        local Vector ClosestPseudoLocation, BossLocation;
        local Rotator ClosestPseudoRotation, BossRotation;

        ClosestPseudoLocation = ClosestPseudo.Location;
        ClosestPseudoRotation = ClosestPseudo.Rotation;
        BossLocation = Location;
        BossRotation = Rotation;

        ClosestPseudo.ClientSetLocation(BossLocation, BossRotation);
        ClientSetLocation(ClosestPseudoLocation, ClosestPseudoRotation);

        ClosestPseudo.bAboutToDie = True;
        ClosestPseudo.LastEvadeTime = Level.TimeSeconds;
    }

Begin:
    SetOverlayMaterial(Finalblend'KFX.StalkerGlow', 0.75, True);

    bBlockActors = False;
    TogglePseudoSquadActorBlocking(False);

    DoPseudoSwitch();

    ClosestPseudo = None;

    bBlockActors = True;
    TogglePseudoSquadActorBlocking(True);

    LastPseudoSwitchTime = Level.TimeSeconds;

    if (KFMonsterController(Controller) != None)
        KFMonsterController(Controller).ExecuteWhatToDoNext();

    if (Controller != None)
        Controller.WaitForLanding();

    GoToState('');
}

/** Charge distance increased */
state Charging
{
    function bool ShouldChargeFromDamage()
    {
        return False;
    }

    function RangedAttack(Actor A)
    {
        if (VSize(A.Location - Location) > Max(
                GetCombatStage().MaxChargeGroupDistance,
                GetCombatStage().MaxChargeSingleDistance
            ) &&
            Level.TimeSeconds - LastForceChargeTime > 3.0)
        {
            GoToState('');
        }
        else
        {
            global.RangedAttack(A);
        }
    }

Begin:
    Sleep(6);
    GoToState('');
}

/** Damage reduction + invisibility when escaping */
state Escaping
{
ignores RangedAttack, StartBurnFX, StopBurnFX;

    function BeginState()
    {
        super.BeginState();
        bBlockActors = False;
        bIgnoreEncroachers = True;
        MotionDetectorThreat = 0;
    }

    function EndState()
    {
        super.EndState();
        bIgnoreEncroachers = False;
        bBlockActors = True;
        MotionDetectorThreat = default.MotionDetectorThreat;
    }

    function TakeDamage(
        int Damage, Pawn InstigatedBy, Vector Hitlocation, Vector Momentum, class<DamageType> DamageType, optional int HitIndex)
    {
        local float DamageIgnoreMultiplier;
        DamageIgnoreMultiplier = 1.0 - GetCombatStage().EscapingIgnoreDamageRate;

        if (KFHumanPawn(InstigatedBy) != None && DamageIgnoreMultiplier != 0)
        {
            super.TakeDamage(Damage * DamageIgnoreMultiplier, InstigatedBy, Hitlocation, Momentum, DamageType, HitIndex);
        }
    }
}

/** Damage reduction + invisibility when healing */
state Healing
{
ignores RangedAttack, StartBurnFX, StopBurnFX;

    function BeginState()
    {
        super.BeginState();
        bBlockActors = False;
        bIgnoreEncroachers = True;
        MotionDetectorThreat = 0;

        if (!bCloaked)
        {
            CloakBoss();
        }
    }

    function EndState()
    {
        super.EndState();
        bIgnoreEncroachers = False;
        bBlockActors = True;
        MotionDetectorThreat = default.MotionDetectorThreat;

        if (bCloaked)
        {
            UnCloakBoss();
        }
    }

    function TakeDamage(
        int Damage, Pawn InstigatedBy, Vector Hitlocation, Vector Momentum, class<DamageType> DamageType, optional int HitIndex)
    {
        local float DamageIgnoreMultiplier;
        DamageIgnoreMultiplier = 1.0 - GetCombatStage().HealingIgnoreDamageRate;

        if (KFHumanPawn(InstigatedBy) != None && DamageIgnoreMultiplier != 0)
        {
            super.TakeDamage(Damage * DamageIgnoreMultiplier, InstigatedBy, Hitlocation, Momentum, DamageType, HitIndex);
        }
    }

Begin:
    Sleep(GetAnimDuration('Heal'));

    if (class'Utils'.static.BChance(GetCombatStage().SneakAroundOnHealChance))
        GoToState('SneakAround');
    else GoToState('');
}

/**
 * Depending on distance and configuration
 * Patriarch can do either moving or stationary chaingun attack
 * Moving attack is less accurate yet more efficient on smaller distance
 */
state FireChaingun
{
    function bool IsMovingChaingunAttack(Actor A)
    {
        local float MoveChance, MovingAttackChanceMultiplierByDistance;

        if (A == None)
            return False;

        MoveChance = GetCombatStage().CGMoveChance;
        MovingAttackChanceMultiplierByDistance = 1.0 - FMin(VSize(A.Location - Location) / 2000.0, 1.0);

        // if configuration is strict about turning moving attack on or off - so be it
        if (MoveChance == 0.0 || MoveChance == 1.0)
            return bool(MoveChance);

        // if target is too far - no sense in moving chaingun attack
        else if (MovingAttackChanceMultiplierByDistance == 0)
            return False;

        // if target is too close - better move
        else if (MovingAttackChanceMultiplierByDistance < 0.15)
            return True;

        // otherwise consider both configuration settings and the distance
        return class'Utils'.static.BChance((MoveChance + MovingAttackChanceMultiplierByDistance) / 2.0);
    }

    function BeginState()
    {
        super.BeginState();

        bMovingChaingunAttack = IsMovingChaingunAttack(Controller.Target);
        bCanStrafe = True;
    }

    function EndState()
    {
        bMovingChaingunAttack = False;
        bRunningChaingunAttack = False;
        bCanStrafe = False;
        super.EndState();
    }

    function Tick(float Delta)
    {
        super(KFMonster).Tick(Delta);

        if (bRunningChaingunAttack)
        {
            SetGroundSpeed(GetOriginalGroundSpeed() * 1.75);
        }
    }

    simulated function AnimEnd(int Channel)
    {
        if (MGFireCounter <= 0)
        {
            bShotAnim = True;
            Acceleration = vect(0, 0, 0);
            SetAnimAction('FireEndMG');
            HandleWaitForAnim('FireEndMG');
            GoToState('');
        }
        else if (bMovingChaingunAttack)
        {
            if (bFireAtWill && Channel != 1)
                return;

            if (Controller.Target != None)
                Controller.Focus = Controller.Target;

            bShotAnim = False;
            bFireAtWill = True;
            SetAnimAction('FireMG');
        }
        else
        {
            if (Controller.Enemy != None)
            {
                if (Controller.LineOfSightTo(Controller.Enemy) &&
                    FastTrace(GetBoneCoords('tip').Origin, Controller.Enemy.Location))
                {
                    MGLostSightTimeout = 0.0;
                    Controller.Focus = Controller.Enemy;
                    Controller.FocalPoint = Controller.Enemy.Location;
                }
                else
                {
                    MGLostSightTimeout = Level.TimeSeconds + (0.25 + FRand() * 0.35);
                    Controller.Focus = None;
                }
                Controller.Target = Controller.Enemy;
            }
            else
            {
                MGLostSightTimeout = Level.TimeSeconds + (0.25 + FRand() * 0.35);
                Controller.Focus = None;
            }

            if (Controller.Target != None)
            {
                Controller.Focus = Controller.Target;
            }

            if (!bFireAtWill)
            {
                MGFireDuration = Level.TimeSeconds + (0.75 + FRand() * 0.5);
            }

            bFireAtWill = True;
            bShotAnim = True;
            Acceleration = vect(0, 0, 0);

            SetAnimAction('FireMG');
            bWaitForAnim = True;
        }

        if (FRand() < 0.03 && Controller.Enemy != None && PlayerController(Controller.Enemy.Controller) != None)
        {
            // Randomly send out a message about Patriarch shooting chain gun(3% chance)
            PlayerController(Controller.Enemy.Controller).Speech('AUTO', 9, "");
        }
    }

    function FireMGShot()
    {
        local Vector Start, End, HL, HN, Dir;
        local Rotator R;
        local Actor A;

        MGFireCounter--;

        if (AmbientSound != MiniGunFireSound)
        {
            SoundVolume=255;
            SoundRadius=400;
            AmbientSound = MiniGunFireSound;
        }

        Start = GetBoneCoords('tip').Origin;

        if (Controller.Focus != None)
        {
            R = Rotator(Controller.Focus.Location - Start);
        }
        else R = Rotator(Controller.FocalPoint - Start);

        if (NeedToTurnFor(R))
            R = Rotation;

        // Accuracy increased when it's not a moving attack
        if (bRunningChaingunAttack)
            Dir = Normal(Vector(R) + VRand() * 0.07);
        else if (bMovingChaingunAttack)
            Dir = Normal(Vector(R) + VRand() * 0.05);
        else
            Dir = Normal(Vector(R) + VRand() * 0.025);

        End = Start + Dir * 10000;

        // Have to turn of hit point collision so trace doesn't hit the Human Pawn's bullet whiz cylinder
        bBlockHitPointTraces = False;
        A = Trace(HL, HN, End, Start, True);
        bBlockHitPointTraces = True;

        if (A == None)
            return;

        TraceHitPos = HL;
        if (Level.NetMode != NM_DedicatedServer)
            AddTraceHitFX(HL);

        if (A != Level)
        {
            A.TakeDamage(MGDamage + Rand(3), Self, HL, Dir * 500, class'DamageType');
        }
    }

    function TakeDamage(
        int Damage,
        Pawn InstigatedBy,
        Vector Hitlocation,
        Vector Momentum,
        class<DamageType> DamageType,
        optional int HitIndex)
    {
        local float EnemyDistSq, DamagerDistSq, DamageToHealthRatio;
        local KFHumanPawn P;

        global.TakeDamage(Damage, InstigatedBy, Hitlocation, Momentum, DamageType);

        if (InstigatedBy != None)
        {
            DamagerDistSq = VSizeSquared(Location - InstigatedBy.Location);
            DamageToHealthRatio = float(DamageToCharge) / float(Health);

            // if someone is too close to patriarch while he's shooting a chaingun
            // and anyone at the same time damages him, he attacks the players around
            if (DamageToHealthRatio > GetCombatStage().ForceChargeDamageThreshold &&
                class'Utils'.static.BChance(GetCombatStage().RadialAttackCirclersChance))
            {
                foreach VisibleCollidingActors(class'KFHumanPawn', P, 150.0)
                {
                    DamageToCharge = 0;
                    LastForceChargeTime = Level.TimeSeconds;

                    SetAnimAction('transition');
                    GoToState('RadialAttack');
                    return;
                }
            }

            // if someone is shooting us heavily during moving chaingun attack
            // approach them at higher speed
            if (!bRunningChaingunAttack && bMovingChaingunAttack &&
                class'Utils'.static.BChance(GetCombatStage().CGRunChance) &&
                DamageToHealthRatio > GetCombatStage().CGRunDamageThreshold)
            {
                bRunningChaingunAttack = True;
                DamageToCharge = 0;

                return;
            }
            // if someone nearby is shooting us, just charge them
            else if (!bRunningChaingunAttack &&
                class'Utils'.static.BChance(GetCombatStage().CGChargeAtNearbyChance) &&
                (DamageToHealthRatio > GetCombatStage().ForceChargeDamageThreshold && DamagerDistSq < (500 * 500)))
            {
                DamageToCharge = 0;
                LastForceChargeTime = Level.TimeSeconds;

                SetAnimAction('transition');
                GoToState('Charging');
                return;
            }
        }

        if (Controller == None)
            return;

        if (Controller.Enemy != None && InstigatedBy != None && InstigatedBy != Controller.Enemy)
        {
            EnemyDistSq = VSizeSquared(Location - Controller.Enemy.Location);
            DamagerDistSq = VSizeSquared(Location - InstigatedBy.Location);
        }

        if (InstigatedBy != None && (DamagerDistSq < EnemyDistSq || Controller.Enemy == None))
        {
            MonsterController(Controller).ChangeEnemy(InstigatedBy,Controller.CanSee(InstigatedBy));
            Controller.Target = InstigatedBy;
            Controller.Focus = InstigatedBy;

            if (DamagerDistSq < (500 * 500))
            {
                SetAnimAction('transition');
                GoToState('Charging');
            }
        }
    }

    simulated function bool HitCanInterruptAction()
    {
        return False;
    }

    function bool ShouldChargeFromDamage()
    {
        return False;
    }

Begin:
    while (True)
    {
        if (!bMovingChaingunAttack)
        {
            Acceleration = vect(0, 0, 0);
        }

        if (MGFireCounter <= 0 || (MGLostSightTimeout > 0 && Level.TimeSeconds > MGLostSightTimeout))
        {
            bShotAnim = True;
            Acceleration = vect(0, 0, 0);
            SetAnimAction('FireEndMG');
            HandleWaitForAnim('FireEndMG');
            GoToState('');
        }
        else
        {
            if (!bMovingChaingunAttack && Level.TimeSeconds > MGFireDuration)
            {
                if (AmbientSound != MiniGunSpinSound)
                {
                    SoundVolume=185;
                    SoundRadius=200;
                    AmbientSound = MiniGunSpinSound;
                }
                Sleep(0.5 + FRand() * 0.75);
                MGFireDuration = Level.TimeSeconds + (0.75 + FRand() * 0.5);
            }
            else
            {
                if (bFireAtWill)
                    FireMGShot();

                Sleep(GetCombatStage().CGFireRate);
            }
        }
    }
}

/** Shoots multiple missiles per attack */
state FireMissile
{
    function RangedAttack(Actor A)
    {
        if (MissileShotsLeft > 1)
        {
            Controller.Target = A;
            Controller.Focus = A;
        }
    }

    function BeginState()
    {
        MissileShotsLeft = GetCombatStage().RLShots + Rand(3);
        Acceleration = vect(0, 0, 0);
    }

    function EndState()
    {
        MissileShotsLeft = 0;
    }

    simulated function AnimEnd(int Channel)
    {
        local Vector Start;
        local Rotator R;

        Start = GetBoneCoords('tip').Origin;

        if (Controller.Target == None)
        {
            Controller.Target = Controller.Enemy;
        }

        if (!SavedFireProperties.bInitialized)
        {
            SavedFireProperties.AmmoClass = class'Old2K4.SkaarjAmmo';
            SavedFireProperties.ProjectileClass = LAWProjClass;
            SavedFireProperties.WarnTargetPct = 0.15;
            SavedFireProperties.MaxRange = 10000;
            SavedFireProperties.bTossed = False;
            SavedFireProperties.bLeadTarget = True;
            SavedFireProperties.bInitialized = True;
        }
        SavedFireProperties.bInstantHit = (SyringeCount < 1);
        SavedFireProperties.bTrySplash = (SyringeCount >= 2);

        R = AdjustAim(SavedFireProperties, Start, 100);
        PlaySound(RocketFireSound, SLOT_Interact, 2.0,, TransientSoundRadius,, False);
        Spawn(LAWProjClass,,, Start, R);

        bShotAnim = True;
        Acceleration = vect(0, 0, 0);
        SetAnimAction('FireEndMissile');
        HandleWaitForAnim('FireEndMissile');

        if (FRand() < 0.05 && Controller.Enemy != None && PlayerController(Controller.Enemy.Controller) != None)
        {
            PlayerController(Controller.Enemy.Controller).Speech('AUTO', 10, "");
        }

        MissileShotsLeft--;
        if (MissileShotsLeft > 0)
        {
            GoToState(, 'NextShot');
        }
        else
        {
            GoToState('');
        }
    }

    simulated function bool HitCanInterruptAction()
    {
        return False;
    }

    function bool ShouldChargeFromDamage()
    {
        return False;
    }

Begin:
    while (True)
    {
        Acceleration = vect(0, 0, 0);
        Sleep(GetAnimDuration('PreFireMissile'));
    }

NextShot:
    Acceleration = vect(0, 0, 0);
    Sleep(GetCombatStage().RLFireRate);
    AnimEnd(0);
}

state FireMissileAtObstacle extends FireMissile
{
ignores RangedAttack;

    function BeginState()
    {
        local KFDoorMover TargetDoor;

        if (Controller.Target != None)
        {
            if (KFDoorMover(Controller.Target) != None)
            {
                TargetDoor = KFDoorMover(Controller.Target);

                MissileShotsLeft = Min(
                    Ceil(TargetDoor.WeldStrength / (LAWProjClass.default.Damage * TargetDoor.ZombieDamageReductionFactor)) + 1,
                    5);
            }
            else MissileShotsLeft = 1;

            Acceleration = vect(0, 0, 0);
        }
    }
}

state RadialAttack
{
ignores RangedAttack;

    // Removed line causing slomo effect
    function ClawDamageTarget()
    {
        local Vector PushDir;
        local float UsedMeleeDamage;
        local bool bDamagedSomeone, bDamagedThisHit;
        local KFHumanPawn P;
        local Actor OldTarget;
        local float RadialDamageBase;

        MeleeRange = 150;

        if (Controller != None && Controller.Target != None)
            PushDir = (DamageForce * Normal(Controller.Target.Location - Location));
        else
            PushDir = DamageForce * Vector(Rotation);

        OldTarget = Controller.Target;

        CurrentDamtype = ZombieDamType[0];

        // Damage all players within a radius
        foreach DynamicActors(class'KFHumanPawn', P)
        {
            if (VSize(P.Location - Location) < MeleeRange)
            {
                Controller.Target = P;

                // This attack cuts through shields, so crank up the damage if they have a lot of shields
                if (P.ShieldStrength >= 50)
                {
                    RadialDamageBase = 240;
                }
                else
                {
                    RadialDamageBase = 120;
                }

                // Randomize the damage a bit so everyone gets really hurt, but only some poeple die
                UsedMeleeDamage = (RadialDamageBase - (RadialDamageBase * 0.55)) + (RadialDamageBase * (FRand() * 0.45));

                bDamagedThisHit =  MeleeDamageTarget(UsedMeleeDamage, DamageForce * Normal(P.Location - Location));
                if (!bDamagedSomeone && bDamagedThisHit)
                {
                    bDamagedSomeone = true;
                }
                MeleeRange = 150;
            }
        }

        Controller.Target = OldTarget;

        MeleeRange = default.MeleeRange;

        if (bDamagedSomeone)
        {
            PlaySound(MeleeAttackHitSound, SLOT_Interact, 2.0);
        }
    }

Begin:
    bShotAnim = True;
    Acceleration = vect(0, 0, 0);

    SetAnimAction('RadialAttack');
    KFMonsterController(Controller).bUseFreezeHack = True;
    Controller.GoToState('WaitForAnim');
    BossZombieController(Controller).SetWaitForAnimTimout(GetAnimDuration('RadialAttack') / 2.5, 'RadialAttack');
    Sleep(GetAnimDuration('RadialAttack') / 2.5);
    StopAnimating();

    SetAnimAction('transition');
    GotoState('');
}

function CombatStage GetCombatStage()
{
    return CombatStages[SyringeCount];
}

/** No zapped behaviour */
function SetZapped(float ZapAmount, Pawn Instigator) {}

simulated function SetZappedBehavior() {}
simulated function UnSetZappedBehavior() {}

/** No crisping up */
simulated function ZombieCrispUp() {}

defaultProperties
{
    CustomMenuName="N7 Patriarch"

    CombatStages(0)=(MinPseudos=0,MaxPseudos=0,KiteChance=0.75,ChargeCooldown=5.0,ForceChargeCooldown=5.0,ForceChargeDamageThreshold=0.1,MaxChargeGroupDistance=400,MaxChargeSingleDistance=700,RadialAttackCirclersChance=0.1,CGShots=75,CGFireRate=0.05,CGRunChance=0.1,CGRunDamageThreshold=0.15,CGMoveChance=0.1,CGChargeAtNearbyChance=0.5,PseudoSwitchChance=0.0,PseudoSwitchCooldown=3.0,PseudoSwitchDamageThreshold=0.0,RLShots=1,RLFireRate=0.5,ShieldChance=0.0,ShieldDuration=0.0,ShieldCooldown=5.0,ShootObstacleChance=0.1,ShootObstacleMaxDistance=2000,SneakAroundOnHealChance=0.25,SneakAroundCooldown=20.0,TeleportChance=0.0,TeleportCooldown=20.0,TeleportMinDistance=1500,TeleportMinApproachDistance=700,TeleportMaxApproachDistance=1000,ShieldIgnoreDamageRate=0.25,EscapingIgnoreDamageRate=0.7,HealingIgnoreDamageRate=1.0)
    CombatStages(1)=(MinPseudos=0,MaxPseudos=0,KiteChance=0.5,ChargeCooldown=5.0,ForceChargeCooldown=4.0,ForceChargeDamageThreshold=0.1,MaxChargeGroupDistance=450,MaxChargeSingleDistance=750,RadialAttackCirclersChance=0.2,CGShots=100,CGFireRate=0.04,CGRunChance=0.25,CGRunDamageThreshold=0.15,CGMoveChance=0.25,CGChargeAtNearbyChance=0.4,PseudoSwitchChance=0.0,PseudoSwitchCooldown=3.0,PseudoSwitchDamageThreshold=0.0,RLShots=1,RLFireRate=0.4,ShieldChance=0.0,ShieldDuration=0.0,ShieldCooldown=5.0,ShootObstacleChance=0.2,ShootObstacleMaxDistance=2000,SneakAroundOnHealChance=0.35,SneakAroundCooldown=20.0,TeleportChance=0.0,TeleportCooldown=20.0,TeleportMinDistance=1500,TeleportMinApproachDistance=700,TeleportMaxApproachDistance=1000,ShieldIgnoreDamageRate=0.5,EscapingIgnoreDamageRate=0.6,HealingIgnoreDamageRate=1.0)
    CombatStages(2)=(MinPseudos=0,MaxPseudos=0,KiteChance=0.25,ChargeCooldown=5.0,ForceChargeCooldown=3.5,ForceChargeDamageThreshold=0.2,MaxChargeGroupDistance=500,MaxChargeSingleDistance=800,RadialAttackCirclersChance=0.3,CGShots=100,CGFireRate=0.035,CGRunChance=0.4,CGRunDamageThreshold=0.15,CGMoveChance=0.4,CGChargeAtNearbyChance=0.3,PseudoSwitchChance=0.0,PseudoSwitchCooldown=3.0,PseudoSwitchDamageThreshold=0.0,RLShots=2,RLFireRate=0.3,ShieldChance=0.03,ShieldDuration=1.0,ShieldCooldown=5.0,ShootObstacleChance=0.4,ShootObstacleMaxDistance=2000,SneakAroundOnHealChance=0.5,SneakAroundCooldown=17.5,TeleportChance=0.1,TeleportCooldown=20.0,TeleportMinDistance=1500,TeleportMinApproachDistance=700,TeleportMaxApproachDistance=1000,ShieldIgnoreDamageRate=0.75,EscapingIgnoreDamageRate=0.5,HealingIgnoreDamageRate=0.8)
    CombatStages(3)=(MinPseudos=3,MaxPseudos=5,KiteChance=0.1,ChargeCooldown=5.0,ForceChargeCooldown=3.0,ForceChargeDamageThreshold=0.25,MaxChargeGroupDistance=500,MaxChargeSingleDistance=850,RadialAttackCirclersChance=0.5,CGShots=125,CGFireRate=0.03,CGRunChance=0.5,CGRunDamageThreshold=0.15,CGMoveChance=0.5,CGChargeAtNearbyChance=0.2,PseudoSwitchChance=0.5,PseudoSwitchCooldown=3.0,PseudoSwitchDamageThreshold=0.25,RLShots=3,RLFireRate=0.2,ShieldChance=0.05,ShieldDuration=2.0,ShieldCooldown=5.0,ShootObstacleChance=0.5,ShootObstacleMaxDistance=2000,SneakAroundOnHealChance=0.75,SneakAroundCooldown=15.0,TeleportChance=0.15,TeleportCooldown=20.0,TeleportMinDistance=1500,TeleportMinApproachDistance=700,TeleportMaxApproachDistance=1000,ShieldIgnoreDamageRate=1.0,EscapingIgnoreDamageRate=0.4,HealingIgnoreDamageRate=0.7)

    DefaultCombatStages(0)=(MinPseudos=0,MaxPseudos=0,KiteChance=0.75,ChargeCooldown=5.0,ForceChargeCooldown=5.0,ForceChargeDamageThreshold=0.1,MaxChargeGroupDistance=400,MaxChargeSingleDistance=700,RadialAttackCirclersChance=0.1,CGShots=75,CGFireRate=0.05,CGRunChance=0.1,CGRunDamageThreshold=0.15,CGMoveChance=0.1,CGChargeAtNearbyChance=0.5,PseudoSwitchChance=0.0,PseudoSwitchCooldown=3.0,PseudoSwitchDamageThreshold=0.0,RLShots=1,RLFireRate=0.5,ShieldChance=0.0,ShieldDuration=0.0,ShieldCooldown=5.0,ShootObstacleChance=0.1,ShootObstacleMaxDistance=2000,SneakAroundOnHealChance=0.25,SneakAroundCooldown=20.0,TeleportChance=0.0,TeleportCooldown=20.0,TeleportMinDistance=1500,TeleportMinApproachDistance=700,TeleportMaxApproachDistance=1000,ShieldIgnoreDamageRate=0.25,EscapingIgnoreDamageRate=0.7,HealingIgnoreDamageRate=1.0)
    DefaultCombatStages(1)=(MinPseudos=0,MaxPseudos=0,KiteChance=0.5,ChargeCooldown=5.0,ForceChargeCooldown=4.0,ForceChargeDamageThreshold=0.1,MaxChargeGroupDistance=450,MaxChargeSingleDistance=750,RadialAttackCirclersChance=0.2,CGShots=100,CGFireRate=0.04,CGRunChance=0.25,CGRunDamageThreshold=0.15,CGMoveChance=0.25,CGChargeAtNearbyChance=0.4,PseudoSwitchChance=0.0,PseudoSwitchCooldown=3.0,PseudoSwitchDamageThreshold=0.0,RLShots=1,RLFireRate=0.4,ShieldChance=0.0,ShieldDuration=0.0,ShieldCooldown=5.0,ShootObstacleChance=0.2,ShootObstacleMaxDistance=2000,SneakAroundOnHealChance=0.35,SneakAroundCooldown=20.0,TeleportChance=0.0,TeleportCooldown=20.0,TeleportMinDistance=1500,TeleportMinApproachDistance=700,TeleportMaxApproachDistance=1000,ShieldIgnoreDamageRate=0.5,EscapingIgnoreDamageRate=0.6,HealingIgnoreDamageRate=1.0)
    DefaultCombatStages(2)=(MinPseudos=0,MaxPseudos=0,KiteChance=0.25,ChargeCooldown=5.0,ForceChargeCooldown=3.5,ForceChargeDamageThreshold=0.2,MaxChargeGroupDistance=500,MaxChargeSingleDistance=800,RadialAttackCirclersChance=0.3,CGShots=100,CGFireRate=0.035,CGRunChance=0.4,CGRunDamageThreshold=0.15,CGMoveChance=0.4,CGChargeAtNearbyChance=0.3,PseudoSwitchChance=0.0,PseudoSwitchCooldown=3.0,PseudoSwitchDamageThreshold=0.0,RLShots=2,RLFireRate=0.3,ShieldChance=0.03,ShieldDuration=1.0,ShieldCooldown=5.0,ShootObstacleChance=0.4,ShootObstacleMaxDistance=2000,SneakAroundOnHealChance=0.5,SneakAroundCooldown=17.5,TeleportChance=0.1,TeleportCooldown=20.0,TeleportMinDistance=1500,TeleportMinApproachDistance=700,TeleportMaxApproachDistance=1000,ShieldIgnoreDamageRate=0.75,EscapingIgnoreDamageRate=0.5,HealingIgnoreDamageRate=0.8)
    DefaultCombatStages(3)=(MinPseudos=3,MaxPseudos=5,KiteChance=0.1,ChargeCooldown=5.0,ForceChargeCooldown=3.0,ForceChargeDamageThreshold=0.25,MaxChargeGroupDistance=500,MaxChargeSingleDistance=850,RadialAttackCirclersChance=0.5,CGShots=125,CGFireRate=0.03,CGRunChance=0.5,CGRunDamageThreshold=0.15,CGMoveChance=0.5,CGChargeAtNearbyChance=0.2,PseudoSwitchChance=0.5,PseudoSwitchCooldown=3.0,PseudoSwitchDamageThreshold=0.25,RLShots=3,RLFireRate=0.2,ShieldChance=0.05,ShieldDuration=2.0,ShieldCooldown=5.0,ShootObstacleChance=0.5,ShootObstacleMaxDistance=2000,SneakAroundOnHealChance=0.75,SneakAroundCooldown=15.0,TeleportChance=0.15,TeleportCooldown=20.0,TeleportMinDistance=1500,TeleportMinApproachDistance=700,TeleportMaxApproachDistance=1000,ShieldIgnoreDamageRate=1.0,EscapingIgnoreDamageRate=0.4,HealingIgnoreDamageRate=0.7)

    PatHealth=4000
    CGDamage=5.000000
    ClawMeleeDamageRange=75
    ImpaleMeleeDamageRange=90.000000
    bPseudo=False

    ControllerClass=class'N7_BossController'
    PseudoClass=class'N7_PseudoBoss'
    LAWProjClass=class'N7_BossLAWProj'

    Skins(2)=Shader'KF_Specimens_Trip_T.patriarch_invisible_gun'
    Skins(3)=Shader'KF_Specimens_Trip_T.patriarch_invisible'
}
