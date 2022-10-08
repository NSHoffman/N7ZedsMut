class N7_Husk extends KFChar.ZombieHusk_STANDARD;

/* Max interval between shots */
var const float MinFireInterval;
var const float MaxFireInterval;

/**
 * For some reason original function used to 
 * explicitly override HuskFireProjClass to class'KFChar.HuskFireProjectile'
 */
function SpawnTwoShots()
{
    local vector X,Y,Z, FireStart;
    local rotator FireRotation;
    local KFMonsterController KFMonstControl;

    if (Controller != None && KFDoorMover(Controller.Target) != None)
    {
        Controller.Target.TakeDamage(22, self, Location, vect(0, 0, 0), class'KFMod.DamTypeBurned');
        return;
    }

    GetAxes(Rotation, X, Y, Z);
    FireStart = GetBoneCoords('Barrel').Origin;

    if (!SavedFireProperties.bInitialized)
    {
        SavedFireProperties.AmmoClass = class'Old2K4.SkaarjAmmo';
        SavedFireProperties.ProjectileClass = HuskFireProjClass;
        SavedFireProperties.WarnTargetPct = 1;
        SavedFireProperties.MaxRange = 65535;
        SavedFireProperties.bTossed = False;
        SavedFireProperties.bTrySplash = True;
        SavedFireProperties.bLeadTarget = True;
        SavedFireProperties.bInstantHit = False;
        SavedFireProperties.bInitialized = True;
    }

    // Turn off extra collision before spawning, otherwise spawn fails
    ToggleAuxCollision(False);
    FireRotation = Controller.AdjustAim(SavedFireProperties, FireStart, 0);

    foreach DynamicActors(class'KFMod.KFMonsterController', KFMonstControl)
    {
        if (KFMonstControl != Controller)
        {
            if (PointDistToLine(KFMonstControl.Pawn.Location, vector(FireRotation), FireStart) < 75)
            {
                KFMonstControl.GetOutOfTheWayOfShot(vector(FireRotation), FireStart);
            }
        }
    }
    Spawn(HuskFireProjClass, self,, FireStart, FireRotation);
    // Turn extra collision back on
    ToggleAuxCollision(True);
}

function RangedAttack(Actor A)
{
    local int LastFireTime;
    local float NextFireTimeCooldown;

    if (bShotAnim) 
    {
        return;
    }

    if (Physics == PHYS_Swimming)
    {
        SetAnimAction('Claw');
        bShotAnim = True;
        LastFireTime = Level.TimeSeconds;
    }

    else if (VSize(A.Location - Location) < MeleeRange + CollisionRadius + A.CollisionRadius)
    {
        bShotAnim = True;
        LastFireTime = Level.TimeSeconds;
        SetAnimAction('Claw');
        Controller.bPreparingMove = True;
        Acceleration = vect(0, 0, 0);
    }

    else if (!bDecapitated && (
        KFDoorMover(A) != None 
        || (!Region.Zone.bDistanceFog && VSize(A.Location - Location) <= 65535) 
        || (Region.Zone.bDistanceFog && VSizeSquared(A.Location - Location) < (Square(Region.Zone.DistanceFogEnd) * 0.8)))
    ) {
        bShotAnim = True;
        SetAnimAction('ShootBurnsAndMove');

        NextFireTimeCooldown = FMin(MaxFireInterval, MinFireInterval + FRand() * ProjectileFireInterval);
        NextFireProjectileTime = Level.TimeSeconds + NextFireTimeCooldown;
    }
}

simulated event SetAnimAction(name NewAction)
{
    local int meleeAnimIndex;

    if (NewAction == '')
    {
        return;
    }

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

    ExpectingChannel = AttackAndMoveDoAnimAction(NewAction);
    bWaitForAnim = AnimNeedsWait(NewAction);

    if (Level.NetMode != NM_Client)
    {
        AnimAction = NewAction;
        bResetAnimAct = True;
        ResetAnimActTime = Level.TimeSeconds+0.3;
    }
}

/* Handle playing the anim action on the upper body only if we're attacking and moving */
simulated function int AttackAndMoveDoAnimAction(name AnimName)
{
    if (AnimName == 'ShootBurnsAndMove')
    {
        AnimBlendParams(1, 1.0, 0.0,, FireRootBone, True);
        PlayAnim('ShootBurns',, 0.1, 1);

        return 1;
    }

    return DoAnimAction(AnimName);
}

simulated function bool AnimNeedsWait(name TestAnim)
{
    if (TestAnim == 'ShootBurnsAndMove')
    {
        return False;
    }

    return super.AnimNeedsWait(TestAnim);
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
    MinFireInterval=1.000000
    MaxFireInterval=3.500000
    ProjectileFireInterval=10.00000
    HuskFireProjClass=class'N7_HuskFireProjectile'
    DetachedArmClass=class'N7_SeveredArmHusk'
    DetachedLegClass=class'N7_SeveredLegHusk'
    DetachedHeadClass=class'N7_SeveredHeadHusk'
    Skins(0)=Texture'KF_Specimens_Trip_N7_Two.burns.burns_tatters'
    Skins(1)=Shader'KF_Specimens_Trip_N7_Two.burns.burns_shdr'
}
