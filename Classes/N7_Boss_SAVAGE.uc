class N7_Boss_SAVAGE extends N7_Boss;

/** 
 * The whole purpose of overriding the method below
 * is to provide different material sources
 */

simulated function CloakBoss()
{
    local Controller C;
    local int index;

    if (bZapped)
    {
        return;
    }

    if (bSpotted)
    {
        Visibility = 120;

        if (Level.NetMode == NM_DedicatedServer)
        {
            return;
        }

        Skins[0] = Finalblend'KFX.StalkerGlow';
        Skins[1] = Finalblend'KFX.StalkerGlow';
        bUnlit = True;
        return;
    }

    Visibility = 1;
    bCloaked = True;
    if (Level.NetMode != NM_Client)
    {
        for (C = Level.ControllerList; C != None; C = C.NextController)
        {
            if (C.bIsPlayer && C.Enemy == self)
            {
                C.Enemy = None;
            }
        }
    }

    if (Level.NetMode == NM_DedicatedServer)
    {
        return;
    }

    Skins[0] = Shader'KF_Specimens_Trip_N7.patriarch_invisible_gun';
    Skins[1] = Shader'KF_Specimens_Trip_N7.patriarch_invisible';

    if (PlayerShadow != None)
    {
        PlayerShadow.bShadowActive = False;
    }
    Projectors.Remove(0, Projectors.Length);
    bAcceptsProjectors = False;

    if (FRand() < 0.10)
    {
        index = Rand(Level.Game.NumPlayers);

        for (C = Level.ControllerList; C != None; C = C.NextController)
        {
            if (PlayerController(C) != None)
            {
                if (index == 0)
                {
                    PlayerController(C).Speech('AUTO', 8, "");
                    break;
                }
                index--;
            }
        }
    }
}

defaultProperties
{
    DetachedArmClass=class'N7_SeveredArmPatriarch'
    DetachedLegClass=class'N7_SeveredLegPatriarch'
    DetachedHeadClass=class'N7_SeveredHeadPatriarch'
    DetachedSpecialArmClass=class'N7_SeveredRocketArmPatriarch'
    Skins(0)=Combiner'KF_Specimens_Trip_N7.gatling_cmb'
    Skins(1)=Combiner'KF_Specimens_Trip_N7.patriarch_cmb'
}
