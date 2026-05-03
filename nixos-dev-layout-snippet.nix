{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    uv
    poetry
    jq
    yq
    tree
    lsof
  ];

  systemd.tmpfiles.rules = [
    "d /srv/apps 0755 life7vision users - -"
    "d /srv/releases 0755 life7vision users - -"
    "d /var/lib/apps 0755 life7vision users - -"
    "d /var/log/apps 0755 life7vision users - -"
    "d /var/cache/apps 0755 life7vision users - -"
  ];

  environment.variables = {
    PIP_REQUIRE_VIRTUALENV = "true";
  };

  programs.zsh.enable = true;
}
