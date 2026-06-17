# ---
# Module: NixVim - LSP Plugins
# Description: Language Server Protocol configuration and related tools
# Scope: Home Manager
# ---

{ pkgs, ... }:
{
  programs.nixvim.extraConfigLuaPre = ''
    -- [LSP] Log level
    vim.lsp.set_log_level("warn")

    -- [UI] Silence specific noise
    local original_notify = vim.notify
    vim.notify = function(msg, level, opts)
      if msg:find("/<default workspace root>") or msg:match("SQLite is an experimental feature") or msg:find("Policy watcher") then
        return
      end
      original_notify(msg, level, opts)
    end
  '';

  programs.nixvim.plugins = {
    lsp = {
      enable = true;
      inlayHints = true;
      servers = {
        bashls.enable = true;
        clangd.enable = true;
        cmake.enable = true;
        docker_compose_language_service.enable = true;
        dockerls.enable = true;
        jsonls.enable = true;
        lua_ls = {
          enable = true;
          settings = {
            workspace.checkThirdParty = false;
            completion.callSnippet = "Replace";
            diagnostics.globals = [
              "vim"
              "Snacks"
            ];
          };
        };
        marksman.enable = true;
        tinymist = {
          enable = true;
          settings = {
            autoArchive = true;
            formatterMode = "typstyle";
            exportPdf = "onSave";
            semanticTokens = "disable";
          };
        };
        nil_ls = {
          enable = true;
          extraOptions = {
            root_dir = {
              __raw = ''
                function(fname)
                  return require('lspconfig.util').root_pattern('flake.nix', '.git', 'default.nix')(fname) or vim.fn.getcwd()
                end
              '';
            };
          };
        };
        pyright = {
          enable = true;
          extraOptions = {
            root_dir = {
              __raw = ''
                function(fname)
                  return require('lspconfig.util').root_pattern('pyproject.toml', 'setup.py', '.git')(fname) or vim.fn.getcwd()
                end
              '';
            };
          };
        };
        ruff = {
          enable = true;
          onAttach.function = ''
            -- [Conflicts] Handled by Pyright
            client.server_capabilities.hoverProvider = false
          '';
          extraOptions = {
            root_dir = {
              __raw = ''
                function(fname)
                  return require('lspconfig.util').root_pattern('pyproject.toml', 'ruff.toml', '.git', 'setup.py')(fname) or vim.fn.getcwd()
                end
              '';
            };
          };
        };
        sqls.enable = true;
        tailwindcss.enable = true;
        taplo.enable = true;
        ts_ls.enable = true;
        volar.enable = true;
        yamlls.enable = true;
      };
    };

    schemastore = {
      enable = true;
      json.enable = true;
      yaml.enable = true;
    };

    lazydev = {
      enable = true;
      settings.library = [
        {
          path = "luvit-meta/library";
          words = [ "vim%.uv" ];
        }
      ];
    };

    trouble.enable = true;
    rustaceanvim = {
      enable = true;
      settings.server.default_settings.rust-analyzer = {
        cargo.allFeatures = true;
        check.command = "clippy";
        inlayHints = {
          bindingModeHints.enable = false;
          chainingHints.enable = true;
          closingBraceHints.minLines = 25;
          closureReturnTypeHints.enable = "never";
          lifetimeElisionHints.enable = "never";
          typeHints.enable = true;
        };
      };
    };

    jdtls = {
      enable = true;
      package = pkgs.jdt-language-server;
      rootMarkers = [
        "pom.xml"
        "build.gradle"
        "build.gradle.kts"
        "settings.gradle"
        "settings.gradle.kts"
        "mvnw"
        "gradlew"
        ".git"
      ];
    };

    venv-selector.enable = true;
    vim-dadbod.enable = true;
    vim-dadbod-ui.enable = true;
    vim-dadbod-completion.enable = true;
  };

  programs.nixvim.keymaps = [
    {
      mode = "n";
      key = "gd";
      action = "<cmd>lua vim.lsp.buf.definition()<cr>";
      options.desc = "转到定义";
    }
    {
      mode = "n";
      key = "gD";
      action = "<cmd>lua vim.lsp.buf.declaration()<cr>";
      options.desc = "转到声明";
    }
    {
      mode = "n";
      key = "gr";
      action = "<cmd>lua vim.lsp.buf.references()<cr>";
      options.desc = "查看引用";
    }
    {
      mode = "n";
      key = "gI";
      action = "<cmd>lua vim.lsp.buf.implementation()<cr>";
      options.desc = "转到实现";
    }
    {
      mode = "n";
      key = "gy";
      action = "<cmd>lua vim.lsp.buf.type_definition()<cr>";
      options.desc = "转到类型定义";
    }
    {
      mode = "n";
      key = "K";
      action = "<cmd>lua vim.lsp.buf.hover()<cr>";
      options.desc = "悬停提示";
    }
    {
      mode = "n";
      key = "<leader>ca";
      action = "<cmd>lua vim.lsp.buf.code_action()<cr>";
      options.desc = "代码操作";
    }
    {
      mode = "n";
      key = "<leader>rn";
      action = "<cmd>lua vim.lsp.buf.rename()<cr>";
      options.desc = "重命名";
    }
    {
      mode = "n";
      key = "<leader>xx";
      action = "<cmd>Trouble diagnostics toggle<cr>";
      options.desc = "项目诊断";
    }
    {
      mode = "n";
      key = "<leader>xX";
      action = "<cmd>Trouble diagnostics toggle filter.buf=0<cr>";
      options.desc = "当前文件诊断";
    }
    {
      mode = "n";
      key = "<leader>cs";
      action = "<cmd>Trouble symbols toggle focus=false<cr>";
      options.desc = "大纲/符号";
    }
    {
      mode = "n";
      key = "<leader>cl";
      action = "<cmd>Trouble lsp toggle focus=false win.position=right<cr>";
      options.desc = "LSP 定义/引用";
    }
    {
      mode = "n";
      key = "<leader>xL";
      action = "<cmd>Trouble loclist toggle<cr>";
      options.desc = "位置列表";
    }
    {
      mode = "n";
      key = "<leader>xQ";
      action = "<cmd>Trouble qflist toggle<cr>";
      options.desc = "Quickfix 列表";
    }
    {
      mode = "n";
      key = "[d";
      action = "<cmd>lua vim.diagnostic.goto_prev()<cr>";
      options.desc = "上一个诊断";
    }
    {
      mode = "n";
      key = "]d";
      action = "<cmd>lua vim.diagnostic.goto_next()<cr>";
      options.desc = "下一个诊断";
    }
    {
      mode = "n";
      key = "<leader>cv";
      action = "<cmd>VenvSelect<cr>";
      options.desc = "选择 Python 虚拟环境";
    }
  ];
}
