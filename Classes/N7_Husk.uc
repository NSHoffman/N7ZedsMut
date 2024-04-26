class N7_Husk extends KFChar.ZombieHusk_STANDARD
    config(N7ZedsMut);

/* Max interval between shots */
var config float MinFireInterval;
var config float MaxFireInterval;

var config float MovingAttackChance;
var config int MovingAttackCertainDistance;

var config string CustomMenuName;

var bool bMovingAttack;

replication {
    reliable if (Role == ROLE_AUTHORITY)
        CustomMenuName;
}

simulated function PostBeginPlay()
{
    super.PostBeginPlay();

    SetupConfig();
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
    if (MinFireInterval < 0 || MinFireInterval > 10 ||
        MaxFireInterval < 0 || MaxFireInterval > 60 ||
        MinFireInterval > MaxFireInterval)
    {
        MinFireInterval = 2.0;
        MaxFireInterval = 4.0;
    }

    if (MovingAttackCertainDistance < 0 || MovingAttackCertainDistance > 10000)
    {
        MovingAttackCertainDistance = 2000;
    }

    MovingAttackChance = class'Utils'.static.FRatio(MovingAttackChance);
}

/**
 * For some reason original function used to
 * explicitly override HuskFireProjClass to class'KFChar.HuskFireProjectile'
 */
function SpawnTwoShots()
{
    local vector X,Y,Z, FireStart;
    local rotator FireRotation;
    local KFMonsterController KFMonstControl;

    if (Controller == None ||
        IsInState('GettingOutOfTheWayOfShot') ||
        Physics == PHYS_Falling)
    {
        return;
    }

    if (KFDoorMover(Controller.Target) != None)
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
    FireRotation = Controller.AdjustAim(SavedFireProperties, FireStart, 100);

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
    local float NextFireTimeCooldown, MovingAttackChanceByDistance;

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

        if (MovingAttackChance == 0)
            MovingAttackChanceByDistance = 0;
        else if (MovingAttackChance == 1 || MovingAttackCertainDistance <= VSize(A.Location - Location))
            MovingAttackChanceByDistance = 1.0;
        else
            MovingAttackChanceByDistance = class'Utils'.static.FRatio(VSize(A.Location - Location) / float(MovingAttackCertainDistance));

        bMovingAttack = KFDoorMover(A) == None && class'Utils'.static.BChance(0.3 * MovingAttackChance + 0.7 * MovingAttackChanceByDistance);

        if (bMovingAttack)
        {
            SetAnimAction('ShootBurnsAndMove');
            bMovingAttack = False;
        }
        else
        {
            SetAnimAction('ShootBurns');
            Controller.bPreparingMove = True;
            Acceleration = vect(0, 0, 0);
        }

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
        ResetAnimActTime = Level.TimeSeconds + 0.3;
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

    // moving attack is interrupted by stunning
    if (ExpectingChannel == 1 && AnimName == 'KnockDown')
    {
        PlayAnim(AnimName,, 0.1, 1);
        AnimBlendParams(1, 1.0, 0.0,,, True);
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

    if (TestAnim == 'KnockDown')
    {
        return True;
    }

    return super.AnimNeedsWait(TestAnim);
}

defaultProperties
{
    CustomMenuName="N7 Husk"
    GroundSpeed=95.000000
    WaterSpeed=85.000000
    MinFireInterval=2.000000
    MaxFireInterval=4.000000
    MovingAttackChance=0.500000
    MovingAttackCertainDistance=2000
    HuskFireProjClass=class'N7_HuskFireProjectile'
}
