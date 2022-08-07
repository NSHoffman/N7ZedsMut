class N7_HuskController extends KFChar.HuskZombieController;

var KFHumanPawn AvoidPlayer;

function AvoidThisPlayer(KFHumanPawn Feared)
{
    GoalString = "PLAYER AVOID!";
    AvoidPlayer = Feared;
    GotoState('PlayerAvoid');
}

state PlayerAvoid
{
    ignores EnemyNotVisible,SeePlayer,HearNoise;

    function AvoidThisPlayer(KFHumanPawn Feared)
    {
        GoalString = "AVOID PLAYER!";
        // Switch to the new guy if he is closer
        if (VSizeSquared(Pawn.Location - Feared.Location) < VSizeSquared(Pawn.Location - AvoidMonster.Location))
        {
            AvoidPlayer = Feared;
            BeginState();
        }
    }

    function BeginState()
    {
        SetTimer(0.4, true);
    }

    event Timer()
    {
        local vector Dir, Side;
        local float Dist;

        if (AvoidPlayer == None || AvoidPlayer.Velocity dot (Pawn.Location - AvoidPlayer.Location) < 0)
        {
            WhatToDoNext(11);
            return;
        }

        Pawn.bIsWalking = false;
        Pawn.bWantsToCrouch = false;
        Dir = Pawn.Location - AvoidPlayer.Location;
        Dist = VSize(Dir);

        if (Dist <= AvoidPlayer.CollisionRadius * NearMult)
        {
            HitTheDirt();
        }
        else if (Dist < AvoidPlayer.CollisionRadius * FarMult)
        {
            Side = Dir cross vect(0,0,1);

            // pick the shortest direction to move to
            if (Side dot AvoidPlayer.Velocity > 0)
                Destination = Pawn.Location + (-Normal(Side) * (AvoidPlayer.CollisionRadius * FarMult));
            else
                Destination = Pawn.Location + (Normal(Side) * AvoidPlayer.CollisionRadius * FarMult);
        }
    }

    function HitTheDirt()
    {
        local vector Dir, Side;

        GoalString = "AVOID Player!   Jumping!!!";
        Dir = Pawn.Location - AvoidPlayer.Location;
        Side = Dir cross vect(0,0,1);
        Pawn.Velocity = Pawn.AccelRate * Normal(Side);

        // jump the other way if its shorter
        if (Side dot AvoidPlayer.Velocity > 0)
        {
            Pawn.Velocity = -Pawn.Velocity;
        }
        Pawn.Velocity.Z = Pawn.JumpZ;
        bPlannedJump = true;
        Pawn.SetPhysics(PHYS_Falling);
    }

    function EndState()
    {
        bTimerLoop = false;
        AvoidPlayer = None;
        Focus = None;
    }

Begin:
    WaitForLanding();
    MoveTo(Destination, AvoidPlayer, false);
    if (
        AvoidPlayer == None 
        || VSize(Pawn.Location - AvoidPlayer.Location) > AvoidPlayer.CollisionRadius * FarMult 
        || AvoidPlayer.Velocity dot (Pawn.Location - AvoidPlayer.Location) < 0
    ) {
        WhatToDoNext(11);

        warn("!! " @ Pawn.GetHumanReadableName() @ " STUCK IN AVOID PLAYER !!");
        GoalString = "!! STUCK IN AVOID PLAYER !!";
    }
    Sleep(0.2);
    GoTo('Begin');
}

defaultProperties
{
}
