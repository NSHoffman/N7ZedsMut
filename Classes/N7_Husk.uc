class N7_Husk extends KFChar.ZombieHusk_STANDARD;

/* Avoid approaching enemy players */
// var N7_HuskPlayerAvoidArea AvoidArea;
/* Max interval between shots */
var const float MaxFireInterval;

// simulated function PostNetBeginPlay()
// {
// 	if (AvoidArea == None) 
// 	{
// 		AvoidArea = Spawn(class'N7_HuskPlayerAvoidArea', Self);
// 	}
// 	else 
// 	{
// 		AvoidArea.InitFor(Self);
// 	}
// 	Log("Avoid Area:"@int(AvoidArea != None));

// 	EnableChannelNotify(1, 1);
// 	AnimBlendParams(1, 1.0, 0.0,, SpineBone1);
// 	Super.PostNetBeginPlay();
// }

/**
 * For some reason original function used to 
 * explicitly override HuskFireProjClass to Class'HuskFireProjectile'
 */
function SpawnTwoShots()
{
    local vector X,Y,Z, FireStart;
    local rotator FireRotation;
    local KFMonsterController KFMonstControl;

    if (Controller != None && KFDoorMover(Controller.Target) != None)
    {
        Controller.Target.TakeDamage(22, Self, Location, vect(0,0,0), Class'DamTypeVomit');
        return;
    }

    GetAxes(Rotation,X,Y,Z);
    FireStart = GetBoneCoords('Barrel').Origin;

    if (!SavedFireProperties.bInitialized)
    {
        SavedFireProperties.AmmoClass = Class'SkaarjAmmo';
        SavedFireProperties.ProjectileClass = HuskFireProjClass;
        SavedFireProperties.WarnTargetPct = 1;
        SavedFireProperties.MaxRange = 65535;
        SavedFireProperties.bTossed = false;
        SavedFireProperties.bTrySplash = true;
        SavedFireProperties.bLeadTarget = true;
        SavedFireProperties.bInstantHit = false;
        SavedFireProperties.bInitialized = true;
    }

    // Turn off extra collision before spawning, otherwise spawn fails
    ToggleAuxCollision(false);
    FireRotation = Controller.AdjustAim(SavedFireProperties, FireStart, 600);

    foreach DynamicActors(class'KFMonsterController', KFMonstControl)
    {
        if (KFMonstControl != Controller)
        {
            if (PointDistToLine(KFMonstControl.Pawn.Location, vector(FireRotation), FireStart) < 75)
            {
                KFMonstControl.GetOutOfTheWayOfShot(vector(FireRotation), FireStart);
            }
        }
    }
    Spawn(HuskFireProjClass, Self,, FireStart, FireRotation);
    // Turn extra collision back on
    ToggleAuxCollision(true);
}

function RangedAttack(Actor A)
{
    local int LastFireTime;
    local float NextFireTimeCooldown;

    if (bShotAnim)
        return;

    if (Physics == PHYS_Swimming)
    {
        SetAnimAction('Claw');
        bShotAnim = true;
        LastFireTime = Level.TimeSeconds;
    }
    else if (VSize(A.Location - Location) < MeleeRange + CollisionRadius + A.CollisionRadius)
    {
        bShotAnim = true;
        LastFireTime = Level.TimeSeconds;
        SetAnimAction('Claw');
        Controller.bPreparingMove = true;
        Acceleration = vect(0,0,0);
    }
    else if (!bDecapitated && (
        KFDoorMover(A) != None 
        || (!Region.Zone.bDistanceFog && VSize(A.Location-Location) <= 65535) 
        || (Region.Zone.bDistanceFog && VSizeSquared(A.Location-Location) < (Square(Region.Zone.DistanceFogEnd) * 0.8)))
    ) {
        bShotAnim = true;
        SetAnimAction('ShootBurnsAndMove');

        NextFireTimeCooldown = FMin(MaxFireInterval, FRand() * ProjectileFireInterval);
        NextFireProjectileTime = Level.TimeSeconds + NextFireTimeCooldown;
    }
}

simulated event SetAnimAction(name NewAction)
{
    local int meleeAnimIndex;
    local bool bWantsToAttackAndMove;

    if (NewAction == '')
        return;

    bWantsToAttackAndMove = NewAction == 'ShootBurnsAndMove';

    switch (NewAction) 
    {
    case 'Claw':
        meleeAnimIndex = Rand(3);
        NewAction = meleeAnims[meleeAnimIndex];
        CurrentDamtype = ZombieDamType[meleeAnimIndex];
        break;
    
    case 'DoorBash':
        CurrentDamtype = ZombieDamType[Rand(3)];
        break;
    }

    if (bWantsToAttackAndMove)
    {
       ExpectingChannel = AttackAndMoveDoAnimAction(NewAction);
    }
    else
    {
       ExpectingChannel = DoAnimAction(NewAction);
    }

    if (!bWantsToAttackAndMove && AnimNeedsWait(NewAction))
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
        ResetAnimActTime = Level.TimeSeconds+0.3;
    }
}

/* Handle playing the anim action on the upper body only if we're attacking and moving */
simulated function int AttackAndMoveDoAnimAction(name AnimName)
{
    if (AnimName == 'ShootBurnsAndMove')
    {
        AnimBlendParams(1, 1.0, 0.0,, FireRootBone, true);
        PlayAnim('ShootBurns',, 0.1, 1);

        return 1;
    }
    return Super.DoAnimAction(AnimName);
}

static simulated function PreCacheMaterials(LevelInfo myLevel)
{
    myLevel.AddPrecacheMaterial(Texture'KF_Specimens_Trip_N7_Two.burns_diff');
    myLevel.AddPrecacheMaterial(Texture'KF_Specimens_Trip_N7_Two.burns_emissive_mask');
    myLevel.AddPrecacheMaterial(Combiner'KF_Specimens_Trip_N7_Two.burns_energy_cmb');
    myLevel.AddPrecacheMaterial(Combiner'KF_Specimens_Trip_N7_Two.burns_env_cmb');
    myLevel.AddPrecacheMaterial(Combiner'KF_Specimens_Trip_N7_Two.burns_fire_cmb');
    myLevel.AddPrecacheMaterial(Material'KF_Specimens_Trip_N7_Two.burns_shdr');
    myLevel.AddPrecacheMaterial(Combiner'KF_Specimens_Trip_N7_Two.burns_cmb');
}

defaultProperties
{
    MenuName="N7 Husk"
    GroundSpeed=95.000000
    WaterSpeed=85.000000
    MaxFireInterval=3.500000
    ProjectileFireInterval=10.00000
    HuskFireProjClass=Class'N7ZedsMut.N7_HuskFireProjectile'
    /** @todo implement husk close quarters contact avoiding behaviour */
    // ControllerClass=Class'N7ZedsMut.N7_HuskController'
    Skins(0)=Texture'KF_Specimens_Trip_N7_Two.burns.burns_tatters'
    Skins(1)=Shader'KF_Specimens_Trip_N7_Two.burns.burns_shdr'
}
