{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.features.cli;

  # `rnd <N>`: generate N random output characters. <N> is the output
  # length (a char count, not bytes); the byte count fed to `openssl rand`
  # is derived per format so odd hex lengths and non-multiple-of-3 base64
  # lengths still produce exactly N characters.
  rnd = pkgs.writeShellApplication {
    name = "rnd";
    runtimeInputs = [
      pkgs.openssl
      pkgs.coreutils
    ];
    text = ''
      format=hex
      count=
      for arg in "$@"; do
        case "$arg" in
          hex | h)
            format=hex
            ;;
          base64 | b64)
            format=base64
            ;;
          base64url | b64url | url)
            format=base64url
            ;;
          raw | bin | bytes)
            format=raw
            ;;
          -h | --help)
            echo "Usage: rnd [hex|base64|base64url|raw] <N>"
            echo "Generate <N> random output characters."
            echo "  hex         lowercase hex (default)"
            echo "  base64      standard base64"
            echo "  base64url   URL-safe base64 (+/ -> -_)"
            echo "  raw         <N> raw bytes"
            echo "<N> is the output length; the random-byte count is derived per format."
            exit 0
            ;;
          *)
            if [ -n "$count" ]; then
              echo "rnd: unexpected argument '$arg'" >&2
              exit 2
            fi
            count="$arg"
            ;;
        esac
      done

      if [ -z "$count" ]; then
        echo "Usage: rnd [hex|base64|base64url|raw] <N>" >&2
        exit 2
      fi

      case "$count" in
        *[!0-9]*)
          echo "rnd: <N> must be a positive integer, got '$count'" >&2
          exit 2
          ;;
      esac

      [ "$count" -ge 1 ] || {
        echo "rnd: <N> must be greater than 0" >&2
        exit 2
      }

      # Capture the full `openssl` output, then truncate to <N> chars with
      # printf precision. Reading the whole stream avoids the SIGPIPE that
      # `head -c` would raise against openssl under `pipefail`.
      case "$format" in
        hex)
          bytes=$(( (count + 1) / 2 ))
          out=$(openssl rand -hex "$bytes")
          printf '%.*s\n' "$count" "$out"
          ;;
        base64)
          bytes=$(( (count * 3 + 3) / 4 ))
          out=$(openssl rand -base64 "$bytes" | tr -d '\n=')
          printf '%.*s\n' "$count" "$out"
          ;;
        base64url)
          bytes=$(( (count * 3 + 3) / 4 ))
          out=$(openssl rand -base64 "$bytes" | tr -d '\n=' | tr '+/' '-_')
          printf '%.*s\n' "$count" "$out"
          ;;
        raw)
          openssl rand "$count"
          ;;
      esac
    '';
  };
in
{
  options.features.cli.enable = lib.mkEnableOption "modern CLI tools";

  config = lib.mkIf cfg.enable {
    # eza: ls replacement. Shell integration is on by default, so it adds the
    # ls/ll/la/lt aliases in any enabled shell (e.g. fish).
    programs.eza = {
      enable = true;
      icons = "never";
      git = true;
    };

    programs.fd.enable = true; # `find` replacement
    programs.fastfetch.enable = true; # system info
    programs.ripgrep.enable = true; # `grep` replacement (rg)
    programs.bat.enable = true; # `cat` with syntax highlighting
    programs.btop.enable = true; # resource monitor
    programs.jq.enable = true; # JSON processor
    programs.lazygit.enable = true; # git TUI
    programs.tealdeer.enable = true; # `tldr` quick command examples
    programs.yazi.enable = true; # terminal file manager

    home.packages =
      with pkgs;
      [
        dust # `du` replacement
        procs # `ps` replacement
        hyperfine # command benchmarking
        gping # `ping` with a graph
        doggo # modern `dig`
      ]
      ++ [ rnd ];
  };
}
