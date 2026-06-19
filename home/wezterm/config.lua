-- ---
-- Module: WezTerm
-- Description: Minimalist, high-performance terminal canvas
-- Scope: Home Manager
-- ---

local wezterm = require 'wezterm'
local config = wezterm.config_builder()

config.default_prog = { 'fish' }

-- [Module Path Setup]
-- Ensure we can require modules from the same directory
local config_dir = wezterm.config_dir or (os.getenv("HOME") .. "/.config/wezterm")
package.path = config_dir .. "/?.lua;" .. config_dir .. "/?/init.lua;" .. package.path

-- [Modules]
require("modules.visuals").apply(config, wezterm)
require("modules.ui").apply(config, wezterm)
require("modules.performance").apply(config, wezterm)
require("modules.theme").apply(config, wezterm)
require("modules.ssh").apply(config, wezterm)
require("modules.keybindings").apply(config, wezterm)

return config
