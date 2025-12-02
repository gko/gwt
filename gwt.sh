_gwt_jump_to_default() {
  local default_branch=""
  local worktree_path=""

  default_branch=$(git symbolic-ref -q refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')

  if [ -z "$default_branch" ]; then
    default_branch=$(git remote show origin 2>/dev/null | awk -F': ' '/HEAD branch/ {print $2; exit}')
  fi

  if [ -z "$default_branch" ]; then
    for b in main master; do
      if git show-ref --verify --quiet "refs/heads/$b"; then
        default_branch="$b"
        break
      fi
    done
  fi

  if [ -n "$default_branch" ]; then
    worktree_path=$(git worktree list | awk -v b="$default_branch" 'index($0, "[" b "]") {print $1; exit}')
  fi

  if [ -z "$worktree_path" ]; then
    for b in ${default_branch:-main master}; do
      worktree_path=$(git worktree list | awk -v b="$b" 'index($0, "[" b "]") {print $1; exit}')
      if [ -n "$worktree_path" ]; then
        default_branch="$b"
        break
      fi
    done
  fi

  if [ -n "$worktree_path" ]; then
    echo "Jumping to default branch ('$default_branch') worktree..."
    cd "$worktree_path"
  else
    echo "Default branch worktree not found. Jumping to the main repository folder."
    cd "$(git rev-parse --show-toplevel)"
  fi
}

_gwt_print_help() {
  cat <<'EOF'
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
EOF
}

# git worktree manager
# Usage:
#   gwt              - Interactively cd into any worktree using fzf.
#   gwt add <branch> - Create a new worktree and jump into it.
#   gwt main         - Jump to the default branch worktree (or the main repo folder).
#   gwt <branch>     - Jump directly to the worktree for the specified branch.
#   gwt remove       - Interactively select and remove a worktree.
gwt() {
  if [ -z "$1" ]; then
    local fzf_opts="--height 40% --layout=reverse --preview 'git -C {1} --no-pager status'"
    local worktree_line
    worktree_line=$(git worktree list | eval fzf "$fzf_opts")

    if [ -n "$worktree_line" ]; then
      local worktree_path
      worktree_path=$(echo "$worktree_line" | awk '{print $1}')
      cd "$worktree_path"
    fi
    return
  fi

  case "$1" in
    -h|--help)
      _gwt_print_help
      ;;

    add)
      local branch_to_add="$2"
      if [ -z "$branch_to_add" ]; then
        echo "Error: Please specify a branch name to create a worktree from." >&2; return 1
      fi
      local current_folder_name
      current_folder_name=$(basename "$(pwd)")
      local sanitized_branch_name
      sanitized_branch_name=$(echo "$branch_to_add" | sed 's/\//_/g')
      local new_worktree_path="../${current_folder_name}_${sanitized_branch_name}"

      if [ -e "$new_worktree_path" ]; then
        echo "Error: A directory already exists at '$new_worktree_path'." >&2; return 1
      fi

      if git rev-parse --verify "$branch_to_add" >/dev/null 2>&1 || \
         git rev-parse --verify "origin/$branch_to_add" >/dev/null 2>&1; then
        echo "Creating worktree for branch '$branch_to_add' at '$new_worktree_path'..."
        if git worktree add "$new_worktree_path" "$branch_to_add"; then
          cd "$new_worktree_path"
        fi
      else
        printf "Branch '%s' does not exist. Create it? [y/N] " "$branch_to_add"
        read -r REPLY
        if [[ "$REPLY" =~ ^[Yy]$ ]]; then
          echo "Creating new branch '$branch_to_add' and worktree at '$new_worktree_path'..."
          if git worktree add -b "$branch_to_add" "$new_worktree_path"; then
            cd "$new_worktree_path"
          fi
        else
          echo "Cancelled."
          return 1
        fi
      fi
      ;;

    main|master)
      _gwt_jump_to_default
      ;;

    remove)
      local force_flag=""
      if [ "$2" = "-f" ] || [ "$2" = "--force" ]; then
        force_flag="-f"
      fi
      local fzf_opts="--height 40% --layout=reverse --preview 'git -C {1} --no-pager status'"
      printf "Select a worktree to REMOVE:\n"
      local worktree_line
      worktree_line=$(git worktree list | eval fzf "$fzf_opts")

      if [ -n "$worktree_line" ]; then
        local worktree_path_to_remove
        worktree_path_to_remove=$(echo "$worktree_line" | awk '{print $1}')

        printf "Permanently remove worktree '%s'? [y/N] " "$worktree_path_to_remove"
        read -r REPLY

        case "$REPLY" in
          [Yy]*)
            local prev_pwd
            prev_pwd=$(pwd)
            local common_dir
            common_dir=$(git -C "$worktree_path_to_remove" rev-parse --git-common-dir 2>/dev/null)
            local main_repo_path
            if [ -n "$common_dir" ]; then
              main_repo_path=$(cd "$common_dir/.." && pwd)
            else
              main_repo_path=$(git rev-parse --show-toplevel)
            fi

            cd "$main_repo_path" || { echo "Error: failed to cd to main repository at '$main_repo_path'." >&2; return 1; }

            echo "Removing worktree..."
            if [ -n "$force_flag" ]; then
              if git worktree remove -f "$worktree_path_to_remove"; then
                echo "Switching to folder: $main_repo_path"
              else
                if [ "$prev_pwd" != "$main_repo_path" ]; then
                  cd "$prev_pwd"
                fi
                echo "Error: failed to remove worktree. You may try 'gwt remove -f'." >&2
              fi
            else
              if git worktree remove "$worktree_path_to_remove"; then
                echo "Switching to folder: $main_repo_path"
              else
                if [ "$prev_pwd" != "$main_repo_path" ]; then
                  cd "$prev_pwd"
                fi
                echo "Error: failed to remove worktree. You may try 'gwt remove -f'." >&2
              fi
            fi
            ;;
          *) echo "Removal cancelled." ;;
        esac
      fi
      ;;

    *)
      local branch_name="$1"
      local worktree_path_for_branch
      worktree_path_for_branch=$(git worktree list | awk -v b="$branch_name" 'index($0, "[" b "]") {print $1; exit}')

      if [ -n "$worktree_path_for_branch" ]; then
        echo "Jumping to worktree for branch '$branch_name'..."
        cd "$worktree_path_for_branch"
      else
        echo "Error: No worktree found for branch '$branch_name'." >&2; return 1
      fi
      ;;
  esac
}
