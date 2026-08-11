fx_version 'cerulean'
game 'gta5'

name 'Pulsar Mdt'
description 'Police Mobile Data Terminal'
author 'Artmines - maintained for Pulsar Framework'
url 'https://pulsarframe.work'
version 'v1.0.2'

version_check 'yes'
github 'https://github.com/PulsarFW/pulsar_mdt'

client_script '@pulsar_core/components/cl_error.lua'
shared_script '@pulsar_core/core/sh_pulsar.lua'
client_script '@pulsar_pwnzor/client/check.lua'
server_script '@oxmysql/lib/MySQL.lua'

client_scripts({ 
    "client/**/*.lua" 
})
server_scripts({ 
    "config/utils/*.lua", 
    "server/**/*.lua" 
})

ui_page 'ui/dist/index.html'
files({ "ui/dist/index.html", "ui/dist/assets/*", "config/shared.lua" })
lua54 'yes'