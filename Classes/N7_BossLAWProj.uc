class N7_BossLAWProj extends KFChar.BossLAWProj;

#exec obj load file="KF_LAWSnd.uax"
#exec obj load file="KillingFloorStatics.usx"

static function PreloadAssets();
static function bool UnloadAssets()
{
	return True;
}

/** Removed damage reduction when there's only one player */
simulated function PostBeginPlay()
{
    if (Level.Game != None)
    {
        if (Level.Game.GameDifficulty < 2.0)
        {
            Damage = default.Damage * 0.375;
        }
        else if (Level.Game.GameDifficulty < 4.0)
        {
            Damage = default.Damage * 1.0;
        }
        else if (Level.Game.GameDifficulty < 5.0)
        {
            Damage = default.Damage * 1.15;
        }
        else
        {
            Damage = default.Damage * 1.3;
        }
    }

    super(LAWProj).PostBeginPlay();
}

/** Cannot be dud + No need to check for teams */
simulated function ProcessTouch(Actor Other, Vector HitLocation)
{
    if (Other == None || Other == Instigator || Other.Base == Instigator || KFBulletWhipAttachment(Other) != None)
    {
        return;
    }

    // Use the instigator's location if it exists. This fixes issues with
    // the original location of the projectile being really far away from
    // the real Origloc due to it taking a couple of milliseconds to
    // replicate the location to the client and the first replicated location has
    // already moved quite a bit.
    if (Instigator != None)
    {
        OrigLoc = Instigator.Location;
    }

    Explode(HitLocation, Normal(HitLocation - Other.Location));
}

/** Cannot be dud */
simulated function HitWall(vector HitNormal, actor Wall)
{
    // Use the instigator's location if it exists. This fixes issues with
    // the original location of the projectile being really far away from
    // the real Origloc due to it taking a couple of milliseconds to
    // replicate the location to the client and the first replicated location has
    // already moved quite a bit.
    if (Instigator != None)
    {
        OrigLoc = Instigator.Location;
    }

    super(Projectile).HitWall(HitNormal, Wall);
}

defaultProperties 
{
    ExplosionSound=SoundGroup'KF_LAWSnd.Rocket_Explode'
    StaticMesh=StaticMesh'KillingFloorStatics.LAWRocket'
    AmbientSound=Sound'KF_LAWSnd.Rocket_Propel'
}
