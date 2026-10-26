fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'dps-crossings'
author 'DelPerroSands'
version '0.1.0'
description 'Level crossings for the Roxwood lines: drops the arms, reds the signals and holds traffic while a train passes'

shared_script '@ox_lib/init.lua'

client_scripts {
    'config.lua',
    'client.lua',
}
