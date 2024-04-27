class N7_BossController extends KFChar.BossZombieController;

// overridden from KFMonsterController
state ZombieHunt
{
    function PickDestination()
    {
        local bool bCanSeeLastSeen;
        local float PosZ;
        local Vector NextSpot, ViewSpot, Dir;
        local Actor TargetObstacle;

        ViewSpot = Pawn.Location + Pawn.BaseEyeHeight * vect(0, 0, 1);

        // if no enemies in sight, check for pipes and doors with nearby players
        if (!CanSee(Enemy) && N7_Boss(Pawn).FindVisibleObstacle(TargetObstacle))
        {
            N7_Boss(Pawn).AttackVisibleObstacle(TargetObstacle);
            WhatToDoNext(23);
            return;
        }

        if (Enemy != None && !KFM.bCannibal && Enemy.Health <= 0)
        {
            Enemy = None;
            WhatToDoNext(23);
            return;
        }

        if (PathFindState == 0)
        {
            InitialPathGoal = FindRandomDest();
            PathFindState = 1;
        }

        if (PathFindState == 1)
        {
            if (InitialPathGoal == None)
            {
                PathFindState = 2;
            }
            else if (ActorReachable(InitialPathGoal))
            {
                MoveTarget = InitialPathGoal;
                PathFindState = 2;
                return;
            }
            else if (FindBestPathToward(InitialPathGoal, True, True))
            {
                return;
            }
            else PathFindState = 2;
        }

        if (Pawn.JumpZ > 0)
            Pawn.bCanJump = True;

        if (ActorReachable(Enemy))
        {
            Destination = Enemy.Location;

            MoveTarget = None;
            return;
        }

        bCanSeeLastSeen = bEnemyInfoValid && FastTrace(LastSeenPos, ViewSpot);

        if (FindBestPathToward(Enemy, True, True))
            return;

        if (bSoaking && Physics != PHYS_Falling)
            SoakStop("COULDN'T FIND PATH TO ENEMY "$Enemy);

        MoveTarget = None;

        // -- not sure if the code below is relevant for patriarch
        // -- but leaving it untouched just in case

        if (!bEnemyInfoValid)
        {
            Enemy = None;
            GotoState('StakeOut');
            return;
        }

        Destination = LastSeeingPos;
        bEnemyInfoValid = False;

        if (FastTrace(Enemy.Location, ViewSpot) &&
            VSize(Pawn.Location - Destination) > Pawn.CollisionRadius)
        {
            SeePlayer(Enemy);
            return;
        }

        PosZ = LastSeenPos.Z + Pawn.CollisionHeight - Enemy.CollisionHeight;
        NextSpot = LastSeenPos - Normal(Enemy.Velocity) * Pawn.CollisionRadius;
        NextSpot.Z = PosZ;

        if (FastTrace(NextSpot, ViewSpot))
            Destination = NextSpot;

        else if (bCanSeeLastSeen)
        {
            Dir = Pawn.Location - LastSeenPos;
            Dir.Z = 0;

            if (VSize(Dir) < Pawn.CollisionRadius)
            {
                Destination = Pawn.Location + VRand() * 500;
                return;
            }
            Destination = LastSeenPos;
        }
        else
        {
            Destination = LastSeenPos;
            if (!FastTrace(LastSeenPos, ViewSpot))
            {
                // check if could adjust and see it
                if (PickWallAdjust(Normal(LastSeenPos - ViewSpot)) || FindViewSpot())
                {
                    if (Pawn.Physics == PHYS_Falling)
                        SetFall();
                    else
                        GotoState('Hunting', 'AdjustFromWall');
                }
                else
                {
                    Destination = Pawn.Location + VRand() * 500;
                    return;
                }
            }
        }
    }
}

defaultProperties {}
