{ config, lib, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      <agenix/modules/age.nix>
    ];

  networking.hostName = "rpi";
  networking.domain = "sc.gjuvekar.com";
  networking.networkmanager.enable = false;
  networking.useNetworkd = true;
  systemd.network.enable = true;

  systemd.network.networks."wlan0" =
    {
      enable = true;
      name = "wlan0";
      DHCP = "no";
      address =
        [
          "10.10.16.1/16"
          "fde8:3a34:ee2f:f101::1/64"
        ];
    };

  time.timeZone = "America/Los_Angeles";

  i18n.defaultLocale = "en_US.UTF-8";

  services.openssh.enable = true;
  services.openssh.settings =
    {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };

  users.mutableUsers = false;
  users.users."root".openssh.authorizedKeys.keys =
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

  age.secrets."hostapd_wpa_password".file = ./secrets/hostapd_wpa_password.age;
  services.hostapd.enable = true;
  services.hostapd.radios."wlan0" =
    {
      band = "2g";
      countryCode = "US";
      channel = 7;
      networks."wlan0" =
        {
          ssid = "gaurav-iot";
          authentication =
            {
              mode = "wpa2-sha256";
              wpaPasswordFile = config.age.secrets."hostapd_wpa_password".path;
            };
        };
      wifi4.capabilities = [ "SHORT-GI-20" ];
    };

  services.dnsmasq.enable = true;
  services.dnsmasq.settings =
    {
      interface = "wlan0";
      bind-interfaces = true;
      resolv-file = false;
      listen-address = "10.10.16.1";

      # DNS
      no-resolv = true;
      server = [ "1.1.1.1" "2606:4700:4700::1111" "2606:4700:4700::1001" ];
      domain = "iot.sc.gjuvekar.com";

      # DHCP
      dhcp-option =
        [
          "3,0.0.0.0" # Default gateway
          "6,0.0.0.0" # DNS servers to announce
        ];
      dhcp-range =
        [
          "10.10.17.0,10.10.30.255,4h"
          "::f101:0001,::f101:fffe,constructor:wlan0,slaac,12h" # SLAAC + DHCPv6 assigned address
        ];
    };

  networking.firewall.enable = false;

  environment.systemPackages = with pkgs;
    [
      gitMinimal
      screen
    ];

  system.copySystemConfiguration = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
