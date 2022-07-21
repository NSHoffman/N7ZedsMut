class N7_Boss extends ZombieBoss_STANDARD;

// KFHardPat snippet
// Fix: Don't spawn needle before last stage.
simulated function NotifySyringeA()
{
	if (Level.NetMode != NM_Client)
	{
		if (SyringeCount < 3) {
			SyringeCount++;
        }

		if (Level.NetMode != NM_DedicatedServer) {
			PostNetReceive();
        }
	}

	if (Level.NetMode != NM_DedicatedServer) {
		DropNeedle();
    }
}

simulated function NotifySyringeC()
{
	if (Level.NetMode != NM_DedicatedServer)
	{
		CurrentNeedle = Spawn(Class'BossHPNeedle');
		CurrentNeedle.Velocity = vect(-45, 300, -90) >> Rotation;
		DropNeedle();
	}
}

/* Function body mostly copied from
 * class ZombieBoss.uc
 * As some changes require modifying core mechanics
 */
function TakeDamage(
    int Damage, 
    Pawn InstigatedBy, 
    Vector Hitlocation, 
    Vector Momentum, 
    class<DamageType> damageType, 
    optional int HitIndex
) {
	local KFHumanPawn P;

	local float DamagerDistSq;
	local float UsedPipeBombDamScale;

	local int NumPlayersSurrounding;

    local bool bCanDoRadialAttack;
	local bool bDidRadialAttack;

    if (ZombieBoss(InstigatedBy) != None) {
        return;
    }

    bCanDoRadialAttack = 
        Level.TimeSeconds - LastMeleeExploitCheckTime > 1.0 &&
        (
            class<DamTypeMelee>(damageType) != None ||
            class<KFProjectileWeaponDamageType>(damageType) != None
        );

    // Check for melee exploiters trying to surround the patriarch
    if (bCanDoRadialAttack)
    {
        LastMeleeExploitCheckTime = Level.TimeSeconds;
        NumLumberJacks = 0;
        NumNinjas = 0;

		foreach DynamicActors(class'KFHumanPawn', P)
		{
            // look for guys attacking us within 3 meters
            if (VSize(P.Location - Location) < 150)
            {
				NumPlayersSurrounding++;

                if (P != None && P.Weapon != None)
                {
                    if (Axe(P.Weapon) != None || Chainsaw(P.Weapon) != None)
                    {
                        NumLumberJacks++;
                    }
                    else if (Katana(P.Weapon) != None)
                    {
                        NumNinjas++;
                    }
                }

				if (!bDidRadialAttack && NumPlayersSurrounding >= 3)
                {
                    bDidRadialAttack = true;
                    GotoState('RadialAttack');
                    break;
                }
			}
		}
    }

    if (
        class<DamTypeCrossbow>(damageType) == None && 
        class<DamTypeCrossbowHeadShot>(damageType) == None
    ) {
    	bOnlyDamagedByCrossbow = false;
    }

    // Scale damage from the pipebomb down a bit if lots of pipe bomb damage happens
    // at around the same times. Prevent players from putting all thier pipe bombs
    // in one place and owning the patriarch in one blow.
	if (class<DamTypePipeBomb>(damageType) != None)
	{
	   UsedPipeBombDamScale = FMax(0, (1.0 - PipeBombDamageScale));

	   PipeBombDamageScale += 0.075;

	   if (PipeBombDamageScale > 1.0)
	   {
	       PipeBombDamageScale = 1.0;
	   }

	   Damage *= UsedPipeBombDamScale;
	}

    Super(KFMonster).TakeDamage(Damage,instigatedBy,hitlocation,Momentum,damageType);

    if (Level.TimeSeconds - LastDamageTime > 10)
    {
        ChargeDamage = 0;
    }
    else
    {
        LastDamageTime = Level.TimeSeconds;
        ChargeDamage += Damage;
    }

    if (ShouldChargeFromDamage() && ChargeDamage > 200)
    {
        // If someone close up is shooting us, just charge them
        if (InstigatedBy != None)
        {
            DamagerDistSq = VSizeSquared(Location - InstigatedBy.Location);

            if (DamagerDistSq < (700 * 700))
            {
                SetAnimAction('transition');
        		ChargeDamage=0;
        		LastForceChargeTime = Level.TimeSeconds;
        		GoToState('Charging');

        		return;
    		}
        }
    }

	if (
        Health<=0 || 
        SyringeCount==3 || 
        IsInState('Escaping') || 
        IsInState('KnockDown') || 
        IsInState('RadialAttack') || 
        bDidRadialAttack/*|| bShotAnim*/ 
    ) {
	    return;
    }

	if (
        (SyringeCount == 0 && Health < HealingLevels[0]) || 
        (SyringeCount == 1 && Health < HealingLevels[1]) || 
        (SyringeCount == 2 && Health < HealingLevels[2]) 
    ) {
	    //log(GetStateName()$" Took damage and want to heal!!! Health="$Health$" HealingLevels "$HealingLevels[SyringeCount]);
    	bShotAnim = true;
		Acceleration = vect(0, 0, 0);
		SetAnimAction('KnockDown');
		HandleWaitForAnim('KnockDown');
		KFMonsterController(Controller).bUseFreezeHack = true;

		GoToState('KnockDown');
	}
}

function PlayPatriarchSaveMe() {
    PlaySound(sound'KF_EnemiesFinalSnd.Patriarch.Kev_SaveMe', SLOT_Misc, 2.0,,500.0);
}

state KnockDown 
{
    Begin:
        if (Health > 0)
        {
            Sleep(GetAnimDuration('KnockDown'));
            CloakBoss();
            PlayPatriarchSaveMe();

            if (KFGameType(Level.Game).FinalSquadNum == SyringeCount) {
                KFGameType(Level.Game).AddBossBuddySquad();
            }

            GotoState('Escaping');
        }
        else
        {
            GotoState('');
        }
}

defaultProperties
{
    MenuName="N7 Patriarch"
}