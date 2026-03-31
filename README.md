# Linux Sync

## Setup

Run this: 

```sh
pacman -Syu --noconfirm && \
pacman -S --noconfirm git base-devel && \
git clone https://github.com/DraconicAspirations/linux-bootstrap.git && \
bash linux-bootstrap/bootstrap.sh
```

## Todo: 

- [ ] Boostrap.sh doesn't seem to find script files
- [ ] Zsh should be installed and switched to by default
