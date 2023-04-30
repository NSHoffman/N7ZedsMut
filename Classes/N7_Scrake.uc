class N7_Scrake extends KFChar.ZombieScrake_STANDARD;

var float ChargeGroundSpeed;

simulated event PostBeginPlay()
{
    super(KFMonster).PostBeginPlay();

    ChargeGroundSpeed = OriginalGroundSpeed * AttackChargeRate;
}

function RangedAttack(Actor A)
{
    if (bShotAnim || Physics == PHYS_Swimming)
        return;
    else if (CanAttack(A))
    {
        bShotAnim = True;
        SetAnimAction(MeleeAnims[Rand(2)]);
        CurrentDamType = ZombieDamType[0];
        GoToState('SawingLoop');
    }

    if (!bDecapitated && Controller.Enemy != None)
    {
        GotoState('RunningState');
    }
}

state RunningState
{
    simulated function Tick(float DeltaTime)
    {
        CheckAnimationAndGroundSpeed();
        super.Tick(DeltaTime);
    }

    /**
     * For some reason original scrake
     * can reset its movement animation to 'SawZombieWalk'
     * when just spawned within player's view
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
}

defaultProperties
{
    MenuName="N7 Scrake"
}
