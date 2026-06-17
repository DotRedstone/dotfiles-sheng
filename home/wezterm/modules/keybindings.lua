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
    -- GNOME's on-screen keyboard may emit Delete where terminal apps expect Backspace.
    { key = 'Delete', mods = 'NONE', action = act.SendKey{ key = 'Backspace' } },
  }
end

return M
