class N7_PseudoStalker extends N7_Stalker;

var const float AdjustedHealthModifier;
var const float AdjustedHeadHealthModifier;

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
}

simulated function int AttackAndMoveDoAnimAction(name AnimName)
{
    local int meleeAnimIndex;
    local float AnimDuration;

    if (AnimName == 'ClawAndMove')
    {
        meleeAnimIndex = Rand(3);
        AnimName = MeleeAnims[meleeAnimIndex];
        CurrentDamtype = ZombieDamType[meleeAnimIndex];
    }

    if (
        AnimName == MeleeAnims[0] ||
        AnimName == MeleeAnims[1] ||
        AnimName == MeleeAnims[2]
    ) {
        AnimDuration = GetAnimDuration(AnimName);

        /**
         * Apply StalkerGlow effect before hit
         * To emphasize pseudo/holographic nature of this ZED
         */
        bUnlit = True;
        SetOverlayMaterial(Finalblend'KFX.StalkerGlow', AnimDuration, True);
        SetTimer(AnimDuration, False);

        AnimBlendParams(1, 1.0, 0.0,, FireRootBone);
        PlayAnim(AnimName,, 0.1, 1);

        return 1;
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
     * As those are not needed for pseudo stalker hit/death handling
     */
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
    LocalKFHumanPawn = None;

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

simulated function CloakStalker()
{
    if (!bPlayedDeath)
    {
        Visibility = 1;
        bCloaked = True;

        if (Level.NetMode == NM_DedicatedServer)
        {
            return;
        }

        Skins[0] = Shader'KF_Specimens_Trip_T.stalker_invisible';
        Skins[1] = Shader'KF_Specimens_Trip_T.stalker_invisible';

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

simulated function Tick(float DeltaTime)
{
    local PlayerController P;
    local float DistSquared;
    local bool bKeepAccelerationWhileAttacking;

    bKeepAccelerationWhileAttacking = LookTarget != None && bShotAnim && !bWaitForAnim;

    /** BEGIN: KFMonster.Tick */

    // If we've flagged this character to be destroyed next tick, handle that
    if (bDestroyNextTick && TimeSetDestroyNextTickTime < Level.TimeSeconds)
    {
        Destroy();
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

    // Removed code responsible for burning/zapped behaviour

    /** END: KFMonster.Tick */

    if (Level.NetMode != NM_DedicatedServer && !bCloaked)
    {
        CloakStalker();
    }

    if (Role == ROLE_Authority && bKeepAccelerationWhileAttacking)
    {
        Acceleration = AccelRate * Normal(LookTarget.Location - Location);
    }
}

function TakeFireDamage(int Damage, Pawn Instigator)
{
    local Vector DummyHitLoc, DummyMomentum;
    TakeDamage(Damage, BurnInstigator, DummyHitLoc, DummyMomentum, FireDamageClass);
}

/** Ragdoll gets destroyed almost instantly */
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
simulated function UnCloakStalker() {}

/** No hit effects */
simulated function ProcessHitFX() {}

/** No gibs and blood stains */
event KImpact(Actor Other, Vector Pos, Vector ImpactVel, Vector ImpactNorm) {}

simulated function HideBone(name BoneName) {}
simulated function SpawnGibs(Rotator HitRotation, float ChunkPerterbation) {}

/** No zapped behaviour */
function SetZapped(float ZapAmount, Pawn Instigator) {}

simulated function SetZappedBehavior() {}
simulated function UnSetZappedBehavior() {}

/** No decapitation */
function RemoveHead() {}

/** No burning behaviour */
simulated function StartBurnFX() {}
simulated function StopBurnFX() {}
simulated function SetBurningBehavior() {}
simulated function UnSetBurningBehavior() {}
simulated function ZombieCrispUp() {}

defaultProperties
{
    CustomMenuName="N7 Pseudo Stalker"
    ScoringValue=0
    Health=5
    HeadHealth=5
    HealthMax=5
    AdjustedHealthModifier=1.0
    AdjustedHeadHealthModifier=1.0
    bPseudo=True
    bBlockActors=False
    bIgnoreEncroachers=True
    bCanDistanceAttackDoors=False
    MotionDetectorThreat=0
    HitSound(0)=Sound'Inf_Weapons.panzerfaust60.faust_explode_distant02'
    DeathSound(0)=Sound'Inf_Weapons.panzerfaust60.faust_explode_distant02'
}
