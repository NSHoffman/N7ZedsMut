class N7ZedsMut extends Engine.Mutator
    config(N7ZedsMut);

#exec OBJ LOAD FILE=KF_Specimens_Trip_N7.utx
#exec OBJ LOAD FILE=KF_Specimens_Trip_N7_Two.utx
#exec OBJ LOAD FILE=kf_gore_n7_sm.usx

/**
 * @description if true - replaces default monsters collection
 * setting this to false might be useful if ZEDs replacement is handled somewhere else
 */
var() globalconfig bool bEnableIngameSpecimenReplacement;

function PostBeginPlay() {
    local KFGameType KFGT;

    if (!bEnableIngameSpecimenReplacement) 
    {
        return;
    }

    KFGT = KFGameType(Level.Game);

    if (KFGT == None) 
    {
        Destroy();
        return;
    }

    if (KFGT.MonsterCollection == Class'KFGameType'.default.MonsterCollection) 
    {
        KFGT.MonsterCollection = Class'N7ZedsMut.N7_MonstersCollection';
        KFGT.SpecialEventMonsterCollections[0] = Class'N7ZedsMut.N7_MonstersCollection';
        KFGT.FallbackMonsterClass = "N7ZedsMut.N7_Stalker";

        ReplaceMonsterClasses(KFGT.MonsterClasses, KFGT.MonsterCollection.default.MonsterClasses);
    }
}

function ReplaceMonsterClasses(out array<KFGameType.MClassTypes> InitialMonsterClasses, array<KFMonstersCollection.MClassTypes> NewMonsterClasses)
{
    local int i;

    for (i = 0; i < InitialMonsterClasses.Length; i++)
    {
        InitialMonsterClasses[i].MClassName = NewMonsterClasses[i].MClassName;
        InitialMonsterClasses[i].Mid = NewMonsterClasses[i].Mid;
    }
}

static function FillPlayInfo(PlayInfo PlayInfo) 
{
    local string N7ZedsConfig;
    N7ZedsConfig = "N7 Zeds Mutator Config";

    Super.FillPlayInfo(PlayInfo);

    PlayInfo.AddSetting(N7ZedsConfig, "bEnableIngameSpecimenReplacement", "Replace original ZEDs", 0, 0, "Check");
}

static event string GetDescriptionText(string property) 
{
    switch (property) 
    {
        case "bEnableIngameSpecimenReplacement": return "Enable replacement of original ZEDs to N7 Zeds";
        default: return Super.GetDescriptionText(property);
    }
}

defaultproperties 
{
    FriendlyName="N7 Zeds"
    Description="Adds some changes to zeds behaviour making them more aggressive"
    GroupName="KFN7ZedsMut"
    bEnableIngameSpecimenReplacement=true
}
