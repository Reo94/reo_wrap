--========================================================--
--                    REO WRAP SYSTEM                     --
--                     CONFIGURATION                      --
--========================================================--
Config = {}

--========================================================--
--                        DEBUG                           --
--========================================================--
Config.Debug = false
Config.EnableDevCommands = true

--========================================================--
--                       INVENTORY                        --
--========================================================--
Config.WrapItem = 'wrap_restraint'
Config.ConsumeWrap = true
Config.ReturnWrapOnRemoval = true

--========================================================--
--                      INTERACTION                       --
--========================================================--
Config.MaxDistance = 3.0
Config.TargetDistance = 2.5
Config.ApplyDuration = 5000
Config.RemoveDuration = 4000

--========================================================--
--                    ACCESS CONTROL                      --
--========================================================--
Config.AllowedJobs = { police = true, ambulance = true }
Config.RequireRestrainedTarget = true
Config.CuffedStateKeys = { 'isCuffed', 'handcuffed', 'cuffed' }
Config.IncapacitatedStateKeys = { 'isDead', 'dead', 'laststand', 'isLaststand', 'downed' }

--========================================================--
--                       ANIMATION                        --
--========================================================--
Config.WrappedAnim = {
    dict = 'anim@heists@fleeca_bank@ig_7_jetski_owner',
    clip = 'owner_idle',
    flag = 1
}

--========================================================--
--                    CONTROL LOCKOUTS                    --
--========================================================--
Config.DisableControls = {
    21, 22, 23, 24, 25, 37, 44, 45, 75,
    140, 141, 142, 143, 257, 263, 264
}
