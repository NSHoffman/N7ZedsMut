class N7_Stalker_VIOLENT extends N7_Stalker;

/** 
 * The whole purpose of overriding the methods below
 * is to provide different material sources
 */

function RemoveHead()
{
    super.RemoveHead();

    if (!bCrispified)
    {
        Skins[1] = FinalBlend'KF_Specimens_Trip_N7.stalker_fb';
        Skins[0] = Combiner'KF_Specimens_Trip_N7.stalker_cmb';
    }
}

simulated function CloakStalker()
{
    if (bZapped)
    {
        return;
    }

    if (bSpotted)
    {
        if (Level.NetMode == NM_DedicatedServer)
            return;

        Skins[0] = Finalblend'KFX.StalkerGlow';
        Skins[1] = Finalblend'KFX.StalkerGlow';
        bUnlit = True;
        return;
    }

    if (!bDecapitated && !bCrispified)
    {
        Visibility = 1;
        bCloaked = True;

        if (Level.NetMode == NM_DedicatedServer)
            return;

        Skins[0] = Shader'KF_Specimens_Trip_N7.stalker_invisible';
        Skins[1] = Shader'KF_Specimens_Trip_N7.stalker_invisible';

        if (PlayerShadow != None)
            PlayerShadow.bShadowActive = False;
        if (RealTimeShadow != None)
            RealTimeShadow.Destroy();

        Projectors.Remove(0, Projectors.Length);
        bAcceptsProjectors = False;
        SetOverlayMaterial(Material'KFX.FBDecloakShader', 0.25, True);
    }
}

simulated function UnCloakStalker()
{
    if (bZapped)
    {
        return;
    }

    if (!bCrispified)
    {
        LastUncloakTime = Level.TimeSeconds;

        Visibility = default.Visibility;
        bCloaked = False;
        bUnlit = False;

        // 25% chance of our Enemy saying something about us being invisible
        if (
            Level.NetMode != NM_Client 
            && !KFGameType(Level.Game).bDidStalkerInvisibleMessage 
            && FRand() < 0.25 
            && Controller.Enemy != None 
            && PlayerController(Controller.Enemy.Controller) != None
        )
        {
            PlayerController(Controller.Enemy.Controller).Speech('AUTO', 17, "");
            KFGameType(Level.Game).bDidStalkerInvisibleMessage = True;
        }

        if (Level.NetMode == NM_DedicatedServer)
            return;

        if (Skins[0] != Combiner'KF_Specimens_Trip_N7.stalker_cmb')
        {
            Skins[1] = FinalBlend'KF_Specimens_Trip_N7.stalker_fb';
            Skins[0] = Combiner'KF_Specimens_Trip_N7.stalker_cmb';

            if (PlayerShadow != None)
                PlayerShadow.bShadowActive = True;

            bAcceptsProjectors = True;
            SetOverlayMaterial(Material'KFX.FBDecloakShader', 0.25, True);
        }
    }
}

simulated function SetZappedBehavior()
{
    super.SetZappedBehavior();

    bUnlit = False;

    // Handle setting the zed to uncloaked so the zapped overlay works properly
    if (Level.Netmode != NM_DedicatedServer)
    {
        Skins[1] = FinalBlend'KF_Specimens_Trip_N7.stalker_fb';
        Skins[0] = Combiner'KF_Specimens_Trip_N7.stalker_cmb';

        if (PlayerShadow != None)
            PlayerShadow.bShadowActive = True;

        bAcceptsProjectors = True;
        SetOverlayMaterial(Material'KFZED_FX_T.Energy.ZED_overlay_Hit_Shdr', 999, True);
    }
}

simulated function PlayDying(class<DamageType> DamageType, Vector HitLoc)
{
    super.PlayDying(DamageType, HitLoc);

    KillPseudoSquad();

    if (bUnlit)
        bUnlit = !bUnlit;

    LocalKFHumanPawn = None;

    if (!bCrispified)
    {
        Skins[1] = FinalBlend'KF_Specimens_Trip_N7.stalker_fb';
        Skins[0] = Combiner'KF_Specimens_Trip_N7.stalker_cmb';
    }
}

static simulated function PreCacheMaterials(LevelInfo myLevel)
{
    myLevel.AddPrecacheMaterial(Combiner'KF_Specimens_Trip_N7.stalker_cmb');
    myLevel.AddPrecacheMaterial(Combiner'KF_Specimens_Trip_N7.stalker_env_cmb');
    myLevel.AddPrecacheMaterial(Texture'KF_Specimens_Trip_N7.stalker_diff');
    myLevel.AddPrecacheMaterial(Texture'KF_Specimens_Trip_N7.stalker_spec');
    myLevel.AddPrecacheMaterial(Material'KF_Specimens_Trip_N7.stalker_invisible');
    myLevel.AddPrecacheMaterial(Combiner'KF_Specimens_Trip_N7.StalkerCloakOpacity_cmb');
    myLevel.AddPrecacheMaterial(Material'KF_Specimens_Trip_N7.StalkerCloakEnv_rot');
    myLevel.AddPrecacheMaterial(Material'KF_Specimens_Trip_N7.stalker_opacity_osc');
    myLevel.AddPrecacheMaterial(Material'KFCharacters.StalkerSkin');
}

defaultProperties
{
    DetachedArmClass=class'N7_SeveredArmStalker'
    DetachedLegClass=class'N7_SeveredLegStalker'
    DetachedHeadClass=class'N7_SeveredHeadStalker'
    Skins(0)=Shader'KF_Specimens_Trip_N7.stalker_invisible'
    Skins(1)=Shader'KF_Specimens_Trip_N7.stalker_invisible'
}
