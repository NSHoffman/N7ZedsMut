class N7_Fleshpound extends N7_FleshpoundGlowing;

state RageCharging
{
    Ignores StartCharging;

    function BeginState()
    {
        if (!bZapped) 
        {
            bChargingPlayer = True;

            if (Level.NetMode != NM_DedicatedServer)
            {
                ClientChargingAnims();
            }

            NetUpdateTime = Level.TimeSeconds - 1;
        }
        else 
        {
            GoToState('');
        }
    }

    function Tick(float DeltaTime)
    {
        if (!bShotAnim) 
        {
            SetGroundSpeed(OriginalGroundSpeed * 2.3);
        }

        // Keep the flesh pound moving toward its target when attacking
        if (Role == ROLE_Authority && bShotAnim && LookTarget != None) 
        {
            Acceleration = AccelRate * Normal(LookTarget.Location - Location);
        }

        global.Tick(DeltaTime);
    }

    // Even hitting a target won't settle raged FP down
    function bool MeleeDamageTarget(int hitdamage, vector pushdir)
    {
        return super(KFMonster).MeleeDamageTarget(hitdamage * 1.75, pushdir * 3);
    }
}

/**
 * State where the zed is charging to a marked location.
 * Not sure if we need this since its just like RageCharging,
 * but keeping it here for now in case we need to implement some
 * custom behavior for this state
 */ 
state ChargeToMarker {
    Ignores StartCharging;

    function Tick(float DeltaTime)
    {
        if (!bShotAnim) 
        {
            SetGroundSpeed(OriginalGroundSpeed * 2.3);
        }

        // Keep the flesh pound moving toward its target when attacking
        if (Role == ROLE_Authority && bShotAnim && LookTarget != None) 
        {
            Acceleration = AccelRate * Normal(LookTarget.Location - Location);
        }

        global.Tick(DeltaTime);
    }
}

simulated function PostNetReceive()
{
    if (bClientCharge != bChargingPlayer && !bZapped)
    {
        bClientCharge = bChargingPlayer;

        if (bChargingPlayer)
        {
            MovementAnims[0] = ChargingAnim;
            DeviceGoRed();
        }
        else
        {
            MovementAnims[0] = default.MovementAnims[0];
            DeviceGoNormal();
        }
    }
}

static simulated function PreCacheMaterials(LevelInfo myLevel)
{
    myLevel.AddPrecacheMaterial(Combiner'KF_Specimens_Trip_N7.fleshpound_cmb');
    myLevel.AddPrecacheMaterial(Combiner'KF_Specimens_Trip_N7.fleshpound_env_cmb');
    myLevel.AddPrecacheMaterial(Texture'KF_Specimens_Trip_N7.fleshpound_diff');
}

defaultproperties
{
    MenuName="N7 Fleshpound"
    DetachedArmClass=class'N7_SeveredArmPound'
    DetachedLegClass=class'N7_SeveredLegPound'
    DetachedHeadClass=class'N7_SeveredHeadPound'
    Skins(0)=Combiner'KF_Specimens_Trip_N7.fleshpound_cmb'
}
