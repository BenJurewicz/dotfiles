# Dotfiles

My dotfiles with the exclusion of the NeoVim config which is stored in a
separate repository.

## How to import

Clone the repository including submodules
(needed to automatically install tpm for tmux)

```bash
git clone --recurse-submodules https://github.com/BenJurewicz/dotfiles.git ~/dotfiles/

```

Enter it:

```bash
cd ~/Documents/Dotfiles
```

And run GNU Stow:

```bash
stow .
```

You can do a trial run that does not change anything with:

```bash
stow -n .
```

## Additional steps

If `bat` is installed remember to run this command so that `bat` will properly
detect the themes:

```bash
bat cache --build
```
