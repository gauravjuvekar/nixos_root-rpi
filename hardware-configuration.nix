{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "nodev";
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.efiInstallAsRemovable = true;
  # boot.loader.grub.enableCryptodisk = true;

  boot.loader.efi.canTouchEfiVariables = false;
  boot.loader.efi.efiSysMountPoint = "/boot/esp";

  boot.initrd.availableKernelModules =
    [
      "vc4"
      "bcm2835_dma"
      "i2c_bcm2835"
      "usb_storage"
      "xhci_pci"
      "uas"
      "usbhid"
      "sd_mod"
    ];
  boot.initrd.kernelModules = [ "dm-snapshot" "dm-integrity" "dm-raid" ];
  boot.initrd.systemd.enable = true;
  boot.initrd.services.lvm.enable = true;
  boot.initrd.systemd.contents =
    {
      "/etc/lvm/lvm.conf".source = ./files/lvm.conf;
    };

  boot.initrd.luks.devices."crypt_pv" =
    {
      device = "/dev/disk/by-uuid/67f80666-511c-4177-a666-3a63fb58689b";
      keyFile = "/dev/disk/by-partuuid/95d810ca-03";
      keyFileOffset = 8388608;
      keyFileSize = 4096;
    };

  boot.kernelModules = [ ];
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.extraModulePackages = [ ];
  boot.supportedFilesystems = [ "btrfs" ];

  fileSystems."/" =
    {
      device = "/dev/disk/by-uuid/b2b51387-f562-4586-8282-7ae0b6c16834";
      fsType = "btrfs";
      options = [ "subvol=@root" "ssd" "discard" "noatime" ];
    };

  fileSystems."/home" =
    {
      device = "/dev/disk/by-uuid/9d58d865-c18b-46a0-8a18-63f456f32e39";
      fsType = "btrfs";
      options = [ "subvol=@home" "ssd" "discard" "noatime" ];
    };

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/8dbac155-31f9-4899-86f6-f25646a0e02d";
      fsType = "ext4";
    };

  fileSystems."/boot/esp" =
    {
      device = "/dev/disk/by-uuid/C0BA-E285";
      fsType = "vfat";
    };

  swapDevices = [ ];

  hardware.enableRedistributableFirmware = true;

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";
}
