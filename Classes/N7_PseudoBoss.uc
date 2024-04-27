class N7_PseudoBoss extends N7_Boss;

var const float AdjustedHealthModifier;
var const float AdjustedHeadHealthModifier;

var DamageInfo EvasionDamage;

var bool bAboutToDie;

var float LastEvadeTime;

replication {
    reliable if (Role == ROLE_AUTHORITY)
        bAboutToDie;
}

simulated function PostBeginPlay()
{
    super.PostBeginPlay();

    Health = default.Health;
    HealthMax = default.HealthMax;
    HeadHealth = default.HeadHealth;

    SetTimer(1, False);
}

function Timer()
{
    /** Sets bBlockActors to True after getting spawned */
    if (!bBlockActors)
    {
        bBlockActors = True;
    }

    /** Resets bUnlit to False after KFX.StalkerGlow overlay */
    if (bUnlit)
    {
        bUnlit = False;
    }

    GoToState('SneakAround');
}

simulated function Tick(float DeltaTime)
{
    local PlayerController P;
    local float DistSquared;

    // If we've flagged this character to be destroyed next tick, handle that
    if (bDestroyNextTick && TimeSetDestroyNextTickTime < Level.TimeSeconds)
    {
        Destroy();
    }

    if (
        bAboutToDie && Health > 0 && EvasionDamage.Damage > 0 &&
        FMin(LastEvadeTime + 0.5, FMax(LastReplicateTime, LastSeenOrRelevantTime)) > LastEvadeTime)
    {
        TakeDamage(
            EvasionDamage.Damage,
            EvasionDamage.InstigatedBy,
            EvasionDamage.Hitlocation,
            EvasionDamage.Momentum,
            EvasionDamage.DamageType,
            EvasionDamage.HitIndex);

        bAboutToDie = False;
        EvasionDamage.Damage = 0;
    }

    // Make Zeds move faster if they aren't net relevant, or noone has seen them
    // in a while. This well get the Zeds to the player in larger groups, and
    // quicker - Ramm
    if (Level.NetMode != NM_Client && CanSpeedAdjust())
    {
        if (Level.NetMode == NM_Standalone)
        {
            if (Level.TimeSeconds - LastRenderTime > 5.0)
            {
                P = Level.GetLocalPlayerController();

                if (P != None && P.Pawn != None && Level.TimeSeconds - LastViewCheckTime > 1.0)
                {
                    LastViewCheckTime = Level.TimeSeconds;
                    DistSquared = VSizeSquared(P.Pawn.Location - Location);

                    if ((!P.Pawn.Region.Zone.bDistanceFog || (DistSquared < Square(P.Pawn.Region.Zone.DistanceFogEnd))) &&
                        FastTrace(Location + EyePosition(), P.Pawn.Location + P.Pawn.EyePosition()))
                    {
                        LastSeenOrRelevantTime = Level.TimeSeconds;
                        SetGroundSpeed(GetOriginalGroundSpeed());
                    }
                    else
                    {
                        SetGroundSpeed(default.GroundSpeed * (HiddenGroundSpeed / default.GroundSpeed));
                    }
                }
            }
            else
            {
                LastSeenOrRelevantTime = Level.TimeSeconds;
                SetGroundSpeed(GetOriginalGroundSpeed());
            }
        }
        else if (Level.NetMode == NM_DedicatedServer)
        {
            if (Level.TimeSeconds - LastReplicateTime > 0.5)
            {
                SetGroundSpeed(default.GroundSpeed * (300.0 / default.GroundSpeed));
            }
            else
            {
                LastSeenOrRelevantTime = Level.TimeSeconds;
                SetGroundSpeed(GetOriginalGroundSpeed());
            }
        }
        else if (Level.NetMode == NM_ListenServer)
        {
            if (Level.TimeSeconds - LastReplicateTime > 0.5 && Level.TimeSeconds - LastRenderTime > 5.0)
            {
                P = Level.GetLocalPlayerController();

                if (P != None && P.Pawn != None && Level.TimeSeconds - LastViewCheckTime > 1.0)
                {
                    LastViewCheckTime = Level.TimeSeconds;
                    DistSquared = VSizeSquared(P.Pawn.Location - Location);

                    if ((!P.Pawn.Region.Zone.bDistanceFog || (DistSquared < Square(P.Pawn.Region.Zone.DistanceFogEnd))) &&
                        FastTrace(Location + EyePosition(), P.Pawn.Location + P.Pawn.EyePosition()))
                    {
                        LastSeenOrRelevantTime = Level.TimeSeconds;
                        SetGroundSpeed(GetOriginalGroundSpeed());
                    }
                    else
                    {
                        SetGroundSpeed(default.GroundSpeed * (300.0 / default.GroundSpeed));
                    }
                }
            }
            else
            {
                LastSeenOrRelevantTime = Level.TimeSeconds;
                SetGroundSpeed(GetOriginalGroundSpeed());
            }
        }
    }

    if (bResetAnimAct && ResetAnimActTime < Level.TimeSeconds)
    {
        AnimAction = '';
        bResetAnimAct = False;
    }

    if (Controller != None)
    {
        LookTarget = Controller.Enemy;
    }

    if (Level.NetMode != NM_DedicatedServer && !bCloaked)
    {
        CloakBoss();
    }
}

/**
 * Unused MeleeClaw2 animation added
 * Attack animation rate increased
 * Chaingun attacks handling disabled
 */
simulated function int DoAnimAction(name AnimName)
{
    local float AnimRate;

    if (
        AnimName == 'MeleeClaw' ||
        AnimName == 'MeleeClaw2' ||
        AnimName == 'MeleeImpale' ||
        AnimName == 'transition')
    {
        AnimRate = 1.25;

        if (AnimName != 'transition')
        {
            ApplyHolographicGlow(AnimName, AnimRate);
        }
        AnimBlendParams(1, 1.0, 0.0,, SpineBone1);
        PlayAnim(AnimName, AnimRate, 0.1, 1);

        return 1;
    }
    else if (AnimName == 'RadialAttack')
    {
        AnimRate = 1.25;

        ApplyHolographicGlow(AnimName, AnimRate);
        AnimBlendParams(1, 0.0);
        PlayAnim(AnimName, AnimRate, 0.1);

        return 0;
    }

    return super(KFMonster).DoAnimAction(AnimName);
}

/** Removed blood splatters and burnified effect */
function PlayHit(
    float Damage,
    Pawn InstigatedBy,
    Vector HitLocation,
    class<DamageType> damageType,
    Vector Momentum,
    optional int HitIdx)
{
    local PlayerController PC;
    local Vector HitNormal, HitRay;
    local bool bShowEffects, bRecentHit;
    local float HitBoneDist;
    local name HitBone;

    bRecentHit = Level.TimeSeconds - LastPainTime < 0.2;
    LastDamageAmount = Damage;

    if (Damage <= 0)
    {
        return;
    }

    if (Health > 0 && Damage > float(default.Health) / 1.5)
    {
        FlipOver();
    }

    PC = PlayerController(Controller);

    bShowEffects = (
        Level.NetMode != NM_Standalone ||
        Level.TimeSeconds - LastRenderTime < 2.5 ||
        InstigatedBy != None && PlayerController(InstigatedBy.Controller) != None ||
        PC != None);

    if (!bShowEffects)
    {
        return;
    }

    HitRay = vect(0, 0, 0);
    if (InstigatedBy != None)
    {
        HitRay = Normal(HitLocation - (InstigatedBy.Location + (vect(0, 0, 1) * InstigatedBy.EyeHeight)));
    }

    if (DamageType.default.bLocationalHit)
    {
        CalcHitLoc(HitLocation, HitRay, HitBone, HitBoneDist);
        // Removed zapping effects
    }
    else
    {
        HitLocation = Location;
        HitBone = FireRootBone;
        HitBoneDist = 0.0f;
    }

    if (DamageType.default.bAlwaysSevers && DamageType.default.bSpecial)
    {
        HitBone = 'head';
    }

    if (InstigatedBy != None)
    {
        HitNormal = Normal(Normal(InstigatedBy.Location - HitLocation) + VRand() * 0.2 + vect(0, 0, 2.8));
    }
    else
    {
        HitNormal = Normal(vect(0, 0, 1) + VRand() * 0.2 + vect(0, 0, 2.8));
    }

    /**
     * Snippets responsible for blood splatter projectile spawn, damageFX and M79 achievement stats are removed
     * As those are not needed for pseudo boss hit/death handling
     */
}

/** Get rid of slomo and endgame state transition */
function Died(
    Controller Killer,
    class<DamageType> DamageType,
    Vector HitLocation)
{
    super(KFMonster).Died(Killer, DamageType, HitLocation);
}

simulated function PlayDying(class<DamageType> DamageType, Vector HitLoc)
{
    AmbientSound = None;
    bCanTeleport = False;
    bReplicateMovement = False;
    bTearOff = True;
    bPlayedDeath = True;

    if (CurrentCombo != None)
    {
        CurrentCombo.Destroy();
    }

    HitDamageType = DamageType;
    TakeHitLocation = HitLoc;

    bStunned = False;
    bMovable = True;

    AnimBlendParams(1, 0.0);
    FireState = FS_None;

    LifeSpan = RagdollLifeSpan;

    Visibility = default.Visibility;
    bUnlit = True;
    /**
     * Apply StalkerGlow effect before death
     * To emphasize pseudo/holographic nature of this ZED
     */
    Skins[0] = Finalblend'KFX.StalkerGlow';
    Skins[1] = Finalblend'KFX.StalkerGlow';

    GotoState('ZombieDying');

    PlayDyingSound();
    PlayDyingAnimation(DamageType, HitLoc);
}

simulated function CloakBoss()
{
    if (!bPlayedDeath)
    {
        Visibility = 1;
        bCloaked = True;

        if (Level.NetMode == NM_DedicatedServer)
        {
            return;
        }

        Skins[0] = Shader'KF_Specimens_Trip_T.patriarch_invisible_gun';
        Skins[1] = Shader'KF_Specimens_Trip_T.patriarch_invisible';

        // Invisible - no shadow
        if (PlayerShadow != None)
        {
            PlayerShadow.bShadowActive = False;
        }

        if (RealTimeShadow != None)
        {
            RealTimeShadow.Destroy();
        }

        // Remove/disallow projectors on invisible people
        Projectors.Remove(0, Projectors.Length);
        bAcceptsProjectors = False;
    }
}

/** Disabled chaingun and rocket attacks */
function RangedAttack(Actor A)
{
    if (bShotAnim)
    {
        return;
    }

    if (IsCloseEnuf(A))
    {
        bShotAnim = True;

        if (Pawn(A) != None && FRand() < 0.5)
        {
            SetAnimAction('MeleeImpale');
        }
        else
        {
            SetAnimAction('MeleeClaw');
        }
    }
    else if (bChargingPlayer)
    {
        return;
    }
    else if (!bChargingPlayer)
    {
        SetAnimAction('transition');
        GoToState('Charging');
    }
}

/**
 * Apply StalkerGlow effect before hit
 * To emphasize pseudo/holographic nature of this ZED
 */
function ApplyHolographicGlow(name AnimName, optional float Rate)
{
    local float AnimDuration;
    AnimDuration = GetAnimDuration(AnimName, Rate);

    bUnlit = True;
    SetOverlayMaterial(Finalblend'KFX.StalkerGlow', AnimDuration, True);
    SetTimer(AnimDuration, False);
}

state SneakAround
{
Begin:
    CloakBoss();

    while (true)
    {
        Sleep(0.5);

        if (!bCloaked && !bShotAnim)
            CloakBoss();

        if (!Controller.IsInState('ZombieHunt') && !Controller.IsInState('WaitForAnim'))
        {
            Controller.GoToState('ZombieHunt');
        }
    }
}

state ZombieDying
{
Begin:
    Sleep(0.2);
    bDestroyNextTick = True;
}

/********************************************
 * DISABLED HEALTH MODIFIERS
 ********************************************/

function float DifficultyHealthModifer()
{
    return AdjustedHealthModifier;
}

function float NumPlayersHealthModifer()
{
    return AdjustedHealthModifier;
}

function float DifficultyHeadHealthModifer()
{
    return AdjustedHeadHealthModifier;
}

function float NumPlayersHeadHealthModifer()
{
    return AdjustedHeadHealthModifier;
}

/********************************************
 * DISABLED BEHAVIOURS
 ********************************************/

/** Always cloaked */
simulated function UnCloakBoss() {}

/** No hit effects */
simulated function ProcessHitFX() {}

/** No gibs and blood stains */
event KImpact(Actor Other, Vector Pos, Vector ImpactVel, Vector ImpactNorm) {}

simulated function HideBone(name BoneName) {}
simulated function SpawnGibs(Rotator HitRotation, float ChunkPerterbation) {}

/** No decapitation */
function RemoveHead() {}

/** No burning behaviour */
simulated function StartBurnFX() {}
simulated function StopBurnFX() {}
simulated function ZombieCrispUp() {}

defaultProperties
{
    CustomMenuName="N7 Pseudo Patriarch"
    ScoringValue=0
    Health=5
    HeadHealth=5
    HealthMax=5
    AdjustedHealthModifier=1.0
    AdjustedHeadHealthModifier=1.0
    bBlockActors=False
    bIgnoreEncroachers=True
    bPseudo=True
    MotionDetectorThreat=0
    bCanDistanceAttackDoors=False
    ControllerClass=class'KFChar.BossZombieController'
    HitSound(0)=Sound'Inf_Weapons.panzerfaust60.faust_explode_distant02'
    DeathSound(0)=Sound'Inf_Weapons.panzerfaust60.faust_explode_distant02'
}
