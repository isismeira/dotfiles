local wezterm = require('wezterm')
local Config = require('config')

require('utils.backdrops'):set_files()
wezterm.GLOBAL.background = wezterm.config_dir .. '/backdrops/D814B531-7943-4B15-A709-B7D8F0662EC0.PNG'

require('events.right-status').setup()
require('events.left-status').setup()
require('events.tab-title').setup()
require('events.new-tab-button').setup()

return Config:init()
   :append(require('config.appearance'))
   :append(require('config.bindings'))
   :append(require('config.domains'))
   :append(require('config.fonts'))
   :append(require('config.general'))
   :append(require('config.launch')).options
