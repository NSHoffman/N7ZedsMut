class N7_Siren extends KFChar.ZombieSiren_STANDARD;

/* Shooting the siren can't interrupt her screaming */
simulated function bool HitCanInterruptAction()
{
    return !bShotAnim;
}

defaultProperties
{
    MenuName="N7 Siren"
    ShakeEffectScalar=4.500000
    MinShakeEffectScale=3.250000
    ScreamRadius=1000
    ScreamDamageType=Class'N7ZedsMut.N7_SirenScreamDamage'
}