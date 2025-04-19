{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let

  cfg = config.xsession.windowManager.spectrwm;

  renderedValue = val: if isBool val then if val then "1" else "0" else toString val;

  renderedSettings =
    settings: mapAttrsToList (name: value: "${name} = ${renderedValue value}") settings;

  renderedBindings = bindings: mapAttrsToList (name: value: "bind[${name}] = ${value}") bindings;

  renderedUnbindings = unbindings: map (value: "bind[] = ${value}") unbindings;

  renderedPrograms = programs: mapAttrsToList (name: value: "program[${name}] = ${value}") programs;

  renderedQuirks = quirks: mapAttrsToList (name: value: "quirk[${name}] = ${value}") quirks;

  settingType = types.oneOf [
    types.bool
    types.int
    types.str
  ];

in
{
  meta.maintainers = [ hm.maintainers.loicreynier ];

  options = {
    xsession.windowManager.spectrwm = {
      enable = mkEnableOption "Spectrwm window manager";

      package = mkOption {
        type = types.package;
        default = pkgs.spectrwm;
        defaultText = literalExpression "pkgs.spectrwm";
        description = ''
          Package providing the {command}`spectrwm` command.
        '';
      };

      settings = mkOption {
        type = types.attrsOf settingType;
        default = { };
        example = literalExpression ''
          {
            modkey = "Mod4";
            workspace_limit = 5;
            focus_mode = "manual";
            focus_close = "next";
          }
        '';
        description = "Spectrwm settings.";
      };

      bindings = mkOption {
        type = types.attrsOf types.str;
        default = { };
        example = literalExpression ''
          {
            term = "Mod+Return";
            restart = "Mod+Shift+r";
            quit = "Mod+Shift+q";
          }
        '';
        description = "Spectrwm keybindings.";
      };

      unbindings = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = literalExpression ''
          [
            "MOD+e"
            "MOD+f"
            "MOD+m"
            "MOD+s"
            "MOD+u"
            "MOD+t"
          ]
        '';
        description = ''
          List of keybindings to disable from default Spectrwm configuration.
        '';
      };

      programs = mkOption {
        type = types.attrsOf types.str;
        default = { };
        example = literalExpression ''
          {
            term = "alacritty";
            search = "dmenu -ip -p 'Window name/id:';
          }
        '';
        description = "Spectrwm programs variables.";
      };

      quirks = mkOption {
        type = types.attrsOf types.str;
        default = { };
        example = literalExpression ''
          {
            Matplotlib = "FLOAT";
            Pavucontrol = "FLOAT";
          }
        '';
        description = "Spectrwm quicks (custom window rules).";
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (hm.assertions.assertPlatform "xsession.windowManager.spectrwm" pkgs platforms.linux)
    ];

    home.packages = [ cfg.package ];

    xsession.windowManager.command = "${cfg.package}/bin/spectrwm";

    xdg.configFile."spectrwm/spectrwm.conf".text = ''
      # Generated by Home Manager
      ${concatStringsSep "\n" (
        # \
        renderedSettings cfg.settings # \
        ++ renderedPrograms cfg.programs # \
        ++ renderedQuirks cfg.quirks # \
        ++ renderedBindings cfg.bindings # \
        ++ renderedUnbindings cfg.unbindings
      )}
    '';
  };
}
