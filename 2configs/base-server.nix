{...}: {
  users.users.trr.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDOQJOT6cBwg5xXHR+zpS7+VMcx4F73Qm+X4cWaFqRp+g5ru0M/xb+T2icX189j0qWe3BwpftupzaHy7h4sZRTIcRGwlu8LRGFY1WpL8ftgvWCG45ZD3Lp1nX3XpOfBTZD+XYoNOWVM4kuL/+wWYGQYKzo4Ui3kKFEPo0hrShN7GEMim76Xm3m7sldGW0vBzSk8DpLykDLt+RxrLeY2xGI112fjAVvaWn82KE+kflaQIF5XZNVPFqNTMvhRL+ZHTal1SeN3i2TdcbxV9DMLQ/s5bcSLatae/SMlYqNipTpX+lodBqc0d7e0LfwYJERkAHB0NX3TfQPB5tB8EReGMoOm2m0TPdIRGhaEAM5abB5cQr3KV/r2BAVTrcA6ij2f2GszVNNllhHQHvpv5RZUw8+htvFbaTv0Ww+3X1CY/B+hQQ9st4DIfC0o2or38BE1cn90mqfqvl1s/uplkX3ToYo8PU8j0SqVtBWNq/E7lHecTIZqUL5NX32xUnXvjmhZgtU= trr@runner"
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDAWBFNy2N6Exx7tHlbUDXERJjT7PhIs+vZIWPmhh3qLieeC1tAOf9XcbgVGL3bAryyaCEr1s2bZ6rs2L1JgFFJEGE9TCbfl2dfJIslCPP4OmKxwciIo+T4eXbanGDV0hzW+/vvMyQeWcVT27BrANYR7R28nURmXa1aQ9nWdnHy1Evuv4fI/e+6o3AKEji6Spl5FHs3T9+5vrEwsdq7Mewbfel6gAb3xmp9DIR0Kz0QnitwwErcZYgA2o64C6DLNgsG2l1PrZxE3/MaB6FyzCyOfU8C0FovWlvmmOXkwFPZz1HN1KkKZKV50H4ffiN0cVSLBt6NW6s0v7TWhJyrbIEr trr@spinner"
  ];
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };
}
