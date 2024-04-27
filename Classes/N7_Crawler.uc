class N7_Crawler extends KFChar.ZombieCrawler_STANDARD
    config(N7ZedsMut);

var config string CustomMenuName;

replication {
    reliable if (Role == ROLE_AUTHORITY)
        CustomMenuName;
}

simulated function PostBeginPlay()
{
    super.PostBeginPlay();

    PounceSpeed = 375 + Rand(125);
    MeleeRange = 75 + Rand(25);
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

defaultProperties
{
    CustomMenuName="N7 Crawler"
    GroundSpeed=180.00000
    WaterSpeed=160.00000
}
