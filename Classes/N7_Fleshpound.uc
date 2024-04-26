class N7_Fleshpound extends N7_FleshpoundGlowing
    config(N7ZedsMut);

var config string CustomMenuName;

var config int RageStopDistance;
var config float RageStopAfterKillChance;

replication {
    reliable if (Role == ROLE_AUTHORITY)
        CustomMenuName;
}

simulated function PostBeginPlay()
{
    super.PostBeginPlay();

    RageStopDistance = Max(0, RageStopDistance);
    RageStopAfterKillChance = class'Utils'.static.FRatio(RageStopAfterKillChance);
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

state RageCharging
{
ignores StartCharging;

    function BeginState()
    {
        local float DifficultyModifier;

        if (!bZapped)
        {
            bChargingPlayer = True;

            if (Level.NetMode != NM_DedicatedServer)
                ClientChargingAnims();

            if (Level.Game.GameDifficulty < 2.0)
                DifficultyModifier = 1.00;
            else if (Level.Game.GameDifficulty < 4.0)
                DifficultyModifier = 1.5;
            else if (Level.Game.GameDifficulty < 5.0)
                DifficultyModifier = 2.0;
            else
                DifficultyModifier = 3.0;

            RageEndTime = (Level.TimeSeconds + 5 * DifficultyModifier) + (FRand() * 6 * DifficultyModifier);
            NetUpdateTime = Level.TimeSeconds - 1;
        }
        else
        {
            GoToState('');
        }
    }

    function Tick(float Delta)
    {
        if (!bShotAnim)
        {
            SetGroundSpeed(OriginalGroundSpeed * 2.3);

            if (!bFrustrated && !bZedUnderControl && LookTarget != None &&
                Level.TimeSeconds > RageEndTime && VSize(LookTarget.Location - Location) > RageStopDistance)
            {
                GoToState('');
            }
        }

        if (Role == ROLE_Authority && bShotAnim)
        {
            if (LookTarget != None)
            {
                Acceleration = AccelRate * Normal(LookTarget.Location - Location);
            }
        }

        global.Tick(Delta);
    }

    function bool MeleeDamageTarget(int HitDamage, Vector PushDir)
    {
        local bool bHit, bEnemyPawn;
        local Pawn PawnTarget;

        bEnemyPawn = Controller.Target == Controller.Enemy;

        if (bEnemyPawn)
            PawnTarget = Pawn(Controller.Target);

        bHit = super(KFMonster).MeleeDamageTarget(HitDamage * 1.75, PushDir * 3);

        // A chance FP will settle down when the target is dead
        if (bHit && bEnemyPawn &&
            PawnTarget != None && PawnTarget.Health <= 0 && class'Utils'.static.BChance(RageStopAfterKillChance))
            GoToState('');

        return bHit;
    }

    function DoorAttack(Actor A)
    {
        if (bShotAnim || Physics == PHYS_Swimming)
            return;

        if (A != None)
        {
            bShotAnim = True;
            Controller.Target = A;

            SetAnimAction('DoorBash');
        }
    }
}

simulated function PostNetReceive()
{
    if (bClientCharge != bChargingPlayer && !bZapped)
    {
        bClientCharge = bChargingPlayer;

        if (bChargingPlayer)
        {
            MovementAnims[0] = ChargingAnim;
            DeviceGoRed();
        }
        else
        {
            MovementAnims[0] = default.MovementAnims[0];
            DeviceGoNormal();
        }
    }
}

defaultProperties
{
    CustomMenuName="N7 Fleshpound"
    RageStopDistance=750
    RageStopAfterKillChance=0.340000
}
