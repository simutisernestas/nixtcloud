{ config, lib, pkgs, ... }:
let
  name = "nixtcloud";
in
{
  imports =
    [ ./nextcloud.nix
      ./first-boot.nix
    ];

  networking.hostName = name; 
  
  #### You can define your wireless network here if you don't want to use ethernet cable.
  #networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  #networking.wireless.networks = { SSID = { psk = "pass"; };  };

  # Set your time zone.
  time.timeZone = "auto";
  
  ########## Most probably you don't need and don't want to change the nix settings below #########
  nix.settings = {
	  experimental-features = "nix-command flakes";
	  auto-optimise-store = false; #fewer writes to sd-card
    substituters = [ "https://nix-community.cachix.org" ];
	  trusted-public-keys = [ "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" ];
    require-sigs = false;
  };
  nix.gc = {
	  automatic = true;
	  dates = "weekly";
	  options = "--delete-older-than 5d";
  };
  ##########################################################################################

  ######################################## Size reduction options ########################################
  programs.command-not-found.enable = false;
  i18n.supportedLocales = lib.mkForce [ "en_US.UTF-8/UTF-8" ];
  environment.defaultPackages = lib.mkForce [];
  environment.stub-ld.enable = false;
  boot.supportedFilesystems = lib.mkForce [ "vfat" "ext4" "exfat" "ntfs3" ];
  systemd = {
    coredump.enable = false;
    enableEmergencyMode = false;
  };
  security.audit.enable = false;
  security.auditd.enable = false;
  boot.plymouth.enable = false;
  zramSwap.enable = false;
  documentation = {
    enable = false;
    man.enable = false;
    info.enable = false;
    doc.enable = false;
    nixos.enable = false;
  };
  services.logrotate.enable = false;
  services.udisks2.enable = false;
  xdg = {
    autostart.enable = false;
    icons.enable = false;
    mime.enable = false;
    sounds.enable = false;
  };
  #######################################################################################################

  ### DO NOT CHANGE the username. After the system is installed, you can change the password with 'passwd' command.
   users.users.admin = {
     isNormalUser = true;
     extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
     initialPassword = "admin";
   };
  
  ### If you know what the following line does, you can uncomment it ;)
  #security.sudo.wheelNeedsPassword = false;

  ###### Packages that are available systemwide. Most probably you don't need to change this. ######
  environment.systemPackages = [
      pkgs.curl
      pkgs.jq
      pkgs.htop
      pkgs.avahi
      pkgs.nssmdns
  ];  

  ### Optional daily reboot and periodic nextcloud maintenance
  ### Weekly check and apply of updates
  services.cron.enable = true;
  services.cron.systemCronJobs = [
    #"0 2 * * *    root    /run/current-system/sw/bin/reboot"
    "0 2 * * *    root    sudo -u nextcloud /run/current-system/sw/bin/nextcloud-occ maintenance:repair"
    "5 2 * * 0    root    sudo -u nextcloud /run/current-system/sw/bin/nextcloud-occ maintenance:mimetype:update-db"
    "10 2 * * 0   root    sudo -u nextcloud /run/current-system/sw/bin/nextcloud-occ maintenance:mimetype:update-js"
    ### Automatic system updates are disabled by default: they would silently pull and rebuild
    ### from github:jjacke13/nixtcloud as root with no review. Run updater.sh manually instead:
    ###   sudo bash /etc/nixos/updater.sh
    #"0 3 * * 0    root    /run/current-system/sw/bin/bash /etc/nixos/updater.sh"
    #"0 15 * * 5   root    /run/current-system/sw/bin/bash /etc/nixos/backup-reminder.sh" #will be added in the future
  ];
  
  ########## SSH & Security ##########
  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "no";
  services.openssh.settings.PasswordAuthentication = false;
  services.openssh.settings.KbdInteractiveAuthentication = false;
  users.users.admin.openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMtXV08kDi7eePGWFa2uPoVyeH+u8KkFbIwVna24i3qq ernie@andromeda" ];
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 80 443 ];
  };
  #####################################
  
  #### DON'T CHANGE ANYTHING BELOW THIS LINE UNLESS YOU ABSOLUTELY KNOW WHAT YOU ARE DOING ###

  ########## AVAHI ##########
  services.avahi = {
    enable = true;
    hostName = name;
    nssmdns4 = true;
    reflector = true;
    openFirewall = true;
    publish.enable = true;
    publish.userServices = true;
    publish.domain = true;
    publish.addresses = true;
  };
  ### Seen in practice: avahi-daemon died within minutes of a fresh boot, with no
  ### crash signal logged (proximate cause unrecoverable - dmesg is restricted and
  ### coredumps are disabled above). The stock unit has no restart policy and left
  ### a stale /run/avahi-daemon/pid behind, so it stayed down until someone
  ### manually cleared the pid file and restarted it. Auto-restart, plus clearing
  ### the stale pid file before each start, makes it self-heal instead.
  systemd.services.avahi-daemon.serviceConfig = {
    Restart = "on-failure";
    RestartSec = "5s";
    ExecStartPre = [ "-${pkgs.coreutils}/bin/rm -f /run/avahi-daemon/pid" ];
  };
  ###########################

  ###### System services ######

  #### This service initializes the system and checks stuff after each reboot. ####
  systemd.services.startup = {
    description = "Startup";
    wantedBy = [ "multi-user.target" ];
    after = ["network.target" "nextcloud-setup.service"];
    enable = true;
    path = [ pkgs.coreutils ];
    script = ''
          /run/current-system/sw/bin/nextcloud-occ app:enable files_external
          /run/current-system/sw/bin/nextcloud-occ app:disable files_trashbin
          /run/current-system/sw/bin/nextcloud-occ config:app:set preview jpeg_quality --value="55"
          /run/current-system/sw/bin/nextcloud-occ app:disable nextbackup      
          if [ ! -f /var/lib/nextcloud/data/admin/files/rebooter.txt ]; then
              touch /var/lib/nextcloud/data/admin/files/rebooter.txt
              chown nextcloud:nextcloud /var/lib/nextcloud/data/admin/files/rebooter.txt
              /run/current-system/sw/bin/nextcloud-occ files:scan --path=/admin/files
          fi
    '';
    serviceConfig.Type = "oneshot";
    before = ["mymnt.service" "rebooter.service"];
    onSuccess = ["mymnt.service" "rebooter.service"];
  };
  ############################################################################

  ### The following service automounts external usb devices with correct permissions and creates the corresponding Nextcloud external storages.######
  systemd.services.mymnt = {
    enable = true;
    path = [ pkgs.util-linux pkgs.gawk pkgs.exfatprogs ];
    serviceConfig = {
		  Type = "simple";
		  ExecStart = "${pkgs.bash}/bin/bash /etc/nixos/mounter.sh";
		  Restart = "always";
		  RestartSec = "30";
      KillMode = "process";
	  };
  };
  ################################################################################

  ##### This service reboots the system if the rebooter.txt file gets deleted. On startup, it gets created again ####
  systemd.services.rebooter = {
    description = "rebooter";
    enable = true;
    path = [  ];
    script = ''
          if [ ! -f /var/lib/nextcloud/data/admin/files/rebooter.txt ]; then
            reboot
          fi
    '';
    serviceConfig.Type = "simple";
    serviceConfig.Restart = "always";
    serviceConfig.RestartSec = "30";
    after = ["startup.service"];
  };
  ##############################################################################
  
  ###### Defining the mounter script. This script mounts the external usb devices with correct permissions. ######
  environment.etc."nixos/mounter.sh" = { 
    source = ./mounter.sh;
    mode = "0744";
    group = "wheel";
  };

  environment.etc."nixos/updater.sh" = {
    source = ./updater.sh;
    mode = "0744";
    group = "wheel";
  };
  ##############################################################################################################

}


