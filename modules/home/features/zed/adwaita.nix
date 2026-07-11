# A Zed theme built entirely from GNOME's Adwaita (libadwaita) palette.
#
# The UI chrome mirrors Adwaita verbatim: window/view/headerbar/sidebar/popover
# colors and the accent blue are taken from libadwaita's `_colors.scss`
# @define-color tokens, so Zed blends into the desktop.
#
# The syntax tokens use the same palette - keywords, functions, types and other
# constructs are colored with Adwaita's hue ramps (_palette.scss) via the
# conventional editor role assignment (keywords=red, functions=green, types=
# yellow, identifiers=blue, constants=purple, comments=gray-italic). Per
# appearance we pick the readable end of the ramp - bright shades (_1-_3) on
# dark, dark shades (_4/_5) on light - exactly how libadwaita swaps its own
# named colors between variants.
#
# Note: Zed's theme is color-only and settings.json exposes no element
# border-radius, padding, or margin (those are hardcoded in the renderer), so
# this theme can't carry Adwaita's radii (9/12/15px) or spacing. The chrome
# alignments that *are* reachable (Cantarell UI font, rectangular selection)
# live in the zed feature's settings.
#
# Sources:
#   - libadwaita _colors.scss (chrome @define-color tokens + accent hues)
#   - libadwaita _palette.scss (the red/green/yellow/blue/purple/orange ramps)
#   - libadwaita _common.scss ($button_radius 9 / $card_radius 12 / window 15px)
{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Adwaita (libadwaita) chrome colors, per appearance.
  adwaita = {
    dark = {
      window = "#222226"; # window_bg_color
      view = "#1d1d20"; # view_bg_color  (editor surface)
      headerbar = "#2e2e32"; # headerbar_bg_color (title/tab bar, dock)
      sidebar = "#2e2e32"; # sidebar_bg_color
      popover = "#36363a"; # popover_bg_color / dialog_bg_color (menus)
      card = "#333338"; # card_bg_color (white @ 8% over window)
      fg = "#ffffff"; # window_fg_color
      fgMuted = "#c2c2c8";
      fgDisabled = "#8b8b92";
      border = "#3a3a40";
      borderVariant = "#2e2e32";
      accent = "#3584e4"; # Adwaita default accent (blue_3)
      activeLine = "#26262b";
      hover = "#313138"; # fg @ 7% over window
      active = "#45454d"; # fg @ 16% over window
      selected = "#383840"; # fg @ 10% over window
    };
    light = {
      window = "#fafafb"; # window_bg_color
      view = "#ffffff"; # view_bg_color
      headerbar = "#ffffff"; # headerbar_bg_color
      sidebar = "#ebebed"; # sidebar_bg_color
      popover = "#ffffff"; # popover_bg_color
      card = "#ffffff"; # card_bg_color
      fg = "#333338"; # window_fg RGB(0 0 6 / 80%), composited over view
      fgMuted = "#5f5f66";
      fgDisabled = "#9a9aa0";
      border = "#dcdce0";
      borderVariant = "#ebebed";
      accent = "#3584e4";
      activeLine = "#f6f6f8";
      hover = "#ececee"; # fg @ 7% over window
      active = "#dadadd"; # fg @ 16% over window
      selected = "#e6e6e9"; # fg @ 10% over window
    };
  };

  # Syntax-token hues per role, drawn from Adwaita's palette (libadwaita
  # _palette.scss), using the conventional editor role assignment - keyword=red,
  # function=green, type=yellow, variable=blue, constant=purple, preproc=aqua,
  # storage/special=orange, comment/bracket=neutral gray. Bright shades (_1-_3)
  # on dark, dark shades (_4/_5) on light, so tokens stay readable on each chrome.
  # `aqua` is Adwaita teal (accent-teal) - the palette has no teal ramp, so it's
  # a single tone for both appearances.
  tokens = {
    dark = {
      red = "#f66151"; # red_1    - keywords, statements, tags, errors
      green = "#57e389"; # green_2   - functions, strings, success
      yellow = "#f6d32d"; # yellow_3  - types, typedefs, warnings, modified
      blue = "#62a0ea"; # blue_2    - identifiers, variables, escapes, info
      purple = "#c061cb"; # purple_2  - constants, numbers, booleans
      aqua = "#2190a4"; # accent-teal - preprocessor, attributes
      orange = "#ff7800"; # orange_3  - storage, special, some punctuation
      fg = "#ffffff"; # view_fg   - base text
      comment = "#9a9996"; # light_5   - comments
      bracket = "#c0bfbc"; # light_4   - punctuation
      ansi = {
        black = "#241f31"; # dark_4
        red = "#e01b24"; # red_3
        green = "#2ec27e"; # green_4
        yellow = "#e5a50a"; # yellow_5
        blue = "#3584e4"; # blue_3
        magenta = "#9141ac"; # purple_3
        cyan = "#2190a4"; # teal
        white = "#ffffff"; # light_1
        bright_black = "#77767b"; # dark_1
        bright_red = "#f66151"; # red_1
        bright_green = "#57e389"; # green_2
        bright_yellow = "#f6d32d"; # yellow_3
        bright_blue = "#99c1f1"; # blue_1
        bright_magenta = "#dc8add"; # purple_1
        bright_cyan = "#2190a4"; # teal
        bright_white = "#ffffff"; # light_1
      };
    };
    light = {
      red = "#c01c28"; # red_4
      green = "#26a269"; # green_5
      yellow = "#c88800"; # accent-yellow (readable fg on light)
      blue = "#1c71d8"; # blue_4
      purple = "#813d9c"; # purple_4
      aqua = "#2190a4"; # accent-teal
      orange = "#c64600"; # orange_5
      fg = "#333338"; # view_fg (RGB 0 0 6 / 80%) - base text
      comment = "#5e5c64"; # dark_2
      bracket = "#77767b"; # dark_1
      ansi = {
        black = "#241f31"; # dark_4
        red = "#c01c28"; # red_4
        green = "#26a269"; # green_5
        yellow = "#c88800"; # accent-yellow
        blue = "#1c71d8"; # blue_4
        magenta = "#813d9c"; # purple_4
        cyan = "#2190a4"; # teal
        white = "#5e5c64"; # dark_2 (dark, so it shows on a light terminal)
        bright_black = "#77767b"; # dark_1
        bright_red = "#e01b24"; # red_3
        bright_green = "#2ec27e"; # green_4
        bright_yellow = "#e5a50a"; # yellow_5
        bright_blue = "#3584e4"; # blue_3
        bright_magenta = "#9141ac"; # purple_3
        bright_cyan = "#2190a4"; # teal
        bright_white = "#241f31"; # dark_4
      };
    };
  };

  # Standard highlight-group -> token-role mapping (which token gets which hue
  # family); the hues themselves are the Adwaita `tokens` above. Identical for
  # both appearances - only the underlying shades differ.
  mkSyntax = g: {
    "attribute" = {
      color = g.aqua;
    };
    "boolean" = {
      color = g.purple;
    };
    "comment" = {
      color = g.comment;
      font_style = "italic";
    };
    "comment.doc" = {
      color = g.comment;
      font_style = "italic";
    };
    "constant" = {
      color = g.purple;
    };
    "constant.builtin" = {
      color = g.purple;
    };
    "constant.character" = {
      color = g.purple;
    };
    "constructor" = {
      color = g.orange;
      font_weight = 700;
    };
    "embedded" = {
      color = g.fg;
    };
    "emphasis" = {
      color = g.blue;
      font_style = "italic";
    };
    "emphasis.strong" = {
      color = g.fg;
      font_weight = 700;
    };
    "function" = {
      color = g.green;
      font_weight = 700;
    };
    "function.builtin" = {
      color = g.orange;
    };
    "function.macro" = {
      color = g.aqua;
    };
    "function.method" = {
      color = g.green;
      font_weight = 700;
    };
    "keyword" = {
      color = g.red;
    };
    "keyword.control" = {
      color = g.red;
    };
    "keyword.function" = {
      color = g.red;
    };
    "keyword.operator" = {
      color = g.orange;
    };
    "label" = {
      color = g.aqua;
    };
    "link_text" = {
      color = g.green;
    };
    "link_uri" = {
      color = g.blue;
    };
    "number" = {
      color = g.purple;
    };
    "operator" = {
      color = g.fg;
    };
    "preproc" = {
      color = g.aqua;
    };
    "property" = {
      color = g.fg;
    };
    "punctuation" = {
      color = g.bracket;
    };
    "punctuation.bracket" = {
      color = g.bracket;
    };
    "punctuation.delimiter" = {
      color = g.bracket;
    };
    "punctuation.list_marker" = {
      color = g.orange;
    };
    "punctuation.special" = {
      color = g.orange;
    };
    "string" = {
      color = g.green;
    };
    "string.doc" = {
      color = g.comment;
    };
    "string.escape" = {
      color = g.blue;
    };
    "string.regexp" = {
      color = g.blue;
    };
    "string.special" = {
      color = g.blue;
    };
    "tag" = {
      color = g.red;
    };
    "text.literal" = {
      color = g.green;
    };
    "text.title" = {
      color = g.orange;
      font_weight = 700;
    };
    "text.uri" = {
      color = g.blue;
      font_style = "italic";
    };
    "type" = {
      color = g.yellow;
    };
    "type.builtin" = {
      color = g.yellow;
    };
    "variable" = {
      color = g.blue;
    };
    "variable.builtin" = {
      color = g.aqua;
    };
    "variable.member" = {
      color = g.fg;
    };
    "variable.parameter" = {
      color = g.orange;
    };
  };

  # Multiplayer cursor/selection hues (Adwaita palette + accent).
  mkPlayers =
    hues:
    builtins.map (h: {
      background = "${h}22";
      cursor = h;
      selection = "${h}44";
    }) hues;

  # A status set (git/diagnostics) for one appearance: fg + faint bg + border.
  mkStatus = color: {
    inherit color;
    background = "${color}26";
    border = color;
  };

  # Build a full Zed ThemeStyle from an Adwaita chrome set + a syntax-token set.
  mkStyle = a: g: {
    # --- surfaces ---
    "background" = a.window;
    "surface.background" = a.headerbar;
    "elevated_surface.background" = a.popover;

    # --- accent ---
    "accent" = a.accent; # singular form read by older Zed
    "accents" = [ a.accent ]; # array form in schema v0.2.0

    # --- borders ---
    "border" = a.border;
    "border.variant" = a.borderVariant;
    "border.focused" = a.accent;
    "border.selected" = a.accent;
    "border.disabled" = a.borderVariant;
    "border.transparent" = "#00000000";

    # --- text ---
    "text" = a.fg;
    "text.accent" = a.accent;
    "text.muted" = a.fgMuted;
    "text.disabled" = a.fgDisabled;
    "text.placeholder" = a.fgDisabled;

    # --- icons ---
    "icon" = a.fg;
    "icon.accent" = a.accent;
    "icon.muted" = a.fgMuted;
    "icon.disabled" = a.fgDisabled;
    "icon.placeholder" = a.fgDisabled;

    # --- elements (buttons/inputs) ---
    "element.background" = a.card;
    "element.hover" = a.hover;
    "element.active" = a.active;
    "element.selected" = a.selected;
    "element.disabled" = a.hover;
    "ghost_element.background" = "#00000000";
    "ghost_element.hover" = a.hover;
    "ghost_element.active" = a.active;
    "ghost_element.selected" = a.selected;
    "ghost_element.disabled" = a.hover;

    # --- editor (Adwaita chrome, Adwaita-syntax text) ---
    "editor.background" = a.view;
    "editor.foreground" = g.fg;
    "editor.gutter.background" = a.view;
    "editor.line_number" = a.fgDisabled;
    "editor.active_line_number" = a.fg;
    "editor.active_line.background" = a.activeLine;
    "editor.highlighted_line.background" = a.activeLine;
    "editor.invisible" = a.fgDisabled;
    "editor.wrap_guide" = a.borderVariant;
    "editor.active_wrap_guide" = a.border;
    "editor.indent_guide" = a.borderVariant;
    "editor.indent_guide_active" = a.border;
    "editor.subheader.background" = a.headerbar;
    "editor.document_highlight.read_background" = a.hover;
    "editor.document_highlight.write_background" = a.selected;
    "editor.document_highlight.bracket_background" = a.hover;

    # --- chrome bars ---
    "status_bar.background" = a.window;
    "title_bar.background" = a.headerbar;
    "title_bar.inactive_background" = a.window;
    "toolbar.background" = a.headerbar;
    "tab_bar.background" = a.headerbar;
    "tab.active_background" = a.view;
    "tab.inactive_background" = a.headerbar;
    "panel.background" = a.sidebar;
    "panel.focused_border" = a.accent;
    "panel.indent_guide" = a.borderVariant;
    "panel.indent_guide_active" = a.border;
    "panel.indent_guide_hover" = a.border;
    "pane.focused_border" = a.accent;
    "pane_group.border" = a.border;

    # --- search & scrollbar ---
    "search.match_background" = "${g.yellow}40";
    "scrollbar.thumb.background" = "${a.fg}33";
    "scrollbar.thumb.hover_background" = "${a.fg}55";
    "scrollbar.thumb.border" = "#00000000";
    "scrollbar.track.background" = "#00000000";
    "scrollbar.track.border" = "#00000000";

    # --- git status ---
    "created" = mkStatus g.green;
    "deleted" = mkStatus g.red;
    "modified" = mkStatus g.yellow;
    "conflict" = mkStatus g.purple;
    "ignored" = mkStatus a.fgDisabled;
    "hidden" = mkStatus a.fgDisabled;
    "renamed" = mkStatus g.blue;

    # --- diagnostics ---
    "error" = mkStatus g.red;
    "warning" = mkStatus g.yellow;
    "info" = mkStatus g.blue;
    "hint" = mkStatus g.aqua;
    "success" = mkStatus g.green;
    "predictive" = mkStatus g.purple;
    "unreachable" = mkStatus g.comment;

    # --- multiplayer ---
    "players" = mkPlayers [
      a.accent
      g.green
      g.purple
      g.orange
      g.aqua
      g.yellow
      g.red
    ];

    # --- terminal (Adwaita ANSI, Adwaita surface) ---
    "terminal.background" = a.view;
    "terminal.foreground" = g.fg;
    "terminal.bright_foreground" = g.fg;
    "terminal.dim_foreground" = g.comment;
    "terminal.ansi.background" = a.view;
    "terminal.ansi.black" = g.ansi.black;
    "terminal.ansi.red" = g.ansi.red;
    "terminal.ansi.green" = g.ansi.green;
    "terminal.ansi.yellow" = g.ansi.yellow;
    "terminal.ansi.blue" = g.ansi.blue;
    "terminal.ansi.magenta" = g.ansi.magenta;
    "terminal.ansi.cyan" = g.ansi.cyan;
    "terminal.ansi.white" = g.ansi.white;
    "terminal.ansi.bright_black" = g.ansi.bright_black;
    "terminal.ansi.bright_red" = g.ansi.bright_red;
    "terminal.ansi.bright_green" = g.ansi.bright_green;
    "terminal.ansi.bright_yellow" = g.ansi.bright_yellow;
    "terminal.ansi.bright_blue" = g.ansi.bright_blue;
    "terminal.ansi.bright_magenta" = g.ansi.bright_magenta;
    "terminal.ansi.bright_cyan" = g.ansi.bright_cyan;
    "terminal.ansi.bright_white" = g.ansi.bright_white;

    "syntax" = mkSyntax g;
  };
in
{
  # Only provision the theme alongside the editor itself (Linux; the zed feature
  # is Linux-only today, matching the install.sh bootstrap).
  config = lib.mkIf (config.features.zed.enable && pkgs.stdenv.isLinux) {
    programs.zed-editor.themes."adwaita" = {
      "$schema" = "https://zed.dev/schema/themes/v0.2.0.json";
      name = "Adwaita";
      author = "Dan Greco";
      themes = [
        {
          appearance = "dark";
          name = "Adwaita Dark";
          style = mkStyle adwaita.dark tokens.dark;
        }
        {
          appearance = "light";
          name = "Adwaita Light";
          style = mkStyle adwaita.light tokens.light;
        }
      ];
    };
  };
}
