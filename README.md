# Dotfiles

My dotfiles with the exclusion of the NeoVim config which is stored in a
separate repository.

## How to import

Simply clone the repository:

```bash
git clone git@github.com:BenJurewicz/dotfiles.git ~/dotfiles/
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
