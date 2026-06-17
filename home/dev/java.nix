# ---
# Module: Java Development
# Description: JDK and build automation tools for JVM projects
# Scope: Home Manager
# ---

{ pkgs, ... }: {
  home.packages = with pkgs; [
    jdk21
    maven
    gradle
  ];
}
