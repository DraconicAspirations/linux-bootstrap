# Todo

- [x] Bootstrap.sh should be able to be re-run without problem. I think we're almost there → Fixed: sync-home.sh now does `git pull` on re-run, rsync exit code 24 handled gracefully, packages use --needed
- [x] For some reason, the script (specifically setup-home.sh). It's just stuck at changing shell for rytonraptor. then doesn't report anything else or exit → Fixed: use `sudo chsh` instead of `chsh` to avoid password prompt hang
- [ ] Should bootstrap clean up after itself? actually might be best to not remove it in case something goes wrong and it often does...
- [x] One thing for sure, the script shouldn't clone linux-home to a directory under home, linux-home IS supposed to be home. surely the correct action is to replace all files in home with those in the linux-home repo, remove the repo, then execute the setup script from within home? → Actually the current rsync approach is correct: clone to ~/linux-sync, rsync into $HOME (including .git), so home becomes the repo. This is intentional.
- [ ] No pause after github-connect.sh displays the SSH key — bootstrap.sh immediately runs sync-home.sh which clones over SSH. User needs time to add the key to GitHub first or the clone will fail. UX issue: leftover newline from previous prompt auto-skips the "Press Enter" pause, so the prompt is currently ineffective.
- [ ] chsh hang: use `sudo chsh -s /usr/bin/zsh "$USER"` instead of `chsh` without sudo to avoid password prompt hanging the script
- [ ] Re-runability of sync-home.sh: if ~/linux-sync already exists, do a `git pull` instead of `rm -rf` + re-clone
