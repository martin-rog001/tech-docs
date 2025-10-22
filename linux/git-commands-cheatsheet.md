# Git Commands Cheat Sheet

Essential Git commands with descriptions and examples for version control.

---

## Getting Started

### `git init` - Initialize Repository
Create a new Git repository.
```bash
git init                                  # Initialize in current directory
git init project-name                     # Create new directory and initialize
git init --bare                           # Create bare repository (for servers)
git init --initial-branch=main            # Set initial branch name
```

### `git clone` - Clone Repository
Copy an existing repository.
```bash
git clone https://github.com/user/repo.git           # Clone via HTTPS
git clone git@github.com:user/repo.git               # Clone via SSH
git clone https://github.com/user/repo.git my-dir    # Clone to specific directory
git clone --depth 1 https://github.com/user/repo.git # Shallow clone (latest commit only)
git clone --branch develop https://github.com/user/repo.git  # Clone specific branch
git clone --recursive https://github.com/user/repo.git       # Clone with submodules
git clone --mirror https://github.com/user/repo.git          # Mirror clone (bare + all refs)
```

### `git config` - Configuration
Configure Git settings.
```bash
# User information
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Default editor
git config --global core.editor "vim"
git config --global core.editor "code --wait"  # VS Code

# Default branch name
git config --global init.defaultBranch main

# View configuration
git config --list                         # All settings
git config --list --show-origin           # With file locations
git config user.name                      # Specific setting
git config --global --list                # Global settings only
git config --local --list                 # Repository settings only

# Edit config file
git config --global --edit                # Edit global config
git config --local --edit                 # Edit repository config

# Aliases
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.st status
git config --global alias.unstage 'reset HEAD --'
git config --global alias.last 'log -1 HEAD'

# Line endings
git config --global core.autocrlf true   # Windows
git config --global core.autocrlf input  # Mac/Linux

# Credential helper
git config --global credential.helper cache
git config --global credential.helper 'cache --timeout=3600'
```

---

## Basic Operations

### `git status` - Check Status
Show working tree status.
```bash
git status                                # Full status
git status -s                             # Short format
git status -sb                            # Short with branch info
git status --ignored                      # Show ignored files
git status -u                             # Show untracked files
```

### `git add` - Stage Changes
Add files to staging area.
```bash
git add file.txt                          # Stage specific file
git add *.js                              # Stage all JS files
git add .                                 # Stage all changes
git add -A                                # Stage all (new, modified, deleted)
git add -u                                # Stage modified and deleted only
git add -p                                # Interactive staging (patch mode)
git add --all                             # Stage everything
git add -n .                              # Dry run (show what would be staged)

# Stage parts of a file
git add -p file.txt                       # Choose hunks to stage
# y - stage this hunk
# n - don't stage
# s - split hunk
# e - manually edit
# q - quit
```

### `git commit` - Commit Changes
Record changes to repository.
```bash
git commit -m "Commit message"            # Commit with message
git commit -am "Message"                  # Stage all and commit
git commit --amend                        # Amend last commit
git commit --amend -m "New message"       # Change last commit message
git commit --amend --no-edit              # Amend without changing message
git commit -v                             # Show diff in commit message editor
git commit --allow-empty -m "Empty"       # Create empty commit

# Multi-line commit message
git commit -m "Title" -m "Description line 1" -m "Description line 2"

# Commit with specific author
git commit --author="Name <email@example.com>" -m "Message"

# Sign commit
git commit -S -m "Signed commit"
```

### `git diff` - Show Changes
Show differences between commits, working tree, etc.
```bash
git diff                                  # Unstaged changes
git diff --staged                         # Staged changes
git diff --cached                         # Same as --staged
git diff HEAD                             # All changes (staged + unstaged)
git diff commit1 commit2                  # Between commits
git diff branch1 branch2                  # Between branches
git diff main...feature                   # Changes in feature since branching
git diff --stat                           # Summary only
git diff --name-only                      # File names only
git diff --name-status                    # File names with status
git diff file.txt                         # Specific file
git diff HEAD~2 HEAD                      # Last 2 commits
git diff --word-diff                      # Word-level diff
git diff --color-words                    # Colored word diff
```

---

## Branching and Merging

### `git branch` - Manage Branches
List, create, or delete branches.
```bash
# List branches
git branch                                # Local branches
git branch -a                             # All branches (local + remote)
git branch -r                             # Remote branches only
git branch -v                             # With last commit
git branch -vv                            # With upstream info

# Create branch
git branch feature-name                   # Create branch
git branch feature-name commit-hash       # Create from specific commit

# Delete branch
git branch -d branch-name                 # Delete (safe, checks if merged)
git branch -D branch-name                 # Force delete
git branch -d -r origin/branch-name       # Delete remote-tracking branch

# Rename branch
git branch -m old-name new-name           # Rename branch
git branch -M old-name new-name           # Force rename

# Branch management
git branch --merged                       # Show merged branches
git branch --no-merged                    # Show unmerged branches
git branch --contains commit-hash         # Branches containing commit
git branch --sort=-committerdate          # Sort by commit date
```

### `git checkout` - Switch Branches
Switch branches or restore files.
```bash
# Switch branches
git checkout branch-name                  # Switch to branch
git checkout -b new-branch                # Create and switch
git checkout -b new-branch origin/main    # Create from remote branch
git checkout -                            # Switch to previous branch
git checkout -B branch-name               # Create/reset and switch

# Restore files
git checkout -- file.txt                  # Discard changes in file
git checkout .                            # Discard all changes
git checkout HEAD file.txt                # Restore from HEAD
git checkout commit-hash file.txt         # Restore from specific commit

# Detached HEAD
git checkout commit-hash                  # Checkout specific commit
git checkout tags/v1.0.0                  # Checkout tag
```

### `git switch` - Switch Branches (modern)
Modern command to switch branches (Git 2.23+).
```bash
git switch branch-name                    # Switch to branch
git switch -c new-branch                  # Create and switch
git switch -                              # Switch to previous branch
git switch -C branch-name                 # Create/reset and switch
git switch --detach commit-hash           # Detached HEAD state
```

### `git restore` - Restore Files (modern)
Modern command to restore files (Git 2.23+).
```bash
git restore file.txt                      # Discard unstaged changes
git restore --staged file.txt             # Unstage file
git restore --source=HEAD~2 file.txt      # Restore from 2 commits ago
git restore --worktree --staged file.txt  # Restore both working tree and index
```

### `git merge` - Merge Branches
Merge branches together.
```bash
git merge branch-name                     # Merge branch into current
git merge --no-ff branch-name             # No fast-forward (create merge commit)
git merge --ff-only branch-name           # Fast-forward only (fail if not possible)
git merge --squash branch-name            # Squash commits
git merge --abort                         # Abort merge
git merge --continue                      # Continue after resolving conflicts

# Merge strategies
git merge -s recursive branch-name        # Recursive strategy (default)
git merge -s ours branch-name             # Keep our changes
git merge -X theirs branch-name           # Prefer their changes
git merge -X ours branch-name             # Prefer our changes
```

### `git rebase` - Rebase Branches
Reapply commits on top of another base.
```bash
git rebase main                           # Rebase current branch onto main
git rebase main feature                   # Rebase feature onto main
git rebase -i HEAD~3                      # Interactive rebase last 3 commits
git rebase -i commit-hash                 # Interactive rebase from commit
git rebase --onto main server client      # Advanced rebase
git rebase --continue                     # Continue after resolving conflicts
git rebase --skip                         # Skip current commit
git rebase --abort                        # Abort rebase
git rebase --autosquash                   # Auto-squash fixup commits

# Interactive rebase commands:
# p, pick = use commit
# r, reword = use commit, but edit message
# e, edit = use commit, but stop for amending
# s, squash = use commit, but meld into previous
# f, fixup = like squash, but discard message
# d, drop = remove commit
```

---

## Remote Repositories

### `git remote` - Manage Remotes
Manage remote repositories.
```bash
# List remotes
git remote                                # List remote names
git remote -v                             # List with URLs
git remote show origin                    # Detailed info about remote

# Add remote
git remote add origin https://github.com/user/repo.git
git remote add upstream https://github.com/original/repo.git

# Remove remote
git remote remove origin
git remote rm origin

# Rename remote
git remote rename old-name new-name

# Change URL
git remote set-url origin https://github.com/user/new-repo.git
git remote set-url --add origin https://github.com/user/another-repo.git

# Prune remote branches
git remote prune origin                   # Remove stale remote-tracking branches
git remote prune origin --dry-run         # Preview what will be removed
```

### `git fetch` - Fetch from Remote
Download objects and refs from remote.
```bash
git fetch                                 # Fetch from default remote
git fetch origin                          # Fetch from origin
git fetch --all                           # Fetch from all remotes
git fetch origin branch-name              # Fetch specific branch
git fetch --prune                         # Remove deleted remote branches
git fetch --tags                          # Fetch all tags
git fetch --depth=1                       # Shallow fetch
git fetch origin --dry-run                # Preview fetch
```

### `git pull` - Fetch and Merge
Fetch from remote and merge.
```bash
git pull                                  # Pull from tracking branch
git pull origin main                      # Pull from specific branch
git pull --rebase                         # Pull with rebase instead of merge
git pull --ff-only                        # Fast-forward only
git pull --no-rebase                      # Merge even if fast-forward possible
git pull --all                            # Pull all branches
git pull origin main --allow-unrelated-histories  # Force pull unrelated histories
```

### `git push` - Push to Remote
Upload local commits to remote.
```bash
git push                                  # Push current branch
git push origin main                      # Push to specific branch
git push -u origin main                   # Push and set upstream
git push --all                            # Push all branches
git push --tags                           # Push all tags
git push origin :branch-name              # Delete remote branch
git push origin --delete branch-name      # Delete remote branch (modern)
git push --force                          # Force push (dangerous!)
git push --force-with-lease               # Safer force push
git push origin tag-name                  # Push specific tag
git push origin --delete tag-name         # Delete remote tag
git push --dry-run                        # Preview push
git push -u origin --all                  # Push all branches and set upstream
```

---

## History and Logs

### `git log` - Show Commit History
Display commit logs.
```bash
git log                                   # Full log
git log --oneline                         # Compact view
git log --graph                           # ASCII graph
git log --all                             # All branches
git log --graph --oneline --all           # Graph of all branches
git log -n 5                              # Last 5 commits
git log --since="2 weeks ago"             # Time-based filter
git log --after="2024-01-01"              # After date
git log --before="2024-01-31"             # Before date
git log --author="John"                   # By author
git log --grep="fix"                      # Search commit messages
git log -S "function_name"                # Search for code changes (pickaxe)
git log -p                                # Show patches (diffs)
git log --stat                            # Show file statistics
git log --pretty=format:"%h - %an, %ar : %s"  # Custom format
git log --follow file.txt                 # Follow file history (renames)
git log branch1..branch2                  # Commits in branch2 not in branch1
git log main...feature                    # Commits in either branch (symmetric difference)

# Pretty formats
git log --pretty=oneline
git log --pretty=short
git log --pretty=full
git log --pretty=fuller

# Custom format placeholders:
# %H - commit hash
# %h - abbreviated hash
# %an - author name
# %ae - author email
# %ad - author date
# %s - subject
# %b - body
```

### `git show` - Show Commit Details
Show various objects.
```bash
git show                                  # Show last commit
git show commit-hash                      # Show specific commit
git show HEAD                             # Show HEAD commit
git show HEAD~2                           # Show 2 commits ago
git show branch-name                      # Show branch tip
git show tag-name                         # Show tag
git show commit-hash:file.txt             # Show file at specific commit
git show --stat commit-hash               # Show with file statistics
git show --pretty=fuller commit-hash      # Detailed view
```

### `git reflog` - Reference Logs
Show reference update history.
```bash
git reflog                                # Show reflog
git reflog show HEAD                      # HEAD reflog
git reflog show branch-name               # Branch reflog
git reflog --all                          # All refs
git reflog expire --expire=30.days        # Expire old entries
git reflog delete ref@{specifier}         # Delete entry
```

### `git blame` - Show File Annotations
Show who changed each line.
```bash
git blame file.txt                        # Show blame
git blame -L 10,20 file.txt               # Lines 10-20 only
git blame -C file.txt                     # Detect lines copied from other files
git blame -w file.txt                     # Ignore whitespace
git blame commit-hash file.txt            # Blame at specific commit
git blame -e file.txt                     # Show email instead of name
```

### `git shortlog` - Summarize Logs
Summarize git log output.
```bash
git shortlog                              # Group by author
git shortlog -s                           # Summary (commit count)
git shortlog -sn                          # Summary, sorted by count
git shortlog --author="John"              # Specific author
git shortlog --since="1 month ago"        # Time range
```

---

## Undoing Changes

### `git reset` - Reset Current HEAD
Reset current HEAD to specified state.
```bash
# Soft reset (keep changes staged)
git reset --soft HEAD~1                   # Undo last commit, keep changes staged
git reset --soft commit-hash              # Reset to commit, keep changes

# Mixed reset (default, unstage changes)
git reset HEAD~1                          # Undo last commit, unstage changes
git reset commit-hash                     # Reset to commit
git reset HEAD file.txt                   # Unstage file

# Hard reset (discard all changes)
git reset --hard HEAD~1                   # Undo last commit, discard changes
git reset --hard commit-hash              # Reset to commit, discard all
git reset --hard origin/main              # Reset to remote state

# Reset specific file
git reset HEAD file.txt                   # Unstage file
git reset commit-hash file.txt            # Reset file to commit
```

### `git revert` - Revert Commits
Create new commit that undoes changes.
```bash
git revert commit-hash                    # Revert specific commit
git revert HEAD                           # Revert last commit
git revert HEAD~3                         # Revert 3rd commit from HEAD
git revert --no-commit HEAD~3..HEAD       # Revert range without committing
git revert --continue                     # Continue after conflicts
git revert --abort                        # Abort revert
git revert -m 1 merge-commit              # Revert merge commit
```

### `git clean` - Remove Untracked Files
Remove untracked files from working tree.
```bash
git clean -n                              # Dry run (show what will be removed)
git clean -f                              # Remove untracked files
git clean -fd                             # Remove untracked files and directories
git clean -fx                             # Remove untracked and ignored files
git clean -fxd                            # Remove everything not tracked
git clean -i                              # Interactive mode
```

---

## Stashing

### `git stash` - Stash Changes
Temporarily save changes.
```bash
# Stash changes
git stash                                 # Stash changes
git stash save "message"                  # Stash with message
git stash -u                              # Include untracked files
git stash -a                              # Include all (untracked + ignored)
git stash --keep-index                    # Stash but keep staged changes

# List stashes
git stash list                            # List all stashes
git stash show                            # Show latest stash
git stash show stash@{1}                  # Show specific stash
git stash show -p                         # Show with diff

# Apply stashes
git stash apply                           # Apply latest stash
git stash apply stash@{1}                 # Apply specific stash
git stash pop                             # Apply and remove latest stash
git stash pop stash@{1}                   # Apply and remove specific stash

# Drop stashes
git stash drop                            # Remove latest stash
git stash drop stash@{1}                  # Remove specific stash
git stash clear                           # Remove all stashes

# Create branch from stash
git stash branch branch-name              # Create branch from stash
git stash branch branch-name stash@{1}    # From specific stash
```

---

## Tagging

### `git tag` - Manage Tags
Create, list, and manage tags.
```bash
# List tags
git tag                                   # List all tags
git tag -l "v1.*"                         # List matching tags
git tag -n                                # With messages

# Create tags
git tag v1.0.0                            # Lightweight tag
git tag -a v1.0.0 -m "Version 1.0.0"     # Annotated tag
git tag -a v1.0.0 commit-hash            # Tag specific commit
git tag -s v1.0.0 -m "Signed version"    # Signed tag

# Show tag
git show v1.0.0                           # Show tag details

# Delete tags
git tag -d v1.0.0                         # Delete local tag
git push origin :refs/tags/v1.0.0         # Delete remote tag
git push origin --delete v1.0.0           # Delete remote tag (modern)

# Push tags
git push origin v1.0.0                    # Push specific tag
git push origin --tags                    # Push all tags
git push --follow-tags                    # Push commits and tags

# Checkout tag
git checkout v1.0.0                       # Checkout tag (detached HEAD)
git checkout -b branch-name v1.0.0        # Create branch from tag
```

---

## Searching

### `git grep` - Search Files
Search for text in tracked files.
```bash
git grep "search_term"                    # Search in all files
git grep -n "search_term"                 # Show line numbers
git grep -i "search_term"                 # Case-insensitive
git grep -w "word"                        # Match whole word
git grep -c "search_term"                 # Count matches per file
git grep "search_term" branch-name        # Search in specific branch
git grep "search_term" commit-hash        # Search in specific commit
git grep -e "pattern1" --and -e "pattern2"  # Multiple patterns
git grep --all-match -e "pat1" -e "pat2"  # All patterns must match
```

---

## Advanced Operations

### `git cherry-pick` - Apply Commits
Apply changes from specific commits.
```bash
git cherry-pick commit-hash               # Apply commit
git cherry-pick commit1 commit2           # Apply multiple commits
git cherry-pick commit1..commit5          # Apply range
git cherry-pick --continue                # Continue after conflicts
git cherry-pick --abort                   # Abort cherry-pick
git cherry-pick --skip                    # Skip current commit
git cherry-pick -n commit-hash            # Cherry-pick without committing
git cherry-pick -x commit-hash            # Add source commit reference
```

### `git bisect` - Binary Search for Bugs
Find commit that introduced a bug.
```bash
git bisect start                          # Start bisect
git bisect bad                            # Mark current as bad
git bisect good commit-hash               # Mark known good commit
# Git will checkout commits for testing
git bisect good                           # Current is good
git bisect bad                            # Current is bad
git bisect reset                          # End bisect, return to original HEAD

# Automated bisect
git bisect start HEAD v1.0
git bisect run ./test.sh                  # Run test script
```

### `git submodule` - Manage Submodules
Manage repository submodules.
```bash
# Add submodule
git submodule add https://github.com/user/repo.git path/to/submodule

# Initialize and update
git submodule init                        # Initialize submodules
git submodule update                      # Update submodules
git submodule update --init               # Init and update
git submodule update --init --recursive   # Include nested submodules
git submodule update --remote             # Update to latest remote commit

# List submodules
git submodule status                      # Show submodule status
git submodule foreach git pull            # Run command in each submodule

# Remove submodule
git submodule deinit path/to/submodule
git rm path/to/submodule
rm -rf .git/modules/path/to/submodule
```

### `git worktree` - Manage Working Trees
Work on multiple branches simultaneously.
```bash
git worktree add ../feature feature-branch   # Add worktree
git worktree add ../hotfix -b hotfix         # Create branch in worktree
git worktree list                            # List worktrees
git worktree remove ../feature               # Remove worktree
git worktree prune                           # Clean up worktree info
```

---

## Collaboration

### `git request-pull` - Generate Pull Request Summary
Generate summary of pending changes.
```bash
git request-pull origin/main ./            # Generate request summary
git request-pull v1.0 https://github.com/user/repo.git main
```

### `git format-patch` - Create Patches
Create patch files from commits.
```bash
git format-patch HEAD~3                   # Last 3 commits
git format-patch -1 commit-hash           # Specific commit
git format-patch main..feature            # All commits in feature
git format-patch --stdout > patch.diff    # Output to file
```

### `git apply` - Apply Patches
Apply patch files.
```bash
git apply patch.diff                      # Apply patch
git apply --check patch.diff              # Check if patch applies
git apply --stat patch.diff               # Show stats
git apply --reverse patch.diff            # Reverse patch
```

### `git am` - Apply Mail Patches
Apply patches from email.
```bash
git am patch.mbox                         # Apply patch
git am --signoff patch.mbox               # Apply with sign-off
git am --continue                         # Continue after conflicts
git am --skip                             # Skip current patch
git am --abort                            # Abort applying patches
```

---

## Repository Maintenance

### `git gc` - Garbage Collection
Cleanup and optimize repository.
```bash
git gc                                    # Run garbage collection
git gc --aggressive                       # Aggressive optimization
git gc --prune=now                        # Prune loose objects immediately
git gc --auto                             # Run if needed
```

### `git fsck` - File System Check
Verify repository integrity.
```bash
git fsck                                  # Check repository
git fsck --full                           # Full check
git fsck --unreachable                    # Show unreachable objects
git fsck --lost-found                     # Write dangling objects to .git/lost-found
```

### `git prune` - Prune Objects
Remove unreachable objects.
```bash
git prune                                 # Prune unreachable objects
git prune --dry-run                       # Preview what will be pruned
git prune --expire=now                    # Prune immediately
```

---

## Inspection

### `git ls-files` - Show Files
Show files in index and working tree.
```bash
git ls-files                              # Tracked files
git ls-files -o                           # Untracked files
git ls-files -i                           # Ignored files
git ls-files -m                           # Modified files
git ls-files -d                           # Deleted files
git ls-files --stage                      # Show staging info
```

### `git describe` - Describe Commits
Give object a human-readable name.
```bash
git describe                              # Describe HEAD
git describe --tags                       # Use any tag
git describe --abbrev=0                   # Only show tag name
git describe commit-hash                  # Describe specific commit
git describe --long                       # Always show full format
```

### `git rev-parse` - Parse Revisions
Parse and show revision information.
```bash
git rev-parse HEAD                        # Show HEAD commit hash
git rev-parse --short HEAD                # Short hash
git rev-parse --abbrev-ref HEAD           # Current branch name
git rev-parse --show-toplevel             # Repository root
git rev-parse main                        # Branch commit hash
```

---

## Archive and Bundle

### `git archive` - Create Archive
Create archive of files from tree.
```bash
git archive --format=zip HEAD > archive.zip           # Zip of HEAD
git archive --format=tar HEAD > archive.tar           # Tar of HEAD
git archive --format=tar.gz HEAD > archive.tar.gz     # Tar.gz of HEAD
git archive --prefix=project/ HEAD > archive.tar      # With prefix
git archive -o archive.zip HEAD                       # Auto-detect format
git archive HEAD path/to/dir > archive.tar            # Specific directory
```

### `git bundle` - Package Repository
Create bundle files.
```bash
git bundle create repo.bundle --all       # Bundle entire repository
git bundle create repo.bundle main        # Bundle specific branch
git bundle create repo.bundle HEAD~10..HEAD  # Last 10 commits
git bundle verify repo.bundle             # Verify bundle
git clone repo.bundle directory           # Clone from bundle
git fetch bundle-file                     # Fetch from bundle
```

---

## Common Workflows

### Starting a New Project
```bash
# Initialize repository
git init my-project
cd my-project

# Configure
git config user.name "Your Name"
git config user.email "your.email@example.com"

# Create files
echo "# My Project" > README.md
git add README.md
git commit -m "Initial commit"

# Add remote and push
git remote add origin https://github.com/user/repo.git
git push -u origin main
```

### Feature Branch Workflow
```bash
# Create feature branch
git checkout -b feature/new-feature

# Make changes
git add .
git commit -m "Add new feature"

# Update from main
git checkout main
git pull
git checkout feature/new-feature
git rebase main

# Push feature
git push -u origin feature/new-feature

# After merge, cleanup
git checkout main
git pull
git branch -d feature/new-feature
git push origin --delete feature/new-feature
```

### Fixing Mistakes
```bash
# Undo last commit (keep changes)
git reset --soft HEAD~1

# Undo last commit (discard changes)
git reset --hard HEAD~1

# Undo changes to file
git checkout -- file.txt

# Unstage file
git reset HEAD file.txt

# Change last commit message
git commit --amend -m "New message"

# Add forgotten files to last commit
git add forgotten-file.txt
git commit --amend --no-edit

# Recover deleted commit
git reflog
git checkout commit-hash
```

### Syncing Fork
```bash
# Add upstream remote
git remote add upstream https://github.com/original/repo.git

# Fetch upstream
git fetch upstream

# Merge upstream changes
git checkout main
git merge upstream/main

# Or rebase
git rebase upstream/main

# Push to your fork
git push origin main
```

---

## Git Aliases

Add to `~/.gitconfig`:
```ini
[alias]
    # Shortcuts
    co = checkout
    br = branch
    ci = commit
    st = status

    # Useful aliases
    unstage = reset HEAD --
    last = log -1 HEAD
    visual = log --graph --oneline --all

    # Advanced
    lg = log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit
    aliases = config --get-regexp alias
    amend = commit --amend --no-edit
    undo = reset HEAD~1 --mixed

    # Show branches sorted by date
    recent = branch --sort=-committerdate

    # Delete merged branches
    cleanup = "!git branch --merged | grep -v '\\*\\|main\\|master' | xargs -n 1 git branch -d"
```

---

## Environment Variables

```bash
# User info
export GIT_AUTHOR_NAME="Your Name"
export GIT_AUTHOR_EMAIL="your.email@example.com"
export GIT_COMMITTER_NAME="Your Name"
export GIT_COMMITTER_EMAIL="your.email@example.com"

# Editor
export GIT_EDITOR=vim

# Pager
export GIT_PAGER=less

# SSH key
export GIT_SSH_COMMAND="ssh -i ~/.ssh/custom_key"

# Trace
export GIT_TRACE=1                        # Enable tracing
export GIT_TRACE_PACKET=1                 # Packet-level tracing
export GIT_TRACE_PERFORMANCE=1            # Performance tracing
```

---

## Troubleshooting

### Common Issues
```bash
# Detached HEAD state
git checkout main                         # Return to branch

# Merge conflicts
git status                                # See conflicted files
# Edit files to resolve conflicts
git add resolved-file.txt
git commit

# Reset to remote state
git fetch origin
git reset --hard origin/main

# Recover lost commits
git reflog
git checkout commit-hash

# Large file issues
git filter-branch --tree-filter 'rm -f large-file' HEAD
# Or use git-filter-repo (recommended)

# Permission denied (public key)
ssh-add ~/.ssh/id_rsa
ssh -T git@github.com

# SSL certificate problem
git config --global http.sslVerify false  # Not recommended for production

# Line ending issues
git config --global core.autocrlf true    # Windows
git config --global core.autocrlf input   # Mac/Linux
```

### Performance
```bash
# Speed up operations
git gc --aggressive
git repack -a -d --depth=250 --window=250

# Shallow clone for large repos
git clone --depth 1 https://github.com/user/repo.git

# Sparse checkout (only specific files/directories)
git clone --filter=blob:none --sparse https://github.com/user/repo.git
cd repo
git sparse-checkout init --cone
git sparse-checkout set dir1 dir2
```

---

## Quick Reference

### Essential Commands
```bash
git status                # Check status
git add file              # Stage file
git commit -m "msg"       # Commit
git push                  # Push to remote
git pull                  # Pull from remote
git clone url             # Clone repository
git log                   # View history
git diff                  # Show changes
```

### Common Flags
```bash
-a, --all                 # All files
-m "message"              # Message
-u, --set-upstream        # Set upstream
-d, --delete              # Delete
-f, --force               # Force
-v, --verbose             # Verbose
-n, --dry-run             # Dry run
--help                    # Help
```

### Commit References
```bash
HEAD                      # Current commit
HEAD~1                    # 1 commit before HEAD
HEAD~2                    # 2 commits before HEAD
HEAD^                     # Parent of HEAD
HEAD^^                    # Grandparent of HEAD
main                      # Branch name
origin/main               # Remote branch
commit-hash               # Specific commit
tag-name                  # Tag name
```
