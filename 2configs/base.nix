{pkgs, ...}: {
  imports = [
    ./../3modules/neovim
  ];

  users.users.trr = {
    isNormalUser = true;
    description = "Alexander Gaus";
    extraGroups = ["wheel"];
    uid = 1000;
  };

  # Select internationalisation properties.
  i18n.defaultLocale = "de_DE.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "de";
  };

  environment.systemPackages = with pkgs; [
    # shell utils
    wget
    file
    findutils
    tree
    lsof
    xxd
    jq
    qrencode

    # net utils
    bind
    whois
    iperf
    nmap

    # system utils
    htop
    inxi
    pciutils
    usbutils
  ];

  programs = {
    bash.shellAliases = {
      gs = "git status";
      gap = "git add -p";
    };
    git = {
      enable = true;
      lfs.enable = true;
    };
    htop.enable = true;
    less.enable = true;
    iftop.enable = true;
  };

  rtinf.neovim.enable = true;

  #system.copySystemConfiguration = true;

  nix.settings.experimental-features = ["nix-command" "flakes"];
}
