{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.features.pipewire;
in
{
  options.features.pipewire = {
    enable = lib.mkEnableOption "PipeWire tweaks";

    disableAirplayDiscovery = lib.mkEnableOption ''
      disabling AirPlay/RAOP mDNS discovery (stops other people's Macs and                 
      network speakers from appearing as PipeWire sinks)                                   
    '';
  };

  # PipeWire is Linux-only; the same profile built for darwin skips this.
  config = lib.mkIf (cfg.enable && pkgs.stdenv.isLinux) {
    xdg.configFile."pipewire/pipewire.conf.d/50-raop.conf" = lib.mkIf cfg.disableAirplayDiscovery {
      text = ''
        context.modules = [                                                              
            { name = libpipewire-module-raop-discover                                    
                condition = [ { module.raop = false } ]                                  
            }                                                                            
        ]                                                                                
      '';
    };
  };
}
