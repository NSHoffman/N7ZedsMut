class N7_Stalker extends KFChar.ZombieStalker_STANDARD;

/**
 * Each stalker has a chance to spawn
 * a squad of pseudo stalkers, projections
 * that get killed if the host stalker is dead
 */
var Class<N7_Stalker> PseudoStalkerClass;
var Array<N7_Stalker> PseudoStalkersSquad;

var int MaxPseudoSquadSize;

/** Spawning pseudo stalkers squad */
simulated function PostBeginPlay()
{
    local int PseudoSquadSize;
    PseudoSquadSize = Rand(MaxPseudoSquadSize + 1);

    Super.PostBeginPlay();
    SpawnPseudoSquad(PseudoSquadSize);
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
    
    bWaitForAnim = false;

    if (Level.NetMode != NM_Client) 
    {
        AnimAction = NewAction;
        bResetAnimAct = true;
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

    return Super(KFMonster).DoAnimAction(AnimName);
}

simulated function Tick(float DeltaTime) 
{
    local bool bKeepAccelerationWhileAttacking;
    bKeepAccelerationWhileAttacking = LookTarget != None && bShotAnim && !bWaitForAnim;

    Super(KFMonster).Tick(DeltaTime);

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
                bSpotted = true;
            }
            else
            {
                bSpotted = false;
            }

            if (!bSpotted && !bCloaked && Skins[0] != Combiner'KF_Specimens_Trip_N7.stalker_cmb')
            {
                UncloakStalker();
            }
            else if (Level.TimeSeconds - LastUncloakTime > 1.2)
            {
                if (bSpotted && Skins[0] != Finalblend'KFX.StalkerGlow')
                {
                    bUnlit = false;
                    CloakStalker();
                }
                else if (Skins[0] != Shader'KF_Specimens_Trip_N7.stalker_invisible')
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
        bShotAnim = true;
        SetAnimAction('ClawAndMove');
    }
}

function SpawnPseudoSquad(int PseudoSquadSize)
{
    local int i;
    local N7_Stalker CurrentPseudoStalker;

    for (i = 0; i < PseudoSquadSize; i++)
    {
        CurrentPseudoStalker = Spawn(PseudoStalkerClass);

        if (CurrentPseudoStalker != None)
        {
            PseudoStalkersSquad[i] = CurrentPseudoStalker;
        }
    }
}

function KillPseudoSquad()
{
    local int i;

    for (i = 0; i < PseudoStalkersSquad.Length; i++)
    {
        if (PseudoStalkersSquad[i] != None)
        {
            PseudoStalkersSquad[i].Died(LastDamagedBy.Controller, LastDamagedByType, Location);
            PseudoStalkersSquad[i] = None;
        }
    }

    PseudoStalkersSquad.Length = 0;
}

/** 
 * The whole purpose of overriding the methods below
 * is to provide different material sources
 */

function RemoveHead()
{
    Super.RemoveHead();

    if (!bCrispified)
    {
        Skins[1] = FinalBlend'KF_Specimens_Trip_N7.stalker_fb';
        Skins[0] = Combiner'KF_Specimens_Trip_N7.stalker_cmb';
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
        bUnlit = true;
        return;
    }

    if (!bDecapitated && !bCrispified)
    {
        Visibility = 1;
        bCloaked = true;

        if (Level.NetMode == NM_DedicatedServer)
            return;

        Skins[0] = Shader'KF_Specimens_Trip_N7.stalker_invisible';
        Skins[1] = Shader'KF_Specimens_Trip_N7.stalker_invisible';

        if (PlayerShadow != None)
            PlayerShadow.bShadowActive = false;
        if (RealTimeShadow != None)
            RealTimeShadow.Destroy();

        Projectors.Remove(0, Projectors.Length);
        bAcceptsProjectors = false;
        SetOverlayMaterial(Material'KFX.FBDecloakShader', 0.25, true);
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
        bCloaked = false;
        bUnlit = false;

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
            KFGameType(Level.Game).bDidStalkerInvisibleMessage = true;
        }

        if (Level.NetMode == NM_DedicatedServer)
            return;

        if (Skins[0] != Combiner'KF_Specimens_Trip_N7.stalker_cmb')
        {
            Skins[1] = FinalBlend'KF_Specimens_Trip_N7.stalker_fb';
            Skins[0] = Combiner'KF_Specimens_Trip_N7.stalker_cmb';

            if (PlayerShadow != None)
                PlayerShadow.bShadowActive = true;

            bAcceptsProjectors = true;
            SetOverlayMaterial(Material'KFX.FBDecloakShader', 0.25, true);
        }
    }
}

simulated function SetZappedBehavior()
{
    Super.SetZappedBehavior();

    bUnlit = false;

    // Handle setting the zed to uncloaked so the zapped overlay works properly
    if (Level.Netmode != NM_DedicatedServer)
    {
        Skins[1] = FinalBlend'KF_Specimens_Trip_N7.stalker_fb';
        Skins[0] = Combiner'KF_Specimens_Trip_N7.stalker_cmb';

        if (PlayerShadow != None)
            PlayerShadow.bShadowActive = true;

        bAcceptsProjectors = true;
        SetOverlayMaterial(Material'KFZED_FX_T.Energy.ZED_overlay_Hit_Shdr', 999, true);
    }
}

simulated function PlayDying(Class<DamageType> DamageType, Vector HitLoc)
{
    Super.PlayDying(DamageType, HitLoc);

    KillPseudoSquad();

    if (bUnlit)
        bUnlit = !bUnlit;

    LocalKFHumanPawn = None;

    if (!bCrispified)
    {
        Skins[1] = FinalBlend'KF_Specimens_Trip_N7.stalker_fb';
        Skins[0] = Combiner'KF_Specimens_Trip_N7.stalker_cmb';
    }
}

static simulated function PreCacheMaterials(LevelInfo myLevel)
{
    myLevel.AddPrecacheMaterial(Combiner'KF_Specimens_Trip_N7.stalker_cmb');
    myLevel.AddPrecacheMaterial(Combiner'KF_Specimens_Trip_N7.stalker_env_cmb');
    myLevel.AddPrecacheMaterial(Texture'KF_Specimens_Trip_N7.stalker_diff');
    myLevel.AddPrecacheMaterial(Texture'KF_Specimens_Trip_N7.stalker_spec');
    myLevel.AddPrecacheMaterial(Material'KF_Specimens_Trip_N7.stalker_invisible');
    myLevel.AddPrecacheMaterial(Combiner'KF_Specimens_Trip_N7.StalkerCloakOpacity_cmb');
    myLevel.AddPrecacheMaterial(Material'KF_Specimens_Trip_N7.StalkerCloakEnv_rot');
    myLevel.AddPrecacheMaterial(Material'KF_Specimens_Trip_N7.stalker_opacity_osc');
    myLevel.AddPrecacheMaterial(Material'KFCharacters.StalkerSkin');
}

defaultProperties
{
    MenuName="N7 Stalker"
    GroundSpeed=210.000000
    WaterSpeed=190.000000
    MaxPseudoSquadSize=3;
    PseudoStalkerClass=Class'N7ZedsMut.N7_PseudoStalker'
    DetachedArmClass=Class'N7ZedsMut.N7_SeveredArmStalker'
    DetachedLegClass=Class'N7ZedsMut.N7_SeveredLegStalker'
    DetachedHeadClass=Class'N7ZedsMut.N7_SeveredHeadStalker'
    Skins(0)=Shader'KF_Specimens_Trip_N7.stalker_invisible'
    Skins(1)=Shader'KF_Specimens_Trip_N7.stalker_invisible'
}
