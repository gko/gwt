# gwt — A Git Worktree Manager

`gwt` is a simple command-line tool to help you manage your Git worktrees with ease. It simplifies the process of creating, navigating, and removing worktrees.

You can read more about `git worktree` here: https://dev.to/konstantin/checking-out-multiple-branches-at-the-same-time-in-git-and-moving-files-between-them-31hk

## Features

* **Interactive Navigation**: Quickly jump between worktrees using an fzf-powered menu. 
* **Quick Add**: Create a new worktree from an existing branch and switch to it in one command. If the branch doesn't exist, it will offer to create it.
* **Easy Removal**: Interactively select and remove worktrees. 
* **Direct Access**: Jump directly to a worktree for a specific branch. 
* **Main Branch Shortcut**: Instantly navigate to the worktree of your repository's default branch (main or master). 
* **Zsh Completion**: Tab completion for commands and branch names in Zsh.

## Installation

You will need to install [fzf](https://github.com/junegunn/fzf) (see this [installation instructions](https://github.com/junegunn/fzf?tab=readme-ov-file#installation)) for the interactive features.

### With [zinit](https://github.com/zdharma-continuum/zinit)

In your `.zshrc`:
```shell
zinit light gko/gwt
```

### With [antigen](https://github.com/zsh-users/antigen)

In your `.zshrc`:
```shell
antigen bundle gko/gwt
```

### Manual

1. Clone this repository or download the gwt.sh script. 
```shell
git clone https://github.com/gko/gwt.git
```

2. Source the gwt.sh script in your shell's configuration file (e.g., `~/.bashrc`, `~/.zshrc`). Add the following line: 
```shell
# Make sure to use the correct path to where you cloned the repo 
source /path/to/gwt/gwt.sh
```

3. Restart your shell or source the configuration file for the changes to take effect: 
```shell
source ~/.zshrc 
```
or 
```shell
source ~/.bashrc
```

#### Zsh Completion

For Zsh users, gwt comes with a completion script for commands and branch names.

1. Make sure the `_gwt.zsh_completion` file is in a directory that is part of your Zsh `fpath`. You can check your `fpath` with echo `$fpath`. A common location is a custom completions directory like `~/.zsh/completions`. 
2. If you don't have a custom completions directory, you can create one and add it to your `~/.zshrc`: 
```shell
mkdir -p ~/.zsh/completions  
# Add this to your .zshrc, before the line that sources oh-my-zsh if you use it  
fpath=($HOME/.zsh/completions $fpath)
```

3. Copy or symlink the `_gwt.zsh_completion` file into that directory. 
```shell
# Rename it to '_gwt' so Zsh can find it 
cp /path/to/gwt/_gwt.zsh_completion ~/.zsh/completions/_gwt
```

4. Restart your shell. You should now have tab completion for gwt commands.

## Usage

```
Usage: gwt [command]
Example:
  gwt               interactively choose a worktree and cd into it
  gwt add <branch>  create a new worktree for <branch> and cd into it
  gwt main          jump to default branch worktree (or repo root)
  gwt master        alias of 'gwt main'
  gwt <branch>      jump to the worktree for <branch>
  gwt remove [-f|--force]
                     interactively remove a worktree (force removal with -f)
Options:
  -h, --help        show this help
```

## License

This project is open source and available under the [GPLv3](/LICENSE) license.
