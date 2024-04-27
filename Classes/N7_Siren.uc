class N7_Siren extends KFChar.ZombieSiren_STANDARD
    config(N7ZedsMut);

var config string CustomMenuName;
var config bool bUseCustomDamageType;

replication {
    reliable if (Role == ROLE_AUTHORITY)
        CustomMenuName;
}

simulated function PostBeginPlay()
{
    super.PostBeginPlay();

    if (bUseCustomDamageType)
        ScreamDamageType = class'N7_SirenScreamDamage';
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

/* Shooting the siren can't interrupt her screaming */
simulated function bool HitCanInterruptAction()
{
    return !bShotAnim;
}

simulated function SpawnTwoShots()
{
    // No scream damage when decapitated
    if (bZapped || bDecapitated)
    {
        return;
    }

    DoShakeEffect();

    if (Level.NetMode != NM_Client)
    {
        // Deal Actual Damage.
        if (Controller != None && KFDoorMover(Controller.Target) != None)
        {
            Controller.Target.TakeDamage(ScreamDamage * 0.6, self, Location, vect(0, 0, 0), ScreamDamageType);
        }
        else HurtRadius(ScreamDamage, ScreamRadius, ScreamDamageType, ScreamForce, Location);
    }
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
            else Momentum = ScreamForce; // bugfix, when pull wasn't applied always -- PooSH

            if (Victim.IsA('KFGlassMover'))   // Hack for shattering in interesting ways.
                UsedDamageAmount = 100000;
            else
                UsedDamageAmount = DamageAmount;

            if (!bUseCustomDamageType || !DisintegrateExplosive(Victim, HitLocation))
            {
                Victim.TakeDamage(
                    DamageScale * UsedDamageAmount,
                    self,
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

defaultProperties
{
    CustomMenuName="N7 Siren"
    ShakeEffectScalar=1.500000
    MinShakeEffectScale=0.900000
    bUseCustomDamageType=True
}
