{
  pkgs,
  lib,
  ...
}: 
let 
  askpass = lib.getExe (pkgs.lxqt.lxqt-openssh-askpass.overrideAttrs {
    src = pkgs.fetchFromGitHub {
      owner = "monadix";
      repo = "lxqt-openssh-askpass";
      rev = "ae7259b286dac149e571b7570fa4170f3d84e334";
      hash = "sha256-q04hQnY06mD0ZSlELMFf8+9AAQiVXJRgo4PC57EeOU0=";
    };
  });
in {
  services.ssh-agent.enable = true;

  programs.nushell.environmentVariables.SSH_ASKPASS = askpass;
  systemd.user.sessionVariables.ASK_PASSWORD = askpass;
}
