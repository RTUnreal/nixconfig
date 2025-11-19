{
  hosts = import ./hosts.nix;
  homevpn = import ./homevpn.nix;
  panopticon = import ./panopticon.nix;
  wbnet = import ./wbnet.nix;
}
