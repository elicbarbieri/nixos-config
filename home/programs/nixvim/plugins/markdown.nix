{ pkgs, ... }: {
  plugins.markdown-preview = {
    enable = true;

    # Override the package to use Mermaid v11.10.1 with ELK layout support
    package = pkgs.vimPlugins.markdown-preview-nvim.overrideAttrs (old: {
      postInstall = let
        mermaidVersion = "11.10.1";
        elkLayoutVersion = "0.2.0";
        elkjsVersion = "0.9.3";

        # Mermaid v11.10.1
        mermaidJs = pkgs.fetchurl {
          url = "https://cdn.jsdelivr.net/npm/mermaid@${mermaidVersion}/dist/mermaid.min.js";
          sha256 = "0664267560d2f17d8e4dbaf010b58adfae8b57a7ac7325a11c77b45c24d4fc79";
        };

        elkjsBundle = pkgs.fetchurl {
          url = "https://cdn.jsdelivr.net/npm/elkjs@${elkjsVersion}/lib/elk.bundled.js";
          sha256 = "1m0nc9a20rwkj01310y76drgs6dyxmvy71qm19lr3k93gyymlx5h";
        };

        elkLayoutJs = pkgs.fetchurl {
          url = "https://cdn.jsdelivr.net/npm/@mermaid-js/layout-elk@${elkLayoutVersion}/dist/mermaid-layout-elk.esm.min.mjs";
          sha256 = "1pwwv8qpjhnkdsdwfs13hdxax68jkp2av9smx22vxnzz3pbsafdy";
        };

        elkChunk1 = pkgs.fetchurl {
          url = "https://cdn.jsdelivr.net/npm/@mermaid-js/layout-elk@${elkLayoutVersion}/dist/chunks/mermaid-layout-elk.esm.min/chunk-SP2CHFBE.mjs";
          sha256 = "1y8qx6szxiaahvj0469y1b98407hc5vadansiq4c4hjp692m6p1s";
        };

        elkChunk2 = pkgs.fetchurl {
          url = "https://cdn.jsdelivr.net/npm/@mermaid-js/layout-elk@${elkLayoutVersion}/dist/chunks/mermaid-layout-elk.esm.min/render-AVRWSH4D.mjs";
          sha256 = "1wky0i0ak8ms07jfwbwhh2qp1h023izb4y0hiwq3w0fliys70mbi";
        };

        # Bundle ELK layouts into a single browser-compatible script
        elkBundle = pkgs.stdenv.mkDerivation {
          name = "mermaid-elk-bundle";
          nativeBuildInputs = [ pkgs.esbuild pkgs.nodejs_22 ];

          dontUnpack = true;

          buildPhase = ''
            mkdir -p build/chunks/mermaid-layout-elk.esm.min

            cp ${elkLayoutJs} build/mermaid-layout-elk.esm.min.mjs
            cp ${elkChunk1} build/chunks/mermaid-layout-elk.esm.min/chunk-SP2CHFBE.mjs
            cp ${elkChunk2} build/chunks/mermaid-layout-elk.esm.min/render-AVRWSH4D.mjs

            cat > build/entry.js << 'EOF'
            import elkLayouts from './mermaid-layout-elk.esm.min.mjs';
            window.elkLayouts = elkLayouts;
            EOF

            # Bundle with esbuild (converts ESM to IIFE, resolves all imports)
            esbuild build/entry.js \
              --bundle \
              --format=iife \
              --platform=browser \
              --target=es2020 \
              --outfile=elk-bundle.js
          '';

          installPhase = ''
            mkdir -p $out
            cp elk-bundle.js $out/
          '';
        };

      in ''
        ${old.postInstall or ""}

        # Replace bundled Mermaid with v11.10.1
        cp ${mermaidJs} $out/app/_static/mermaid.min.js

        # Install ELK dependencies
        cp ${elkjsBundle} $out/app/_static/elk.bundled.js
        cp ${elkBundle}/elk-bundle.js $out/app/_static/elk-bundle.js

        # Patch HTML to load everything in correct order and register ELK layouts
        substituteInPlace $out/app/out/index.html \
          --replace '<script type="text/javascript" src="/_static/mermaid.min.js" class="next-head"></script>' \
                    '<script type="text/javascript" src="/_static/elk.bundled.js"></script>
<script type="text/javascript" src="/_static/mermaid.min.js" class="next-head"></script>
<script type="text/javascript" src="/_static/elk-bundle.js"></script>
<script>mermaid.registerLayoutLoaders(window.elkLayouts);</script>'

      '';
    });

    settings = {
      # Auto-close preview when changing buffers or leaving markdown file
      auto_close = 1;

      # Refresh on buffer save or leaving insert mode
      refresh_slow = 0;

      # Custom function to open preview in Brave with --app flag
      browserfunc = "OpenMarkdownPreview";

      # Echo preview page URL in command line
      echo_preview_url = 1;

      # Port for the preview server (empty = auto-select random port)
      port = "";

      # Preview page title
      page_title = "Markdown Preview - 「\${name}」";

      # Use custom IP for the preview server
      # Empty string = auto-select based on your network
      open_ip = "";

      # Theme for the preview (dark or light)
      theme = "dark";
    };
  };

  # Custom browser function for opening preview using layoutmsg preselect for right-side positioning
  extraConfigVim = ''
    function! OpenMarkdownPreview(url)
      execute "silent ! hyprctl dispatch layoutmsg preselect r ; brave --app=" . a:url . " &"
    endfunction
  '';

  # Keymaps for markdown preview
  keymaps = [
    {
      mode = "n";
      key = "<leader>up";
      action = "<cmd>MarkdownPreview<cr>";
      options.desc = "Markdown Preview";
    }
    {
      mode = "n";
      key = "<leader>uP";
      action = "<cmd>MarkdownPreviewStop<cr>";
      options.desc = "Stop Markdown Preview";
    }
  ];
}
