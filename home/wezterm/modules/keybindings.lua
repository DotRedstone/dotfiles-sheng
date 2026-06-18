-- ---
-- Module: WezTerm - Keybindings
-- Description: Custom keyboard shortcuts for terminal management
-- Scope: Home Manager
-- ---

local M = {}

function M.apply(config, wezterm)
  local act = wezterm.action

  -- [Keybindings]
  config.keys = {
    { key = 'S', mods = 'CTRL|SHIFT', action = act.ShowLauncher },
    { key = 'P', mods = 'CTRL|SHIFT', action = act.ActivateCommandPalette },
    { key = 'N', mods = 'CTRL|SHIFT', action = act.SpawnWindow },
    { key = 'W', mods = 'CTRL|SHIFT', action = act.CloseCurrentTab{ confirm = true } },
    -- GNOME's on-screen keyboard often emits Delete; terminal apps expect DEL.
    { key = 'Backspace', mods = 'NONE', action = act.SendString('\x7f') },
    { key = 'Delete', mods = 'NONE', action = act.SendString('\x7f') },
  }
end

return M
