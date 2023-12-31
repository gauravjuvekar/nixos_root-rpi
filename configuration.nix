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

  virtualisation.oci-containers.containers =
    {
      "ingress" =
        {
          image = "arm64v8/haproxy";
          volumes =
            [
              "/home/ingress:/usr/local/etc/haproxy:ro"
            ];
          ports =
            [
              "80:80"
              "443:443"
              "8000:8000"
            ];
          dependsOn = [ "frontpage" ];
          user = "root:root";
        };
      "frontpage" =
        {
          image = "arm64v8/httpd";
          volumes =
            [
              "/home/httpd_frontpage/public-html:/usr/local/apache2/htdocs:ro"
            ];
          hostname = "frontpage";
        };
      "homeassistant" =
        {
          image = "ghcr.io/home-assistant/home-assistant:stable" ;
          extraOptions =
            [
              "--network=host"
              "--privileged"
            ];
          volumes =
            [
              "/home/homeassistant:/config"
            ];
          dependsOn = [ "matterserver" ];
        };
      "matterserver" =
        {
          image = "ghcr.io/home-assistant-libs/python-matter-server:stable";
          extraOptions =
            [
              "--network=host"
              "--security-opt" "apparmor=unconfined"
            ];
          volumes =
            [
              "/home/matter:/data"
              "/run/dbus:/run/dbus:ro"
            ];
        };
    };

  boot.kernel.sysctl =
    {
      "net.ipv4.conf.all.forwarding" = true;
      "net.ipv6.conf.all.forwarding" = true;
    };

  networking.firewall =
    {
      enable = true;
      allowedTCPPorts =
        [
          22
          80
          443
          8000
          5540 # matter
        ];
      trustedInterfaces =
        [
          "wlan0"
          # "enabcm6e4ei0"
        ];
      logRefusedConnections = false;
      rejectPackets = true;
    };

  networking.nftables.enable = true;
  networking.nftables.ruleset = ''
      define IP4_NOFWD = {10.0.0.0/8, 192.168.0.0/16, 172.16.0.0/12}
      define IP6_NOFWD = {fd00::/8}
      define IFACE_IOT = "wlan0"
      define IFACE_WAN = "enabcm6e4ei0"

      table inet ap {
        chain routethrough {
          type nat hook postrouting priority filter; policy accept;
          oifname $IFACE_WAN masquerade
        }
        chain forward {
          type filter hook forward priority filter; policy drop;
          iifname $IFACE_WAN oifname $IFACE_IOT ct state established,related accept
          iifname $IFACE_IOT oifname $IFACE_WAN ip  daddr != $IP4_NOFWD accept
          iifname $IFACE_IOT oifname $IFACE_WAN ip6 daddr != $IP6_NOFWD accept
        }
      }
    '';

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
          settings.ieee80211w = "2"; # Regression from https://github.com/NixOS/nixpkgs/pull/263138
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

  environment.systemPackages = with pkgs;
    [
      conntrack-tools
      gitMinimal
      nix-output-monitor
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
