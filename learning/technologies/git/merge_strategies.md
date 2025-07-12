# Git Merge Strategies

## Overview

Git merge strategies determine how Git combines changes from different branches. Understanding these strategies is crucial for maintaining clean project history and effective collaboration.

## Key Concepts

### Merge Conflicts
**Definition:** Occur when two or more branches have made different changes to the same lines in a file, or when one branch deletes a file that another branch modified.

**Resolution:** Merge conflicts must be handled manually by choosing which changes to keep.

### Related Git Commands

**Git Blame:** `git blame <filename>`
- View file line by line, showing the last time each line was changed, by whom, and in which commit
- Useful for tracking down when bugs were introduced

**Interactive Staging:** `git add --patch <filename>`
- Interactively choose which parts (hunks) of changes to stage
- **Hunk:** A contiguous block of changes
- **Use case:** Commit only specific changes within a file

## Merge Strategies

### 1. Fast-Forward Merge

**How it works:** Used when the target branch hasn't diverged from the source branch. Git simply moves the branch pointer forward to the latest commit, creating a linear history with no merge commit.

**When it occurs:** When the target branch has no new commits since the feature branch diverged.

**Key characteristics:**
- Creates linear history without explicit merge commit
- Conflicts are not possible
- Best for small, linear changes that don't require preserving branch history

**Commands:**
```bash
git merge feature-branch                    # Default behavior when possible
git merge --no-ff feature-branch          # Force merge commit even when FF possible
git merge --ff-only feature-branch        # Only allow fast-forward (good for CI/CD safety)
```

**Pros:**
- Simple, clean history
- No merge commit noise
- Good for small, quick fixes or single-commit features

**Cons:**
- Doesn't preserve the fact that a feature was developed in a separate branch
- Harder to understand team collaboration history

### 2. Three-Way Merge

**How it works:** The default strategy when branches have diverged. Git creates a new merge commit that combines changes from both branches using their common ancestor as a reference point.

**Process:** Compares the last common ancestor with changes from both branches to create a new merge commit.

**Key characteristics:**
- Creates explicit merge commit
- Preserves branch history
- Can handle complex scenarios

### 3. Recursive Merge

**How it works:** The traditional default method for three-way merges.

**Features:**
- Recursively merges subtrees when needed
- Can automatically detect file renames
- Handles criss-cross merges effectively

**Criss-cross merge:** When branches merge, diverge, then merge again.

**Command:**
```bash
git merge --strategy=recursive feature-branch    # Legacy default
```

### 4. Merge-ORT (Optimized Recursive Tree)

**Introduction:** Git 2.34 introduced merge-ort as the new default strategy.

**Improvements over recursive:**
- Much faster performance
- More predictable behavior
- Simpler internal architecture
- Better handling of complex merge scenarios

**Command:**
```bash
git merge --strategy=ort feature-branch
```

### 5. Squash Merge

**How it works:** Condenses an entire branch's commit history into a single commit when merging into the main branch.

**Process:** Combines all commits from a feature branch into one commit when merging.

**Command:**
```bash
git merge --squash feature-branch
git commit -m "Implement feature X"    # Required after squash merge
```

**Use case:** Creates cleaner commit history but removes detailed development history.

**Pros:**
- Clean, linear history
- Easier to revert entire features
- Reduces noise in main branch

**Cons:**
- Loses detailed development history
- Makes debugging more difficult
- Loses individual commit context

### 6. Octopus Merge

**How it works:** Allows merging more than two branches simultaneously.

**Limitations:** Only works if no manual conflict resolution is needed.

**Command:**
```bash
git merge branch1 branch2 branch3    # Merge multiple branches at once
```

**Use case:** Suitable for combining many small, independent branches with conflict-free changes.

### 7. Ours Merge

**How it works:** Keeps only the changes from the current branch while ignoring all changes from the merged branch. The other branch's history is preserved, but its content changes are discarded.

**Command:**
```bash
git merge --strategy=ours other-branch
```

**Characteristics:**
- Records a merge commit but discards incoming changes
- Preserves branch history without applying changes
- Useful when you want to mark a branch as merged without applying its changes

### 8. Subtree Merge

**How it works:** Merges one project as a subdirectory of another project while maintaining separate history.

**Use cases:**
- Incorporating external libraries
- Managing subprojects
- Monorepo management
- Dependency management using subtree strategy

**Characteristics:**
- Tracks directory-level changes
- Maintains nested project history
- Alternative to Git submodules

## Pull Requests vs Merge Requests

**Definition:** A mechanism on Git hosting platforms (GitHub, GitLab, etc.) for proposing changes from one branch to another.

**Purpose:**
- Code review process
- Discussion and collaboration
- Automated testing integration
- Quality control before merging

## Strategy Comparison

| Strategy | History Preservation | Complexity | Use Case |
|----------|---------------------|------------|----------|
| Fast-Forward | Linear, no branch history | Simple | Quick fixes, linear development |
| Three-Way/Recursive | Full branch history | Medium | Standard feature development |
| Merge-ORT | Full branch history | Medium | Modern default, better performance |
| Squash | Single commit per feature | Simple | Clean history, feature-based commits |
| Octopus | Multiple branch history | Complex | Multiple small features |
| Ours | History without changes | Simple | Branch absorption without changes |
| Subtree | Nested project history | Complex | Subproject integration |

## Best Practices

1. **Use fast-forward for small, linear changes**
2. **Use squash merge for feature branches to maintain clean history**
3. **Use three-way merge (merge-ort) for preserving detailed development history**
4. **Always use pull requests for code review**
5. **Configure Git to use merge-ort strategy by default**
6. **Use `--no-ff` flag when you want to preserve branch context**

## Common Questions

**Which strategies do you use most often?**
- **Fast-forward:** For hotfixes and small changes
- **Squash merge:** For feature branches in many teams
- **Three-way merge:** For collaborative development where history matters
- **Recursive/Merge-ORT:** Default for most standard merges

**Which strategies are used rarely?**
- **Octopus merge:** Only for specific scenarios with multiple simple branches
- **Ours merge:** Specialized use cases
- **Subtree merge:** When not using Git submodules for subprojects
