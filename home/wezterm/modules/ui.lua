-- ---
-- Module: WezTerm - UI
-- Description: Tab bar, window decorations, and padding settings
-- Scope: Home Manager
-- ---

local M = {}

function M.apply(config, _)
  -- [GNOME tablet UI]
  config.enable_tab_bar = true
  config.hide_tab_bar_if_only_one_tab = true
  config.use_fancy_tab_bar = false
  config.tab_bar_at_bottom = false
  config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"
  config.integrated_title_button_style = "Gnome"
  config.integrated_title_button_alignment = "Right"
  config.integrated_title_buttons = { "Hide", "Maximize", "Close" }
  config.integrated_title_button_color = "Auto"
  config.show_tab_index_in_tab_bar = false
  config.tab_max_width = 18
  config.window_padding = {
    left = "1.0cell",
    right = "1.0cell",
    top = "0.35cell",
    bottom = "0.45cell",
  }
  config.window_close_confirmation = "AlwaysPrompt"
  config.adjust_window_size_when_changing_font_size = false
  config.initial_cols = 96
  config.initial_rows = 28
  config.enable_scroll_bar = false
end

return M
