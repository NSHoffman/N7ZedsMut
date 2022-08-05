class N7_Boss extends KFChar.ZombieBoss_STANDARD;

/**
 * @param bCanKite          - Whether players are allowed to exploit kiting 
 * @param bSpawnProjections = Whether patriarch's pseudos should be spawned after healing
 * @param CGShots           - Fixed number of chaingun shots
 * @param CGFireRate        - Chaingun velocity
 * @param RLShots           - Fixed number of rockets to be shot
 * @param RLFireRate        - Rocket Launcher velocity
 */
struct CombatStage
{
    var bool bCanKite, bSpawnProjections;
    var byte CGShots, RLShots;
    var float CGFireRate, RLFireRate;
};

var CombatStage CombatStages[4];

var byte MissileShotsLeft;

/**
 * Each patriarch has a chance to spawn
 * a squad of pseudos, projections
 * that get killed if the host is dead
 */
var Class<N7_Boss> PseudoClass;
var Array<N7_Boss> PseudoSquad;

var int MinPseudoSquadSize;
var int MaxPseudoSquadSize;

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

    // 50% that Patriarch will use alternate claw animation
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

    // Invisible - no shadow
    if (PlayerShadow != None)
    {
        PlayerShadow.bShadowActive = false;
    }

    // Remove/disallow projectors on invisible people
    Projectors.Remove(0, Projectors.Length);
    bAcceptsProjectors = false;

    // Randomly send out a message about Patriarch going invisible(10% chance)
    if (FRand() < 0.10)
    {
        // Pick a random Player to say the message
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
    // Charge distance increased + charge cooldown decreased
    else if (
        !bDesireChainGun && !bChargingPlayer &&
        (D < 700 || (D < 1500 && bOnlyE)) &&
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

        // Missile cooldown shortened
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

        // Chaingun cooldown shortened
        LastChainGunTime = Level.TimeSeconds + 4 + FRand() * 6;

        bShotAnim = true;
        Acceleration = vect(0, 0, 0);
        SetAnimAction('PreFireMG');

        HandleWaitForAnim('PreFireMG');
        // More shots per chaingun attack
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
        HandleWaitForAnim('MeleeImpale');
        SetAnimAction('MeleeImpale');
    }
}

function TakeDamage(
    int Damage, 
    Pawn InstigatedBy, 
    Vector Hitlocation, 
    Vector Momentum, 
    Class<DamageType> DamageType, 
    optional int HitIndex)
{
    // Ignore damage instigated by other ZEDs 
    if (KFMonster(InstigatedBy) == None)
    {
        Super.TakeDamage(Damage, InstigatedBy, Hitlocation, Momentum, DamageType, HitIndex);
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
    bChargeFromKite = !CombatStages[SyringeCount].bCanKite && FRand() > 0.15;

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
    local int PseudoSquadSize, i;
    local N7_Boss CurrentPseudoBoss;

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

/** After healing patriarch might want to avenge damagers */
function ChargeTargetAfterHealing()
{
    local Controller C;
    local Pawn NextChargeTarget;
    local bool bWantsToAvenge, bChooseWeakest, bWeakerTarget;

    bWantsToAvenge = KFHumanPawn(LastDamagedBy) != None && KFHumanPawn(LastDamagedBy).Health > 0 && FRand() < 0.6;
    bChooseWeakest = FRand() < 0.5;

    if (bWantsToAvenge)
    {
        NextChargeTarget = LastDamagedBy;
    }
    else if (bChooseWeakest)
    {
        for (C = Level.ControllerList; C != None; C = C.NextController)
        { 
            if (C.IsA('PlayerController') || C.IsA('xBot'))
            {
                bWeakerTarget = 
                    (NextChargeTarget == None && C.Pawn.Health > 0) || 
                    (NextChargeTarget != None && C.Pawn.Health > 0 && C.Pawn.Health <= NextChargeTarget.Health);

                if (bWeakerTarget)
                {
                    NextChargeTarget = C.Pawn;
                }
            } 
        }
    }

    if (NextChargeTarget != None)
    {
        Controller.Target = NextChargeTarget;
        Controller.Enemy = NextChargeTarget;

        GoToState('Charging');
    }
    else 
    {
        GoToState('');
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
        CurrentNeedle = Spawn(Class'BossHPNeedle');

        if (CurrentNeedle != None)
        {
            AttachToBone(CurrentNeedle,'Rpalm_MedAttachment');
            CurrentNeedle.Velocity = vect(-45,300,-90) >> Rotation;
            DropNeedle();
        }
	}

    if (CombatStages[SyringeCount].bSpawnProjections)
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

/** God mode + invisibility when escaping */
state Escaping
{
ignores RangedAttack;

    function BeginState()
    {
        Super.BeginState();
        bBlockActors = false;
        bIgnoreEncroachers = true;
        MotionDetectorThreat = 0;
    }

    function EndState()
    {
        Super.EndState();
        bIgnoreEncroachers = false;
        bBlockActors = true;
        MotionDetectorThreat = default.MotionDetectorThreat;
    }

    function TakeDamage(
        int Damage, 
        Pawn InstigatedBy, 
        Vector Hitlocation, 
        Vector Momentum, 
        Class<DamageType> DamageType, 
        optional int HitIndex)
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
ignores RangedAttack;

    function BeginState()
    {
        Super.BeginState();
        bBlockActors = false;
        bIgnoreEncroachers = true;
        MotionDetectorThreat = 0;
        
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
        int Damage, 
        Pawn InstigatedBy, 
        Vector Hitlocation, 
        Vector Momentum, 
        Class<DamageType> DamageType, 
        optional int HitIndex)
    {
        // Only Commando can damage Patriarch in invisible state
        if (KFHumanPawn(InstigatedBy) != None && KFHumanPawn(InstigatedBy).ShowStalkers())
        {
            Super.TakeDamage(Damage, InstigatedBy, Hitlocation, Momentum, DamageType, HitIndex);
        }
    }
Begin:
	Sleep(GetAnimDuration('Heal'));

	ChargeTargetAfterHealing();
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

    function AnimEnd(int Channel)
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
                return;

            if (Controller.Target != None)
                Controller.Focus = Controller.Target;

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

        if (bFireAtWill)
        {
            FireMGShot();
        }
        Sleep(CombatStages[SyringeCount].CGFireRate);
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
        Acceleration = vect(0,0,0);
    }

    function EndState()
    {
        MissileShotsLeft = 0;
    }

    function AnimEnd(int Channel)
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

        // Randomly send out a message about Patriarch shooting a rocket(5% chance)
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
        Sleep(0.1);
    }
NextShot:
    Acceleration = vect(0, 0, 0);
    Sleep(CombatStages[SyringeCount].RLFireRate);
    AnimEnd(0);
}

defaultproperties 
{
    MenuName="N7 Patriarch"
    CombatStages(0)=(bCanKite=true,bSpawnProjections=false,CGShots=75,RLShots=1,CGFireRate=0.05,RLFireRate=0.75)
    CombatStages(1)=(bCanKite=false,bSpawnProjections=false,CGShots=100,RLShots=1,CGFireRate=0.04,RLFireRate=0.75)
    CombatStages(2)=(bCanKite=false,bSpawnProjections=false,CGShots=100,RLShots=2,CGFireRate=0.035,RLFireRate=0.5)
    CombatStages(3)=(bCanKite=false,bSpawnProjections=true,CGShots=125,RLShots=3,CGFireRate=0.03,RLFireRate=0.25)
    ClawMeleeDamageRange=75 // Claw damage range seemed a little too much
    ImpaleMeleeDamageRange=100.000000 // Impale attack had way too little damage range (45)
    ZappedDamageMod=1.00
    ZapResistanceScale=2.0
    ZappedSpeedMod=0.8
    MinPseudoSquadSize=2
    MaxPseudoSquadSize=5
    PseudoClass=Class'N7ZedsMut.N7_PseudoBoss'
    DetachedArmClass=Class'N7ZedsMut.N7_SeveredArmPatriarch'
    DetachedLegClass=Class'N7ZedsMut.N7_SeveredLegPatriarch'
    DetachedHeadClass=Class'N7ZedsMut.N7_SeveredHeadPatriarch'
    DetachedSpecialArmClass=Class'N7ZedsMut.N7_SeveredRocketArmPatriarch'
    Skins(0)=Combiner'KF_Specimens_Trip_N7.gatling_cmb'
    Skins(1)=Combiner'KF_Specimens_Trip_N7.patriarch_cmb'
}
