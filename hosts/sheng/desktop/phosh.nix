# Phosh Desktop Configuration (Mobile/Touch oriented)
{ pkgs, ... }: {
  services.xserver.enable = true;
  services.xserver.desktopManager.phosh.enable = true;
  

  
  services.xserver.desktopManager.phosh.user = "dot";
  services.xserver.desktopManager.phosh.group = "users";
}
