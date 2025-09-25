# ~/dotfiles/nix/secrets/secrets.nix
{
  # This file declares our secrets and who can edit them.

  "secrets/example-secret.age".publicKeys = [
    # User Key: liyan
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAN09iS1jxNkCh2ZjZ1N/tsVXSGKNos8UAS2bBpvCUt6"

    # In the future, you can add your host's public key here too.
    # It's located at /etc/ssh/ssh_host_ed25519_key.pub
  ];
}
