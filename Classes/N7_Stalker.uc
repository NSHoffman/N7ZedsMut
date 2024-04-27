class N7_Stalker extends KFChar.ZombieStalker_STANDARD
    config(N7ZedsMut);

var const bool bPseudo;

/**
 * Each stalker has a chance to spawn
 * a squad of pseudos, projections
 * that get killed if the host is dead
 */
var class<N7_Stalker> PseudoClass;
var array<N7_Stalker> PseudoSquad;

var config int MinPseudos;
var config int MaxPseudos;

var config string CustomMenuName;

replication {
    reliable if (Role == ROLE_AUTHORITY)
        CustomMenuName;
}

/** Spawning pseudo stalkers squad */
simulated function PostBeginPlay()
{
    if (!bPseudo)
    {
        SetupConfig();
        SpawnPseudoSquad();
    }

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
    if (MinPseudos < 0 || MinPseudos > 10 ||
        MaxPseudos < 0 || MaxPseudos > 10 ||
        MinPseudos > MaxPseudos)
    {
        MinPseudos = 0;
        MaxPseudos = 1;
    }
}

/* Don't interrupt stalker when she's trying to attack */
simulated function bool HitCanInterruptAction()
{
    return !bShotAnim;
}

simulated event SetAnimAction(name NewAction)
{
    if (NewAction == '')
    {
        return;
    }

    ExpectingChannel = AttackAndMoveDoAnimAction(NewAction);

    bWaitForAnim = False;

    if (Level.NetMode != NM_Client)
    {
        AnimAction = NewAction;
        bResetAnimAct = True;
        ResetAnimActTime = Level.TimeSeconds + 0.3;
    }
}

simulated function int AttackAndMoveDoAnimAction(name AnimName)
{
    local int meleeAnimIndex;

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
        AnimBlendParams(1, 1.0, 0.0,, FireRootBone);
        PlayAnim(AnimName,, 0.1, 1);

        return 1;
    }

    return super(KFMonster).DoAnimAction(AnimName);
}

simulated function Tick(float DeltaTime)
{
    local bool bKeepAccelerationWhileAttacking;
    bKeepAccelerationWhileAttacking = LookTarget != None && bShotAnim && !bWaitForAnim;

    super(KFMonster).Tick(DeltaTime);

    /**
     * This part is taken from parent ZombieStalker class
     * because all the material sources are hardcoded inside its methods bodies
     * but need to be changed here
     */
    if (Level.NetMode != NM_DedicatedServer)
    {
        if (bZapped)
        {
            NextCheckTime = Level.TimeSeconds;
        }
        else if (Level.TimeSeconds > NextCheckTime && Health > 0)
        {
            NextCheckTime = Level.TimeSeconds + 0.5;

            if (
                LocalKFHumanPawn != None
                && LocalKFHumanPawn.Health > 0
                && LocalKFHumanPawn.ShowStalkers()
                && VSizeSquared(Location - LocalKFHumanPawn.Location) < LocalKFHumanPawn.GetStalkerViewDistanceMulti() * 640000.0 // 640000 = 800 Units
            )
            {
                bSpotted = True;
            }
            else
            {
                bSpotted = False;
            }

            if (!bSpotted && !bCloaked && Skins[0] != default.Skins[3])
            {
                UncloakStalker();
            }
            else if (Level.TimeSeconds - LastUncloakTime > 1.2)
            {
                if (bSpotted && Skins[0] != Finalblend'KFX.StalkerGlow')
                {
                    bUnlit = False;
                    CloakStalker();
                }
                else if (Skins[0] != default.Skins[0])
                {
                    CloakStalker();
                }
            }
        }
    }


    if (Role == ROLE_Authority && bKeepAccelerationWhileAttacking)
    {
        Acceleration = AccelRate * Normal(LookTarget.Location - Location);
    }
}

function RangedAttack(Actor A)
{
    local bool bDoRangedAttack;
    bDoRangedAttack = CanAttack(A) && !(bShotAnim || Physics == PHYS_Swimming);

    if (bDoRangedAttack)
    {
        bShotAnim = True;
        SetAnimAction('ClawAndMove');
    }
}

function SpawnPseudoSquad()
{
    local int PseudoSquadSize, i;
    local N7_Stalker CurrentPseudoStalker;

    if (MaxPseudos <= 0 || MaxPseudos < MinPseudos)
    {
        return;
    }

    PseudoSquadSize = MinPseudos + Rand(MaxPseudos - MinPseudos + 1);

    for (i = 0; i < PseudoSquadSize; i++)
    {
        CurrentPseudoStalker = Spawn(PseudoClass);

        if (CurrentPseudoStalker != None)
        {
            PseudoSquad[PseudoSquad.Length] = CurrentPseudoStalker;
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

/**
 * The whole purpose of overriding the methods below
 * is to replace hardcoded materials with property values
 */

function RemoveHead()
{
    super.RemoveHead();

    if (!bCrispified)
    {
        Skins[1] = default.Skins[2];
        Skins[0] = default.Skins[3];
    }
}

simulated function CloakStalker()
{
    if (bZapped)
    {
        return;
    }

    if (bSpotted)
    {
        if (Level.NetMode == NM_DedicatedServer)
            return;

        Skins[0] = Finalblend'KFX.StalkerGlow';
        Skins[1] = Finalblend'KFX.StalkerGlow';
        bUnlit = True;
        return;
    }

    if (!bDecapitated && !bCrispified)
    {
        Visibility = 1;
        bCloaked = True;

        if (Level.NetMode == NM_DedicatedServer)
            return;

        Skins[0] = default.Skins[0];
        Skins[1] = default.Skins[1];

        if (PlayerShadow != None)
            PlayerShadow.bShadowActive = False;
        if (RealTimeShadow != None)
            RealTimeShadow.Destroy();

        Projectors.Remove(0, Projectors.Length);
        bAcceptsProjectors = False;
        SetOverlayMaterial(Material'KFX.FBDecloakShader', 0.25, True);
    }
}

simulated function UnCloakStalker()
{
    if (bZapped)
    {
        return;
    }

    if (!bCrispified)
    {
        LastUncloakTime = Level.TimeSeconds;

        Visibility = default.Visibility;
        bCloaked = False;
        bUnlit = False;

        // 25% chance of our Enemy saying something about us being invisible
        if (
            Level.NetMode != NM_Client
            && !KFGameType(Level.Game).bDidStalkerInvisibleMessage
            && FRand() < 0.25
            && Controller.Enemy != None
            && PlayerController(Controller.Enemy.Controller) != None
        )
        {
            PlayerController(Controller.Enemy.Controller).Speech('AUTO', 17, "");
            KFGameType(Level.Game).bDidStalkerInvisibleMessage = True;
        }

        if (Level.NetMode == NM_DedicatedServer)
            return;

        if (Skins[0] != default.Skins[3])
        {
            Skins[1] = default.Skins[2];
            Skins[0] = default.Skins[3];

            if (PlayerShadow != None)
            {
                PlayerShadow.bShadowActive = True;
            }

            bAcceptsProjectors = True;
            SetOverlayMaterial(Material'KFX.FBDecloakShader', 0.25, True);
        }
    }
}

simulated function SetZappedBehavior()
{
    super.SetZappedBehavior();

    bUnlit = False;

    // Handle setting the zed to uncloaked so the zapped overlay works properly
    if (Level.Netmode != NM_DedicatedServer)
    {
        Skins[1] = default.Skins[2];
        Skins[0] = default.Skins[3];

        if (PlayerShadow != None)
        {
            PlayerShadow.bShadowActive = True;
        }

        bAcceptsProjectors = True;
        SetOverlayMaterial(Material'KFZED_FX_T.Energy.ZED_overlay_Hit_Shdr', 999, True);
    }
}

simulated function PlayDying(class<DamageType> DamageType, Vector HitLoc)
{
    super(KFMonster).PlayDying(DamageType, HitLoc);

    if (!bPseudo)
    {
        KillPseudoSquad();
    }

    if (bUnlit)
    {
        bUnlit = !bUnlit;
    }

    LocalKFHumanPawn = None;

    if (!bCrispified)
    {
        Skins[1] = default.Skins[2];
        Skins[0] = default.Skins[3];
    }
}

defaultProperties
{
    CustomMenuName="N7 Stalker"
    GroundSpeed=210.000000
    WaterSpeed=190.000000
    bPseudo=False
    MinPseudos=0
    MaxPseudos=1
    PseudoClass=class'N7_PseudoStalker'
    Skins(2)=FinalBlend'KF_Specimens_Trip_T.stalker_fb'
    Skins(3)=Combiner'KF_Specimens_Trip_T.stalker_cmb'
}
