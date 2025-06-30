# nix-misskey

This project uses Nix for development environment management of Misskey.

1. Install Nix: https://nixos.org/download.html

2. Enable flakes:

```bash
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

3. Install direnv

4. Setup development environment:

```bash
git clone --recursive https://github.com/yamisskey/yamisskey.git misskey
cd misskey
git clone https://github.com/hitalin/nix-misskey .nix-misskey
```

```bash
echo "use flake" >> .envrc
```

in bash
```bash
nix develop ./.nix-misskey#default
```
in zsh
```bash
nix develop ./.nix-misskey"#default"
```

5. Start development

```bash
nix-misskey setup
nix-misskey start
```
