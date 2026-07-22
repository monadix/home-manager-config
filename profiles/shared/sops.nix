{ 
  config,
  ...
}:
{
  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;

    age = {
      keyFile = "${config.home.homeDirectory}/.config/sops/age/key.txt";
    };
  };
}
