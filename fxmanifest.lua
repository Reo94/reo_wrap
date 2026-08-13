--========================================================--
--                    REO WRAP SYSTEM                     --
--                    RESOURCE MANIFEST                   --
--========================================================--
fx_version 'cerulean'
game 'gta5'
author 'REO Development'
description 'Roleplay-focused WRAP restraint system for Qbox'
version '1.0.0'
shared_script '@ox_lib/init.lua'
shared_script 'config.lua'
client_script 'client/main.lua'
server_script 'server/main.lua'
dependencies { 'ox_lib', 'ox_inventory', 'ox_target', 'qbx_core' }
