# nix-misskey

This project uses Nix for development environment management of [Misskey](https://github.com/misskey-dev/misskey).

1. Install Nix: https://nixos.org/download.html

2. Enable flakes:

```bash
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

3. Install direnv

4. Setup development environment:

```bash
git clone --recursive https://github.com/misskey-dev/misskey.git misskey
cd misskey
git clone https://github.com/hitalin/nix-misskey .nix-misskey
```

```bash
echo "use flake ./.nix-misskey#default" > .envrc
direnv allow
```

5. Start development

```bash
nix-misskey setup
nix-misskey start
```
