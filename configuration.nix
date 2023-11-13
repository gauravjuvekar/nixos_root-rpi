# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running `nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  networking.hostName = "rpi"; # Define your hostname.
  networking.networkmanager.enable = true;

  time.timeZone = "America/Los_Angeles";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  services.openssh.enable = true;

  users.mutableUsers = false;
  users.users.root.openssh.authorizedKeys.keys =
    [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICW38PaCVme5Kic109sI0ir5U2ZvzXAbI0Qpt5Y67k92 gaurav@dt.sc.gjuvekar.com"
    ];

  environment.etc =
    {
      "lvm/lvm.conf" = lib.mkForce
        {
          source = ./files/lvm.conf;
          mode = "0600";
        };
    };

  networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  system.copySystemConfiguration = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?

}

