{ nixpkgs-unstable, ... }:
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./../../2configs/devel/forge.nix
    # TODO: Remove when buildbot is standing
    #./../../2configs/devel/ci.nix
    ./../../2configs/devel/buildbot.nix
    ./../../2configs/gitlab-ba.nix
  ];
  rtinf.base.systemType = "server";
  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda"; # or "nodev" for efi only

  networking = {
    hostName = "devel"; # Define your hostname.
    domain = "rtinf.net";
  };

  # List services that you want to enable:
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
  };
  security.acme.acceptTerms = true;
  security.acme.defaults.email = "unreal@rtinf.net";

  services.factorio = {
    enable = true;
    openFirewall = true;
    extraSettingsFile = "/var/lib/factorio-settings.json";
    package = nixpkgs-unstable.factorio-headless;

    mods =
      let
        inherit (nixpkgs-unstable) requireFile factorio-utils;
        modDrv = factorio-utils.modDrv {
          allRecommendedMods = true;
          allOptionalMods = true;
        };

        mods = rec {
          Factorissimo2-Playthrough = modDrv {
            src = requireFile {
              name = "Factorissimo2-Playthrough_1.2.1.zip";
              url = "https://mods.factorio.com/download/Factorissimo2-Playthrough/64ce38aa59d3cfa58acd391a?username={username}&token={token}";
              sha256 = "1dgrnzczh0vypayiv976hrpdzg9ixafmra90dbnar2lm8kzaxva7";
            };
            deps = [ Factorissimo2 ];
          };
          Factorissimo2 = modDrv {
            src = requireFile {
              name = "Factorissimo2_2.5.3.zip";
              url = "https://mods.factorio.com/download/Factorissimo2/616ea82bda84c78d82cde184?username={username}&token={token}";
              sha256 = "0knsghvsj02ziymml8p97w0y4vi8i7d926imny6lwr43myjw57ck";
            };
          };

          bobinserters = modDrv {
            src = requireFile {
              name = "bobinserters_1.3.2.zip";
              url = "https://mods.factorio.com/download/bobinserters/671f6f5baf7478b1eaac0a1e?username={username}&token={token}";
              sha256 = "1pl2afqy6gjgzpj5bijbca0xq1rj5d3ajhjx01rgfm3n2klhg70b";
            };
          };
          BottleneckLite = modDrv {
            src = requireFile {
              name = "BottleneckLite_1.3.2.zip";
              url = "https://mods.factorio.com/download/bobinserters/671f6f5baf7478b1eaac0a1e?username={username}&token={token}";
              sha256 = "16q10548zqw5bw7616v2w9pb23f1i9m052adhmdg9hmzy7i6r8p4";
            };
            deps = [ flib ];
          };
          flib = modDrv {
            src = requireFile {
              name = "flib_0.15.0.zip";
              url = "https://mods.factorio.com/download/flib/670d52ce9673ab955de00f63?username={username}&token={token}";
              sha256 = "0w59hsmhyk5q4hibfyaxymhgswnbycc7a4260gpji2xjvqs49hyh";
            };
          };
          even-distribution = modDrv {
            src = requireFile {
              name = "even-distribution_2.0.2.zip";
              url = "https://mods.factorio.com/download/even-distribution/6717f7ef79bf4bb954bf7731?username={username}&token={token}";
              sha256 = "0jq6qlq9kq8pmrqk7qbl9wz5a96yllc5jrn8g7wb3bycpqfs0hs3";
            };
          };
          far-reach = modDrv {
            src = requireFile {
              name = "far-reach_2.0.0.zip";
              url = "https://mods.factorio.com/download/even-distribution/6717f7ef79bf4bb954bf7731?username={username}&token={token}";
              sha256 = "10sadzjnw9ya38vxkvkb1m44xsfbkh23bqs43cx6gawwy40z54nn";
            };
          };
          Fill4Me = modDrv {
            src = requireFile {
              name = "Fill4Me_0.12.0.zip";
              url = "https://mods.factorio.com/download/Fill4Me/6726465d1f1ed0166bc7ee4f?username={username}&token={token}";
              sha256 = "1p2b60rxj1w27inrphlvjq0dg7lxh38vx5a22x85gzmc6j6xipna";
            };
          };
          playtime = modDrv {
            src = requireFile {
              name = "playtime_1.1.1.zip";
              url = "https://mods.factorio.com/download/playtime/6720c7a7be0d77976f64f318?username={username}&token={token}";
              sha256 = "18mal8ggab5imh85f9r9ln1ih791f7cx4mb9wmwkrlhd026kd0ri";
            };
          };
          RateCalculator = modDrv {
            src = requireFile {
              name = "RateCalculator_3.3.2.zip";
              url = "https://mods.factorio.com/download/RateCalculator/6721a5251729ac0ea413973e?username={username}&token={token}";
              sha256 = "0d8mrjp18w7w8mdh20w8adads3pq0khy81kg3ylr5c7sa58pv0y6";
            };
            deps = [ flib ];
          };
          show-max-underground-distance = modDrv {
            src = requireFile {
              name = "show-max-underground-distance_0.1.0.zip";
              url = "https://mods.factorio.com/download/show-max-underground-distance/670e87dfcefed9dbb07fccc5?username={username}&token={token}";
              sha256 = "0kn23sk2m8ph3ar5f3bvmk9vhnzmcdcn56rj27yy52mp7cf23xbj";
            };
          };
          some-squeak-through = modDrv {
            src = requireFile {
              name = "some-squeak-through_2.0.0.zip";
              url = "https://mods.factorio.com/download/some-squeak-through/6718d17b5f4a0024cea2852f?username={username}&token={token}";
              sha256 = "1g3n505d5akrs1fvcfi71446n5qxnaqwd0iqvinsagand3b3nr75";
            };
          };
          some-zoom = modDrv {
            src = requireFile {
              name = "some-zoom_2.0.0.zip";
              url = "https://mods.factorio.com/download/some-zoom/6717a66b34b01341b630da66?username={username}&token={token}";
              sha256 = "1kvp2dq1f425sw6km2pz7q7y8cv4m5bpn0wbba5cjhiyswizwvrw";
            };
          };
        };
      in
      builtins.attrValues {
        inherit (mods)
          bobinserters
          BottleneckLite
          even-distribution
          far-reach
          Fill4Me
          playtime
          RateCalculator
          show-max-underground-distance
          some-squeak-through
          some-zoom
          ;
      };
  };

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  #system.copySystemConfiguration = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?
}
