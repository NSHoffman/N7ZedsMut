class N7_Fleshpound extends FPGlowMut.FleshpoundGlowing;

state RageCharging
{
    Ignores StartCharging;

	function BeginState()
	{
		if (!bZapped) 
        {
            bChargingPlayer = true;

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

        Global.Tick(DeltaTime);
	}

    // Even hitting a target won't settle raged FP down
	function bool MeleeDamageTarget(int hitdamage, vector pushdir)
	{
		return Super(KFMonster).MeleeDamageTarget(hitdamage * 1.75, pushdir * 3);
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

        Global.Tick(DeltaTime);
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

defaultproperties
{
    MenuName="N7 Fleshpound"
	DrawScale=1.050000
    GroundSpeed=155.000000
    WaterSpeed=145.000000
}
