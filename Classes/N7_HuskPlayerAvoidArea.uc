/**
 * Husks must avoid approaching enemies
 */
class N7_HuskPlayerAvoidArea extends AvoidMarker;

/* Husk this area is attached to */
var KFMonster HuskMonster;

state BigMeanAndScary
{
Begin:
    StartleBots();
    Sleep(1.0);
    GoTo('Begin');
}

function InitFor(KFMonster M)
{
    Log("Entered Init, Husk:"@int(HuskMonster != None));
    if (M != None)
    {
        HuskMonster = M;
        SetCollisionSize(HuskMonster.CollisionRadius * 3, HuskMonster.CollisionHeight + CollisionHeight);
        SetBase(HuskMonster);
        Log("Init Complete, Husk:"@int(HuskMonster != None));
        GoToState('BigMeanAndScary');
    }
}

function Touch(Actor Other)
{   
    local KFHumanPawn HP;

    Log("Other:"@Other);
    HP = KFHumanPawn(Other);

    Log("Touched Avoid!");
    if (HP != None && HuskMonster != None && RelevantTo(HP))
    {
        Log("Got avoid");
        N7_HuskController(HuskMonster.Controller).AvoidThisPlayer(HP);
    }
}

function bool RelevantTo(Pawn P)
{
    Log("Checking for relevance..."@"Husk Exists:"@int(HuskMonster != None)@"Velocity check:"@int(VSizeSquared(P.Velocity) >= 75)@"Location check:"@int(P.Velocity dot (HuskMonster.Location - P.Location) > 0));
    return (
        HuskMonster != None
        && VSizeSquared(P.Velocity) >= 75 
        && P.Velocity dot (HuskMonster.Location - P.Location) > 0
    );
}

function StartleBots()
{
    local KFHumanPawn HP;

    if (HuskMonster != None) 
    {
        forEach CollidingActors(class'KFHumanPawn', HP, CollisionRadius)
        {
            if (RelevantTo(HP))
            {
                N7_HuskController(HuskMonster.Controller).AvoidThisPlayer(HP);
            }
        }
    }
}

defaultProperties
{
     CollisionRadius=1000.000000
     bBlockZeroExtentTraces=false
     bBlockNonZeroExtentTraces=false
     bBlockHitPointTraces=false
}
