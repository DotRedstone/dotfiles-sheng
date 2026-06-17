# ---
# Module: NixVim - Copilot
# Description: GitHub Copilot core and chat integration
# Scope: Home Manager
# ---

{ ... }: {
  programs.nixvim.plugins = {
    copilot-lua = {
      enable = true;
      settings = {
        suggestion.enabled = false;
        panel.enabled = false;
        filetypes = {
          markdown = true;
          help = true;
        };
      };
    };

    copilot-chat = {
      enable = true;
      settings = {
        show_help = true;
        question_header = "User ";
        answer_header = "Copilot ";
        error_header = "Error ";
        separator = " ";
        prompts = {
          Explain = "Please explain the following code.";
          Review = "Please review the following code and provide suggestions.";
          Fix = "There is a bug in this code, please fix it.";
          Optimize = "Please optimize this code for performance and readability.";
          Docs = "Please add detailed comments to this code.";
          Tests = "Please write unit tests for this code.";
        };
      };
    };
  };

  programs.nixvim.keymaps = [
    {
      mode = "n";
      key = "<leader>cc";
      action = "<cmd>CopilotChatToggle<cr>";
      options = { desc = "Toggle Copilot Chat"; };
    }
    {
      mode = "v";
      key = "<leader>ce";
      action = "<cmd>CopilotChatExplain<cr>";
      options = { desc = "Explain with Copilot"; };
    }
  ];
}
