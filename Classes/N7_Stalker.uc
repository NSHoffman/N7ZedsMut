class N7_Stalker extends KFChar.ZombieStalker_STANDARD;

simulated function Tick(float DeltaTime) 
{
    local bool bKeepAccelerationWhileAttacking;
    bKeepAccelerationWhileAttacking = LookTarget != None && bShotAnim && !bWaitForAnim;

    super.Tick(DeltaTime);

    if (Role == ROLE_Authority && bKeepAccelerationWhileAttacking) {
        Acceleration = AccelRate * Normal(LookTarget.Location - Location);
    }
}

function RangedAttack(Actor A)
{
    local bool bDoRangedAttack;
    bDoRangedAttack = CanAttack(A) && !(bShotAnim || Physics == PHYS_Swimming);

    if (bDoRangedAttack) {
        bShotAnim = true;
        SetAnimAction('ClawAndMove');
    }
}

/* Don't interrupt stalker when she's trying to attack */
simulated function bool HitCanInterruptAction()
{
    return !bShotAnim;
}

simulated event SetAnimAction(name NewAction)
{
    if (NewAction == '') {
        return;
    }

    ExpectingChannel = AttackAndMoveDoAnimAction(NewAction);
    
    bWaitForAnim = false;

    if (Level.NetMode != NM_Client) {
        AnimAction = NewAction;
        bResetAnimAct = true;
        ResetAnimActTime = Level.TimeSeconds + 0.3;
    }
}

simulated function int AttackAndMoveDoAnimAction(name AnimName)
{
    local int meleeAnimIndex;

    if (AnimName == 'ClawAndMove') {
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

    return super.DoAnimAction(AnimName);
}

defaultProperties
{
    MenuName="N7 Stalker"
    GroundSpeed=210.000000
    WaterSpeed=190.000000
}
