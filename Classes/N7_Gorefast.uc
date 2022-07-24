class N7_Gorefast extends KFChar.ZombieGorefast_STANDARD;

var const int RageDistance;
var const float ChargeSpeedModifier;
var float ChargeGroundSpeed;

event PostBeginPlay()
{
    Super(KFMonster).PostBeginPlay();
    ChargeGroundSpeed = OriginalGroundSpeed * ChargeSpeedModifier;
}

function RangedAttack(Actor A)
{
    Super(KFMonster).RangedAttack(A);

    if (
        !bShotAnim && 
        !bDecapitated && 
        VSize(A.Location - Location) <= RageDistance
    ) {
        GoToState('RunningState');
    }
}

state RunningState
{
    function bool CanSpeedAdjust()
    {
        return false;
    }

    function RangedAttack(Actor A)
    {
        local bool bDoRangedAttack;
        bDoRangedAttack = CanAttack(A) && !bShotAnim && Physics != PHYS_Swimming;

        if (bDoRangedAttack)
        {
            bShotAnim = true;
            SetAnimAction('ClawAndMove');
        }
    }

    /* Don't interrupt gorefast when he's trying to attack */
    simulated function bool HitCanInterruptAction()
    {
        return !bShotAnim;
    }

    simulated function Tick(float DeltaTime)
    {
        local bool bKeepAccelerationWhileAttacking;
        bKeepAccelerationWhileAttacking = LookTarget != None && bShotAnim && !bWaitForAnim;

        CheckAnimationAndGroundSpeed();
        if (Role == ROLE_Authority && bKeepAccelerationWhileAttacking)
        {
            Acceleration = AccelRate * Normal(LookTarget.Location - Location);
        }

        Global.Tick(DeltaTime);
    }

    /**
     * For some reason original gorefast
     * can reset its movement animation to 'GoreWalk'
     * when just spawned within player's view and own rage distance
     * for reasons unknown it's not reproducible on GameDifficulty == 1.0
     */
    final function CheckAnimationAndGroundSpeed()
    {
        if (!bZapped && GroundSpeed < ChargeGroundSpeed)
        {
            SetGroundSpeed(ChargeGroundSpeed);
        }
        PostNetReceive();
    }

Begin:
    GoTo('CheckCharge');
CheckCharge:
    if (
        Controller != None && 
        Controller.Target != None &&
        VSize(Controller.Target.Location - Location) < RageDistance
    ) {
        Sleep(0.5 + FRand() * 0.5);
        GoTo('CheckCharge');
    }
    else {
        GoToState('');
    }
}

static simulated function PreCacheMaterials(LevelInfo myLevel)
{
    myLevel.AddPrecacheMaterial(Combiner'KF_Specimens_Trip_N7.gorefast_cmb');
    myLevel.AddPrecacheMaterial(Combiner'KF_Specimens_Trip_N7.gorefast_env_cmb');
    myLevel.AddPrecacheMaterial(Texture'KF_Specimens_Trip_N7.gorefast_diff');
}

defaultProperties
{
    MenuName="N7 Gorefast"
    ChargeSpeedModifier=1.875
    GroundSpeed=140.000000
    RageDistance=1000
    ControllerClass=Class'N7ZedsMut.N7_GorefastController'
    DetachedArmClass=Class'N7ZedsMut.N7_SeveredArmGorefast'
    DetachedLegClass=Class'N7ZedsMut.N7_SeveredLegGorefast'
    DetachedHeadClass=Class'N7ZedsMut.N7_SeveredHeadGorefast'
    Skins(0)=Combiner'KF_Specimens_Trip_N7.gorefast_cmb'
}
