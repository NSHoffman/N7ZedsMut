class N7_Clot extends KFChar.ZombieClot_STANDARD
    config(N7ZedsMut);

var config string CustomMenuName;

replication {
    reliable if (Role == ROLE_AUTHORITY)
        CustomMenuName;
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
    CustomMenuName="N7 Clot"
    GroundSpeed=115.000000
    WaterSpeed=115.000000
}
