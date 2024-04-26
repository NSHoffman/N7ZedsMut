class N7_FleshpoundGlowing extends KFChar.ZombieFleshpound_STANDARD;

var N7_FleshpoundLight TemperLight;

simulated function PostBeginPlay()
{
    super.PostBeginPlay();

    if (Level.NetMode != NM_DedicatedServer)
    {
        TemperLight = Spawn(class'N7_FleshpoundLight', self);

        if (TemperLight != None)
        {
            AttachToBone(TemperLight, SpineBone1);
            TemperLight.SetRelativeLocation(vect(5, -35, 0));
        }
    }
}

simulated function DeviceGoRed()
{
    super.DeviceGoRed();

    if (Level.NetMode != NM_DedicatedServer)
        TemperLight.ChangeToRed();
}

simulated function DeviceGoNormal()
{
    super.DeviceGoNormal();

    if (Level.NetMode != NM_DedicatedServer)
        TemperLight.ChangeToYellow();
}

simulated function Destroyed() {
    if (TemperLight != None)
        TemperLight.Destroy();

    super.Destroyed();
}

defaultProperties
{}
