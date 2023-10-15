{...}: {
  virtualisation.docker.enable = true;
  users.users.trr.extraGroups = ["docker"];
}
