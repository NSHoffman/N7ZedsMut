class N7_Siren extends KFChar.ZombieSiren_STANDARD;

/* Shooting the siren can't interrupt her screaming */
simulated function bool HitCanInterruptAction()
{
    return !bShotAnim;
}

simulated function HurtRadius(
    float DamageAmount, 
    float DamageRadius, 
    class<DamageType> DamageType, 
    float Momentum, 
    vector HitLocation)
{
    local Actor Victim;
    local Vector Dir;
    local float DamageScale, Dist, UsedDamageAmount;

    if (bHurtEntry)
        return;

    bHurtEntry = True;

    foreach VisibleCollidingActors(class'Actor', Victim, DamageRadius, HitLocation)
    {
        if (
            Victim != self && 
            !Victim.IsA('FluidSurfaceInfo') && 
            !Victim.IsA('KFMonster') && 
            !Victim.IsA('ExtendedZCollision'))
        {
            Dir = Victim.Location - HitLocation;
            Dist = FMax(1, VSize(Dir));
            Dir = Dir / Dist;

            DamageScale = 1 - FMax(0, (Dist - Victim.CollisionRadius) / DamageRadius);

            if (!Victim.IsA('KFHumanPawn')) // If it aint human, don't pull the vortex crap on it.
                Momentum = 0;

            if (Victim.IsA('KFGlassMover'))   // Hack for shattering in interesting ways.
                UsedDamageAmount = 100000;
            else
                UsedDamageAmount = DamageAmount;

            if (!DisintegrateExplosive(Victim, HitLocation))
            {
                Victim.TakeDamage(
                    DamageScale * UsedDamageAmount, 
                    Instigator, 
                    Victim.Location - 0.5 * (Victim.CollisionHeight + Victim.CollisionRadius) * Dir,
                    (DamageScale * Momentum * Dir), 
                    DamageType
                );
            }

            if (Instigator != None && Vehicle(Victim) != None && Vehicle(Victim).Health > 0)
            {
                Vehicle(Victim).DriverRadiusDamage(
                    UsedDamageAmount, 
                    DamageRadius, 
                    Instigator.Controller, 
                    DamageType, 
                    Momentum, 
                    HitLocation
                );
            }
        }
    }

    bHurtEntry = False;
}

/**
 * Explosive projectiles' source code explicitly states class'SirenScreamDamage' 
 * as damage type which causes disintegration thus preventing any derived damage type
 * from behaving the same way. This hack is supposed to fix the issue.
 */
function bool DisintegrateExplosive(Actor Explosive, Vector HitLocation)
{
    if (LAWProj(Explosive) != None)
    {
        LAWProj(Explosive).Disintegrate(HitLocation, vect(0, 0, 1));
        return True;
    }

    else if (M79GrenadeProjectile(Explosive) != None)
    {
        M79GrenadeProjectile(Explosive).Disintegrate(HitLocation, vect(0, 0, 1));
        return True;
    }

    else if (Nade(Explosive) != None)
    {
        Nade(Explosive).Disintegrate(HitLocation, vect(0, 0, 1));
        return True;
    }

    else if (PipeBombProjectile(Explosive) != None)
    {
        PipeBombProjectile(Explosive).Disintegrate(HitLocation, vect(0, 0, 1));
        return True;
    }

    else if (SealSquealProjectile(Explosive) != None)
    {
        SealSquealProjectile(Explosive).Disintegrate(HitLocation, vect(0, 0, 1));
        return True;
    }

    else if (SeekerSixRocketProjectile(Explosive) != None)
    {
        SeekerSixRocketProjectile(Explosive).Disintegrate(HitLocation, vect(0, 0, 1));
        return True;
    }

    else if (SPGrenadeProjectile(Explosive) != None)
    {
        SPGrenadeProjectile(Explosive).Disintegrate(HitLocation, vect(0, 0, 1));
        return True;
    }

    return False;
}

static simulated function PreCacheMaterials(LevelInfo myLevel)
{
    myLevel.AddPrecacheMaterial(Combiner'KF_Specimens_Trip_N7.siren_cmb');
    myLevel.AddPrecacheMaterial(Combiner'KF_Specimens_Trip_N7.siren_env_cmb');
    myLevel.AddPrecacheMaterial(Texture'KF_Specimens_Trip_N7.siren_diffuse');
    myLevel.AddPrecacheMaterial(Texture'KF_Specimens_Trip_N7.siren_hair');
    myLevel.AddPrecacheMaterial(Material'KF_Specimens_Trip_N7.siren_hair_fb');
}

defaultProperties
{
    MenuName="N7 Siren"
    ShakeEffectScalar=4.500000
    MinShakeEffectScale=3.250000
    ScreamDamageType=class'N7_SirenScreamDamage'
    DetachedLegClass=class'N7_SeveredLegSiren'
    DetachedHeadClass=class'N7_SeveredHeadSiren'
    Skins(0)=FinalBlend'KF_Specimens_Trip_N7.siren_hair_fb'
    Skins(1)=Combiner'KF_Specimens_Trip_N7.siren_cmb'
}
