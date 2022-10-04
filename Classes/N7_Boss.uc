class N7_Boss extends KFChar.ZombieBoss_STANDARD
    config(N7ZedsMut);

struct CombatStage
{
    var bool
        // Whether players are allowed to exploit kiting
        bCanKite,

        // Whether patriarch's pseudos should be spawned after healing
        bSpawnPseudos,

        // Whether patriarch can use shield to avoid damage
        bUseShield,

        // Whether patriarch can teleport closer to players
        bUseTeleport;

    var int
        // Fixed number of chaingun shots
        CGShots,

        // Fixed number of rockets to be shot
        RLShots,

        // Limits of pseudos to be spawned
        MinPseudos,
        MaxPseudos;

    var float
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
var Class<N7_Boss> PseudoClass;
var Array<N7_Boss> PseudoSquad;

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
        bWaitForAnim = true;
    }
    else
    {
        bWaitForAnim = false;
    }

    if (Level.NetMode != NM_Client)
    {
        AnimAction = NewAction;
        bResetAnimAct = true;
        ResetAnimActTime = Level.TimeSeconds + 0.3;
    }
}

simulated function bool AnimNeedsWait(name TestAnim)
{
    if (TestAnim == 'FireMG')
    {
        return !bMovingChaingunAttack;
    }

    return Super.AnimNeedsWait(TestAnim);
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
        AnimBlendParams(1, 1.0, 0.0,, FireRootBone, true);
        PlayAnim(AnimName,, 0.f, 1);

        return 1;
    }
    else if (AnimName == 'FireEndMG')
    {
        AnimBlendParams(1, 0);
    }

    return Super(KFMonster).DoAnimAction(AnimName);
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
            Super(KFMonster).AnimEnd(Channel);
            return;
        }

        if (bMovingChaingunAttack) {
            DoAnimAction('FireMG');
        }
    }
    else
    {
        Super(KFMonster).AnimEnd(Channel);
    }
}

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
        bUnlit = true;
        return;
    }

    Visibility = 0;
    bCloaked = true;
    if (Level.NetMode != NM_Client)
    {
        for (C = Level.ControllerList; C != None; C = C.NextController)
        {
            if (C.bIsPlayer && C.Enemy == Self)
            {
                C.Enemy = None;
            }
        }
    }

    if (Level.NetMode == NM_DedicatedServer)
    {
        return;
    }

    Skins[0] = Shader'KF_Specimens_Trip_N7.patriarch_invisible_gun';
    Skins[1] = Shader'KF_Specimens_Trip_N7.patriarch_invisible';

    if (PlayerShadow != None)
    {
        PlayerShadow.bShadowActive = false;
    }
    Projectors.Remove(0, Projectors.Length);
    bAcceptsProjectors = false;

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

simulated function ZombieCrispDown()
{
    bAshen = false;
    bCrispified = false;

    UnSetBurningBehavior();

    if (Level.NetMode == NM_DedicatedServer)
    {
        return;
    }

    Skins[0] = default.Skins[0];
    Skins[1] = default.Skins[1];
}

function RangedAttack(Actor A)
{
    local float D;
    local bool bOnlyE, bDesireChainGun;

    if (Controller.LineOfSightTo(A) && FRand() < 0.15 && LastChainGunTime < Level.TimeSeconds)
    {
        bDesireChainGun = true;
    }

    if (bShotAnim)
    {
        return;
    }

    D = VSize(A.Location-Location);
    bOnlyE = (Pawn(A) != None && OnlyEnemyAround(Pawn(A)));

    if (IsCloseEnuf(A))
    {
        bShotAnim = true;

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

    else if (bChargingPlayer && (bOnlyE || D < 200))
    {
        return;
    }

    else if (
       !bDesireChainGun && !bChargingPlayer && D > 1750 &&
       CombatStages[SyringeCount].bUseTeleport && FRand() <= CombatStages[SyringeCount].TeleportChance &&
       Level.TimeSeconds - LastTeleportTime > 20.0)
    {
        LastTeleportTime = Level.TimeSeconds;
        GoToState('Teleport');
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

        bShotAnim = true;
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

        bShotAnim = true;
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
        bShotAnim = true;
        Acceleration = vect(0, 0, 0);

        // Melee attack is used to break doors
        SetAnimAction('MeleeImpale');
        HandleWaitForAnim('MeleeImpale');
    }
}

function bool ShouldChargeFromDamage()
{
    return !bChargingPlayer 
        && Health > HealingLevels[SyringeCount] 
        && DamageToCharge > DamageToChargeThreshold;
}

function TakeDamage(
    int Damage, Pawn InstigatedBy, Vector Hitlocation, Vector Momentum, Class<DamageType> DamageType, optional int HitIndex)
{
    local int OldHealth;
    local float DamagerDistSq;

    // Ignore damage instigated by other ZEDs
    if (KFMonster(InstigatedBy) == None)
    {
        OldHealth = Health;
        Super.TakeDamage(Damage, InstigatedBy, Hitlocation, Momentum, DamageType, HitIndex);

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
    else
    {
        OldTarget = Controller.Target;
        foreach DynamicActors(Class'KFHumanPawn', P)
        {
            if ((P.Location - Location) dot PushDir > 0.0)
            {
                Controller.Target = P;
                bDamagedSomeone = bDamagedSomeone || MeleeDamageTarget(UsedMeleeDamage, damageForce * Normal(P.Location - Location));
            }
        }
        Controller.Target = OldTarget;
    }

    MeleeRange = Default.MeleeRange;

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
        CurrentNeedle = Spawn(Class'BossHPNeedle');

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

simulated function PlayDying(Class<DamageType> DamageType, Vector HitLoc)
{
    Super.PlayDying(DamageType, HitLoc);

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
ignores ZombieCrispUp, SetBurningBehavior, UnSetBurningBehavior, StartBurnFX, StopBurnFX;

    function BeginState()
    {
        ZombieCrispDown();
    }

    function TakeDamage(
        int Damage, Pawn InstigatedBy, Vector Hitlocation, Vector Momentum, Class<DamageType> DamageType, optional int HitIndex)
    {
        // Only Commando can damage Patriarch in shield state
        if (KFHumanPawn(InstigatedBy) != None && KFHumanPawn(InstigatedBy).ShowStalkers())
        {
            Super.TakeDamage(Damage, InstigatedBy, Hitlocation, Momentum, DamageType, HitIndex);
        }
    }

Begin:
    SetOverlayMaterial(Finalblend'KFX.StalkerGlow', CombatStages[SyringeCount].ShieldDuration, true);
    Sleep(CombatStages[SyringeCount].ShieldDuration);

    GoToState('');
}

/** Teleport when patriarch is far enough from players */
state Teleport
{
ignores RangedAttack, ZombieCrispUp, SetBurningBehavior, UnSetBurningBehavior, StartBurnFX, StopBurnFX;

    function BeginState()
    {
        ZombieCrispDown();
    }

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
    SetOverlayMaterial(Finalblend'KFX.StalkerGlow', 1.0, true);
    TeleportToPlayers();

    GoToState('');
}

/** Charge distance increased */
state Charging
{
    function RangedAttack(Actor A)
	{
        if (VSize(A.Location - Location) > MaxChargeDistance && Level.TimeSeconds - LastForceChargeTime > 3.0)
        {
            GoToState('');
        }
        else
        {
            Global.RangedAttack(A);
        }
	}

Begin:
	Sleep(6);
	GoToState('');
}

/** God mode + invisibility when escaping */
state Escaping
{
ignores RangedAttack, ZombieCrispUp, SetBurningBehavior, UnSetBurningBehavior, StartBurnFX, StopBurnFX;

    function BeginState()
    {
        Super.BeginState();
        bBlockActors = false;
        bIgnoreEncroachers = true;
        MotionDetectorThreat = 0;

        ZombieCrispDown();
    }

    function EndState()
    {
        Super.EndState();
        bIgnoreEncroachers = false;
        bBlockActors = true;
        MotionDetectorThreat = default.MotionDetectorThreat;
    }

    function TakeDamage(
        int Damage, Pawn InstigatedBy, Vector Hitlocation, Vector Momentum, Class<DamageType> DamageType, optional int HitIndex)
    {
        // Only Commando can damage Patriarch in invisible state
        if (KFHumanPawn(InstigatedBy) != None && KFHumanPawn(InstigatedBy).ShowStalkers())
        {
            Super.TakeDamage(Damage, InstigatedBy, Hitlocation, Momentum, DamageType, HitIndex);
        }
    }
}

/** God mode + invisibility when healing */
state Healing
{
ignores RangedAttack, ZombieCrispUp, SetBurningBehavior, UnSetBurningBehavior, StartBurnFX, StopBurnFX;

    function BeginState()
    {
        Super.BeginState();
        bBlockActors = false;
        bIgnoreEncroachers = true;
        MotionDetectorThreat = 0;

        ZombieCrispDown();

        if (!bCloaked)
        {
            CloakBoss();
        }
    }

    function EndState()
    {
        Super.EndState();
        bIgnoreEncroachers = false;
        bBlockActors = true;
        MotionDetectorThreat = default.MotionDetectorThreat;

        if (bCloaked)
        {
            UnCloakBoss();
        }
    }

    function TakeDamage(
        int Damage, Pawn InstigatedBy, Vector Hitlocation, Vector Momentum, Class<DamageType> DamageType, optional int HitIndex)
    {
        // Only Commando can damage Patriarch in invisible state
        if (KFHumanPawn(InstigatedBy) != None && KFHumanPawn(InstigatedBy).ShowStalkers())
        {
            Super.TakeDamage(Damage, InstigatedBy, Hitlocation, Momentum, DamageType, HitIndex);
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
        Super.BeginState();
        bMovingChaingunAttack = true;
        bChargingPlayer = true;
        bCanStrafe = true;
    }

    function EndState()
    {
        bMovingChaingunAttack = false;
        bChargingPlayer = false;
        bCanStrafe = false;
        Super.EndState();
    }

    function Tick(float Delta)
    {
        Super(KFMonster).Tick(Delta);

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
            bShotAnim = true;
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

            bShotAnim = false;
            bFireAtWill = true;
            SetAnimAction('FireMG');
        }
    }

Begin:
    while (true)
    {
        if (!bMovingChaingunAttack)
        {
            Acceleration = vect(0, 0, 0);
        }

        if (MGFireCounter <= 0 || (MGLostSightTimeout > 0 && Level.TimeSeconds > MGLostSightTimeout))
        {
            bShotAnim = true;
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
            SavedFireProperties.AmmoClass = Class'SkaarjAmmo';
            SavedFireProperties.ProjectileClass = Class'N7_BossLAWProj';
            SavedFireProperties.WarnTargetPct = 0.15;
            SavedFireProperties.MaxRange = 10000;
            SavedFireProperties.bTossed = false;
            SavedFireProperties.bLeadTarget = true;
            SavedFireProperties.bInitialized = true;
        }
        SavedFireProperties.bInstantHit = (SyringeCount < 1);
        SavedFireProperties.bTrySplash = (SyringeCount >= 2);

        R = AdjustAim(SavedFireProperties, Start, 100);
        PlaySound(RocketFireSound, SLOT_Interact, 2.0,, TransientSoundRadius,, false);
        Spawn(Class'N7_BossLAWProj',,, Start, R);

        bShotAnim = true;
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

Begin:
    while (true)
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

defaultproperties
{
    MenuName="N7 Patriarch"

    CombatStages(0)=(bCanKite=true,KiteChance=1.0,bSpawnPseudos=false,MinPseudos=0,MaxPseudos=0,CGShots=75,RLShots=1,CGFireRate=0.05,RLFireRate=0.5,bUseShield=false,ShieldChance=0.0,ShieldDuration=0.0,bUseTeleport=false,TeleportChance=0.0)
    CombatStages(1)=(bCanKite=false,KiteChance=0.35,bSpawnPseudos=false,MinPseudos=0,MaxPseudos=0,CGShots=100,RLShots=1,CGFireRate=0.04,RLFireRate=0.4,bUseShield=false,ShieldChance=0.0,ShieldDuration=0.0,bUseTeleport=false,TeleportChance=0.0)
    CombatStages(2)=(bCanKite=false,KiteChance=0.2,bSpawnPseudos=false,MinPseudos=0,MaxPseudos=0,CGShots=100,RLShots=2,CGFireRate=0.035,RLFireRate=0.3,bUseShield=true,ShieldChance=0.05,ShieldDuration=1.0,bUseTeleport=false,TeleportChance=0.0)
    CombatStages(3)=(bCanKite=false,KiteChance=0.1,bSpawnPseudos=true,MinPseudos=3,MaxPseudos=5,CGShots=125,RLShots=3,CGFireRate=0.03,RLFireRate=0.2,bUseShield=true,ShieldChance=0.05,ShieldDuration=2.0,bUseTeleport=true,TeleportChance=0.1)

    MinChargeDistance=700
    MaxChargeDistance=1250
    DamageToChargeThreshold=1000
    ClawMeleeDamageRange=75
    ImpaleMeleeDamageRange=90.000000
    PseudoClass=Class'N7ZedsMut.N7_PseudoBoss'
    DetachedArmClass=Class'N7ZedsMut.N7_SeveredArmPatriarch'
    DetachedLegClass=Class'N7ZedsMut.N7_SeveredLegPatriarch'
    DetachedHeadClass=Class'N7ZedsMut.N7_SeveredHeadPatriarch'
    DetachedSpecialArmClass=Class'N7ZedsMut.N7_SeveredRocketArmPatriarch'
    Skins(0)=Combiner'KF_Specimens_Trip_N7.gatling_cmb'
    Skins(1)=Combiner'KF_Specimens_Trip_N7.patriarch_cmb'
}
