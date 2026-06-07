{ 
  config,
  ...
}:
{
  sops = {
    defaultSopsFile = ../secrets/secrets.yaml;

    age = {
      # This will automatically import SSH keys as age keys
      sshKeyPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];
      # This is using an age key that is expected to already be in the filesystem
      keyFile = "${config.home.homeDirectory}/.config/sops/age/key.txt";
      # This will generate a new key if the key specified above does not exist
      generateKey = true;
    };
  };
}
