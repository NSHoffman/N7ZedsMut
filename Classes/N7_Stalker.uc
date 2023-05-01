class N7_Stalker extends KFChar.ZombieStalker_STANDARD;

/**
 * Each stalker has a chance to spawn
 * a squad of pseudos, projections
 * that get killed if the host is dead
 */
var class<N7_Stalker> PseudoClass;
var Array<N7_Stalker> PseudoSquad;

var int MinPseudoSquadSize;
var int MaxPseudoSquadSize;

/** Spawning pseudo stalkers squad */
simulated function PostBeginPlay()
{
    super.PostBeginPlay();

    SpawnPseudoSquad();
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

            if (!bSpotted && !bCloaked && Skins[0] != Combiner'KF_Specimens_Trip_N7.stalker_cmb')
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
        bShotAnim = True;
        SetAnimAction('ClawAndMove');
    }
}

function SpawnPseudoSquad()
{
    local int PseudoSquadSize, i;
    local N7_Stalker CurrentPseudoStalker;

    PseudoSquadSize = MinPseudoSquadSize + Rand(MaxPseudoSquadSize - MinPseudoSquadSize + 1);

    for (i = 0; i < PseudoSquadSize; i++)
    {
        CurrentPseudoStalker = Spawn(PseudoClass);

        if (CurrentPseudoStalker != None)
        {
            PseudoSquad[i] = CurrentPseudoStalker;
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

defaultProperties
{
    MenuName="N7 Stalker"
    GroundSpeed=210.000000
    WaterSpeed=190.000000
    MinPseudoSquadSize=0
    MaxPseudoSquadSize=3
    PseudoClass=class'N7_PseudoStalker'
}
