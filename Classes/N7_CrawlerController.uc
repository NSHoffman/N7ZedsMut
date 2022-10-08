class N7_CrawlerController extends KFChar.CrawlerController;

function bool FireWeaponAt(Actor A)
{
    local bool bReadyToPounce;
    local bool bTargetInSight;

    local vector aFacing, aToB;
    local float RelativeDir;

    if (A == None) {
        A = Enemy;
    }
    
    if ((A == None) || (Focus != A)) {
        return False;
    }

    if (CanAttack(A)) {
        Target = A;
        Monster(Pawn).RangedAttack(Target);
    } else {
        bReadyToPounce = LastPounceTime < Level.TimeSeconds;

        if (bReadyToPounce) {
            aFacing = Normal(Vector(Pawn.Rotation));
            
            // Get the vector from A to B
            aToB = A.Location - Pawn.Location;

            RelativeDir = aFacing dot aToB;
            bTargetInSight = RelativeDir > 0.85;

            if (bTargetInSight) {
                // Facing enemy
                if (IsInPounceDist(A) && ZombieCrawler(Pawn).DoPounce()) {
                    LastPounceTime = Level.TimeSeconds;
                }
            }
        }
    }
    return False;
}

defaultProperties 
{}
