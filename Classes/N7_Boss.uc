class N7_Boss extends KFChar.ZombieBoss_STANDARD
    config(N7ZedsMut);

struct CombatStage
{
    var config bool
        // Whether players are allowed to exploit kiting
        bCanKite,

        // Whether patriarch's pseudos should be spawned after healing
        bSpawnPseudos,

        // Whether patriarch can use shield to avoid damage
        bUseShield,

        // Whether patriarch can teleport closer to players
        bUseTeleport;

    var config int
        // Fixed number of chaingun shots
        CGShots,

        // Fixed number of rockets to be shot
        RLShots,

        // Limits of pseudos to be spawned
        MinPseudos,
        MaxPseudos;

    var config float
        // Chance of kiting when bCanKite is False
        KiteChance,

        // Chaingun velocity
        CGFireRate,

        // Rocket Launcher velocity
        RLFireRate,

        // Chance patriarch's shield gets activated
        ShieldChance,

        ShieldDuration,

        // Chance patriarch will teleport to players
        TeleportChance;
};

var config CombatStage CombatStages[4];

var int MissileShotsLeft;

var int MinChargeDistance;
var int MaxChargeDistance;
var int TeleportDistance;

var int DamageToChargeThreshold;
var int DamageToCharge;

var float LastShieldTime;
var float LastTeleportTime;
var float LastDamagedTime;

/**
 * Each patriarch has a chance to spawn
 * a squad of pseudos, projections
 * that get killed if the host is dead
 */
var class<N7_Boss> PseudoClass;
var array<N7_Boss> PseudoSquad;

var bool bMovingChaingunAttack;

replication
{
    reliable if (ROLE == ROLE_AUTHORITY)
        bMovingChaingunAttack;
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

    if (FRand() < 0.10)
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

    else if (Level.TimeSeconds - LastSneakedTime > 20.0)
    {
        if (FRand() < 0.3)
        {
            LastSneakedTime = Level.TimeSeconds;
            return;
        }
        SetAnimAction('transition');
        GoToState('SneakAround');
    }

    else if (
       !bDesireChainGun && D > TeleportDistance &&
       CombatStages[SyringeCount].bUseTeleport && FRand() <= CombatStages[SyringeCount].TeleportChance &&
       Level.TimeSeconds - LastTeleportTime > 20.0)
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
        (D < MinChargeDistance || (D < MaxChargeDistance && bOnlyE)) &&
        (Level.TimeSeconds - LastChargeTime > (3.5 + 3.0 * FRand())))
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

        MGFireCounter =  CombatStages[SyringeCount].CGShots + Rand(100);

        GoToState('FireChaingun');
    }
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
    return !bChargingPlayer
        && (SyringeCount == 3 || Health >= HealingLevels[SyringeCount])
        && DamageToCharge > DamageToChargeThreshold;
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
    local float DamagerDistSq, UsedPipeBombDamScale;
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

        OldHealth = Health;
        super(KFMonster).TakeDamage(Damage, InstigatedBy, Hitlocation, Momentum, DamageType);

        if (Health <= 0 ||
            IsInState('Escaping') && !IsInState('SneakAround') ||
            IsInState('KnockDown') ||
            IsInState('RadialAttack') ||
            bDidRadialAttack)
        {
            return;
        }

        // Charging from damage (implementation in ZombieBoss::TakeDamage doesn't work properly)
        if (LastDamagedTime > 0 && Level.TimeSeconds - LastDamagedTime > 10.0)
        {
            DamageToCharge = 0;
        }

        DamageToCharge += OldHealth - Health;
        LastDamagedTime = Level.TimeSeconds;

        if (InstigatedBy != None && ShouldChargeFromDamage())
        {
            DamagerDistSq = VSizeSquared(Location - InstigatedBy.Location);

            if (DamagerDistSq < (MaxChargeDistance * MaxChargeDistance))
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
        if (CombatStages[SyringeCount].bUseShield
            && Level.TimeSeconds - LastShieldTime > 5.0
            && FRand() <= CombatStages[SyringeCount].ShieldChance)
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
     * There's still a little chance to avoid charging
     */
    bChargeFromKite = !CombatStages[SyringeCount].bCanKite && FRand() > CombatStages[SyringeCount].KiteChance;

    if (bDamagedSomeone)
    {
        if (Anim == 'MeleeImpale')
        {
            PlaySound(MeleeImpaleHitSound, SLOT_Interact, 2.0);
        }
        else
        {
            PlaySound(MeleeAttackHitSound, SLOT_Interact, 2.0);
        }
    }
    else if (Controller != None && Controller.Target != None && !IsInState('Escaping') && bChargeFromKite)
    {
        GoToState('Charging');
    }
}

function SpawnPseudoSquad()
{
    local int PseudoSquadSize, MinPseudoSquadSize, MaxPseudoSquadSize, i;
    local N7_Boss CurrentPseudoBoss;

    MinPseudoSquadSize = CombatStages[SyringeCount].MinPseudos;
    MaxPseudoSquadSize = CombatStages[SyringeCount].MaxPseudos;

    if (MaxPseudoSquadSize <= 0 || MaxPseudoSquadSize < MinPseudoSquadSize)
    {
        return;
    }

    PseudoSquadSize = MinPseudoSquadSize + Rand(MaxPseudoSquadSize - MinPseudoSquadSize + 1);

    for (i = 0; i < PseudoSquadSize; i++)
    {
        CurrentPseudoBoss = Spawn(PseudoClass);

        if (CurrentPseudoBoss != None)
        {
            PseudoSquad[i] = CurrentPseudoBoss;
        }
    }
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

    if (CombatStages[SyringeCount].bSpawnPseudos)
    {
        SpawnPseudoSquad();
    }
}

simulated function PlayDying(class<DamageType> DamageType, Vector HitLoc)
{
    super.PlayDying(DamageType, HitLoc);

    KillPseudoSquad();

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
 * Incoming damage is ignored in this state unless the player is commando
 */
state Shield
{
ignores StartBurnFX, StopBurnFX;

    function TakeDamage(
        int Damage, Pawn InstigatedBy, Vector Hitlocation, Vector Momentum, class<DamageType> DamageType, optional int HitIndex)
    {
        // Only Commando can damage Patriarch in shield state
        if (KFHumanPawn(InstigatedBy) != None && KFHumanPawn(InstigatedBy).ShowStalkers())
        {
            super.TakeDamage(Damage, InstigatedBy, Hitlocation, Momentum, DamageType, HitIndex);
        }
    }

Begin:
    SetOverlayMaterial(Finalblend'KFX.StalkerGlow', CombatStages[SyringeCount].ShieldDuration, True);
    Sleep(CombatStages[SyringeCount].ShieldDuration);

    GoToState('');
}

/** Teleport when patriarch is far enough from players */
state Teleport
{
ignores RangedAttack, StartBurnFX, StopBurnFX;

    function TeleportToPlayers()
    {
        if (Controller.Enemy == None && !MonsterController(Controller).FindNewEnemy())
        {
            return;
        }

        Controller.Enemy.LastAnchor.Accept(self, self.Anchor);
        MonsterController(Controller).ExecuteWhatToDoNext();
    }

Begin:
    SetOverlayMaterial(Finalblend'KFX.StalkerGlow', 1.0, True);
    TeleportToPlayers();

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
        if (VSize(A.Location - Location) > MaxChargeDistance && Level.TimeSeconds - LastForceChargeTime > 3.0)
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

/** God mode + invisibility when escaping */
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
        // Only Commando can damage Patriarch in invisible state
        if (KFHumanPawn(InstigatedBy) != None && KFHumanPawn(InstigatedBy).ShowStalkers())
        {
            super.TakeDamage(Damage, InstigatedBy, Hitlocation, Momentum, DamageType, HitIndex);
        }
    }
}

/** God mode + invisibility when healing */
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
        // Only Commando can damage Patriarch in invisible state
        if (KFHumanPawn(InstigatedBy) != None && KFHumanPawn(InstigatedBy).ShowStalkers())
        {
            super.TakeDamage(Damage, InstigatedBy, Hitlocation, Momentum, DamageType, HitIndex);
        }
    }

Begin:
    Sleep(GetAnimDuration('Heal'));
    GoToState('');
}

/**
 * Constant chaingun fire + fire rate increased
 * Patriarch is moving during attack
 */
state FireChaingun
{
    function BeginState()
    {
        super.BeginState();
        bMovingChaingunAttack = True;
        bChargingPlayer = True;
        bCanStrafe = True;
    }

    function EndState()
    {
        bMovingChaingunAttack = False;
        bChargingPlayer = False;
        bCanStrafe = False;
        super.EndState();
    }

    function Tick(float Delta)
    {
        super(KFMonster).Tick(Delta);

        if (bChargingPlayer)
        {
            SetGroundSpeed(GetOriginalGroundSpeed() * 1.5);
        }
        else
        {
            SetGroundSpeed(GetOriginalGroundSpeed());
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
            {
                return;
            }

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

            bShotAnim = False;
            bFireAtWill = True;
            SetAnimAction('FireMG');
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
            if (bFireAtWill)
            {
                FireMGShot();
            }

            Sleep(CombatStages[SyringeCount].CGFireRate);
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
        MissileShotsLeft = CombatStages[SyringeCount].RLShots + Rand(3);
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
            SavedFireProperties.ProjectileClass = class'N7_BossLAWProj';
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
        Spawn(class'N7_BossLAWProj',,, Start, R);

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
    Sleep(CombatStages[SyringeCount].RLFireRate);
    AnimEnd(0);
}

/** No zapped behaviour */
function SetZapped(float ZapAmount, Pawn Instigator) {}

simulated function SetZappedBehavior() {}
simulated function UnSetZappedBehavior() {}

/** No crisping up */
simulated function ZombieCrispUp() {}

defaultProperties
{
    MenuName="N7 Patriarch"

    CombatStages(0)=(bCanKite=True,KiteChance=1.0,bSpawnPseudos=False,MinPseudos=0,MaxPseudos=0,CGShots=75,RLShots=1,CGFireRate=0.05,RLFireRate=0.5,bUseShield=False,ShieldChance=0.0,ShieldDuration=0.0,bUseTeleport=False,TeleportChance=0.0)
    CombatStages(1)=(bCanKite=False,KiteChance=0.35,bSpawnPseudos=False,MinPseudos=0,MaxPseudos=0,CGShots=100,RLShots=1,CGFireRate=0.04,RLFireRate=0.4,bUseShield=False,ShieldChance=0.0,ShieldDuration=0.0,bUseTeleport=False,TeleportChance=0.0)
    CombatStages(2)=(bCanKite=False,KiteChance=0.2,bSpawnPseudos=False,MinPseudos=0,MaxPseudos=0,CGShots=100,RLShots=2,CGFireRate=0.035,RLFireRate=0.3,bUseShield=True,ShieldChance=0.05,ShieldDuration=1.0,bUseTeleport=True,TeleportChance=0.1)
    CombatStages(3)=(bCanKite=False,KiteChance=0.1,bSpawnPseudos=True,MinPseudos=3,MaxPseudos=5,CGShots=125,RLShots=3,CGFireRate=0.03,RLFireRate=0.2,bUseShield=True,ShieldChance=0.05,ShieldDuration=2.0,bUseTeleport=True,TeleportChance=0.15)

    Health=5000
    HealthMax=5000.000000
    MinChargeDistance=500
    MaxChargeDistance=1000
    TeleportDistance=1250
    DamageToChargeThreshold=1000
    ClawMeleeDamageRange=75
    ImpaleMeleeDamageRange=90.000000
    PseudoClass=class'N7_PseudoBoss'

    Skins(2)=Shader'KF_Specimens_Trip_T.patriarch_invisible_gun'
    Skins(3)=Shader'KF_Specimens_Trip_T.patriarch_invisible'
}
