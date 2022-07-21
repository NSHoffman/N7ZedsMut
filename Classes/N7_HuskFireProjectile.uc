class N7_HuskFireProjectile extends KFChar.HuskFireProjectile;

/* Based on Engine.Projectile.Touch */
simulated singular function Touch(Actor Other)
{
	local vector HitLocation, HitNormal;

	if (Other == None || !(Other.bProjTarget || Other.bBlockActors))
		return;

    LastTouched = Other;
    if (Velocity == vect(0,0,0) || Other.IsA('Mover'))
    {
        ProcessTouch(Other,Location);
        LastTouched = None;
        return;
    }

    if (Other.TraceThisActor(HitLocation, HitNormal, Location, Location - 2*Velocity, GetCollisionExtent()))
    {
        HitLocation = Location;
    }

    ProcessTouch(Other, HitLocation);
    LastTouched = None;

    if ((Role < ROLE_Authority) && (Other.Role == ROLE_Authority) && (Pawn(Other) != None))
    {
        ClientSideTouch(Other, HitLocation);
    }
}

/* Based on KFMod.LAWProj.ProcessTouch */
simulated function ProcessTouch(Actor Other, Vector HitLocation)
{
    if (
        Other == None 
        || Other == Instigator 
        || Other.Base == Instigator
        || Other.IsA('KFMonster') // Taken from SuperZombieMut
        || KFBulletWhipAttachment(Other) != None
    ) {
		return;
    }

	if (Instigator != None)
	{
		OrigLoc = Instigator.Location;
	}

	if (!bDud)
	{
        if ((VSizeSquared(Location - OrigLoc) < ArmDistSquared) || OrigLoc == vect(0,0,0))
        {
            if (Role == ROLE_Authority)
            {
                AmbientSound=none;
                PlaySound(Sound'ProjectileSounds.PTRD_deflect04',, 2.0);
                Other.TakeDamage(ImpactDamage, Instigator, HitLocation, Normal(Velocity), ImpactDamageType);
            }

            bDud = true;
            Velocity = vect(0,0,0);
            LifeSpan = 1.0;
            SetPhysics(PHYS_Falling);
        }
        Explode(HitLocation, Normal(HitLocation - Other.Location));
	}
}

defaultProperties
{
    Damage=30.000000
    DamageRadius=200.000000
    MaxSpeed=3000.000000
    Speed=2500.000000
}