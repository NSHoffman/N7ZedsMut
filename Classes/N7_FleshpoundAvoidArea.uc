/**
 * Credits to Shtoyan for the fleshpound spin fix
 * https://github.com/InsultingPros/FPSpinMut/blob/main/Classes/NewAvoidMarker.uc
 */
class N7_FleshpoundAvoidArea extends KFMod.FleshpoundAvoidArea;

// added KFMonsterController check -- Shtoyan
function Touch(actor Other)
{
    if ((Pawn(Other) != None) && KFMonsterController(Pawn(Other).Controller) != None && RelevantTo(Pawn(Other)))
    {
        KFMonsterController(Pawn(Other).Controller).AvoidThisMonster(KFMonst);
    }
}

// added health check, 1500 is FP's base health -- Shtoyan
function bool RelevantTo(Pawn P)
{
    local KFMonster M;

    M = KFMonster(P);

    if (M != None && M.default.Health >= 1500)
        return False;

    return (
        KFMonst != None && 
        VSizeSquared(KFMonst.Velocity) >= 75 && 
        super(AvoidMarker).RelevantTo(P) && 
        KFMonst.Velocity dot (P.Location - KFMonst.Location) > 0
    );
}

defaultProperties {}
