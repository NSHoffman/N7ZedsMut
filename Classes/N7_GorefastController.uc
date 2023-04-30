class N7_GorefastController extends KFChar.GorefastController;

state WaitForAnim
{
    function EndState() 
    {
        if (Pawn != None)
        {
            Pawn.AccelRate = Pawn.default.AccelRate;    
            /**
             * Prevent Gorefast from getting back to
             * its original ground speed after attacking 
             */
            if (!Pawn.IsInState('RunningState'))
            {
                Pawn.GroundSpeed = Pawn.default.GroundSpeed;
            }
        }
        bUseFreezeHack = False;
    }
}

defaultProperties
{
    StrafingAbility=0.7000000
}
