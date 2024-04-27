class N7_Gorefast extends KFChar.ZombieGorefast_STANDARD
    config(N7ZedsMut);

var const int RageDistance;
var const float ChargeSpeedModifier;
var float ChargeGroundSpeed;

var config string CustomMenuName;

replication {
    reliable if (Role == ROLE_AUTHORITY)
        CustomMenuName;
}

simulated event PostBeginPlay()
{
    super(KFMonster).PostBeginPlay();

    ChargeGroundSpeed = OriginalGroundSpeed * ChargeSpeedModifier;
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

function RangedAttack(Actor A)
{
    super(KFMonster).RangedAttack(A);

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
        return False;
    }

    function RangedAttack(Actor A)
    {
        local bool bDoRangedAttack;
        bDoRangedAttack = CanAttack(A) && !bShotAnim && Physics != PHYS_Swimming;

        if (bDoRangedAttack)
        {
            bShotAnim = True;
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

        global.Tick(DeltaTime);
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

defaultProperties
{
    CustomMenuName="N7 Gorefast"
    ChargeSpeedModifier=1.875
    GroundSpeed=140.000000
    RageDistance=1000
}
