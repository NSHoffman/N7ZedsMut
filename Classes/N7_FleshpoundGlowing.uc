class N7_FleshpoundGlowing extends KFChar.ZombieFleshpound_STANDARD;

var N7_FleshpoundLight TemperLight;

simulated function PostBeginPlay()
{
    TemperLight = Spawn(class'N7_FleshpoundLight', self);

    if (TemperLight != None) 
    {
        AttachToBone(TemperLight, SpineBone1);
        TemperLight.SetRelativeLocation(vect(5, -35, 0));
    }

    super.PostBeginPlay();
}

// changes colors on Device (notified in anim)
simulated function DeviceGoRed()
{
    super.DeviceGoRed();
    TemperLight.ChangeToRed();
}

simulated function DeviceGoNormal()
{
    super.DeviceGoNormal();
    TemperLight.ChangeToYellow();
}

simulated function Destroyed() {
    super.Destroyed();

    if (TemperLight != None) 
    {
        TemperLight.Destroy();
    }
}

defaultproperties
{}
