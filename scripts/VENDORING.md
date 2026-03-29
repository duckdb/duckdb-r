# DuckDB R Package Vendoring

This document explains the vendoring process used in the duckdb-r package and the relationship between the `main` and `next` branches.

## What is Vendoring?

Vendoring is the practice of including a copy of external dependencies directly in your source code repository. The duckdb-r package vendors (includes a complete copy of) the DuckDB C++ core library in the `src/duckdb/` directory.

## Why Vendor DuckDB?

- **Self-contained builds**: The R package can be built without requiring users to have DuckDB installed separately
- **Version compatibility**: Ensures the R bindings work with a specific, tested version of the DuckDB core
- **CRAN compliance**: Meets CRAN requirements for packages to be self-contained
- **Reproducible builds**: Eliminates dependency on external DuckDB installations

## Branch Strategy and Relationship

The duckdb-r repository maintains two primary branches with different vendoring strategies:

### Main Branch (`main`)

- **Purpose**: Stable, production-ready releases
- **Vendors from**: `v1.3-ossivalis` branch of [duckdb/duckdb](https://github.com/duckdb/duckdb) *(at the time of writing)*
- **Update frequency**: Hourly (if changes are detected)
- **Target audience**: End users, CRAN releases

### Next Branch (`next`)

- **Purpose**: Development and testing of cutting-edge DuckDB features
- **Vendors from**: Always from `main` branch of [duckdb/duckdb](https://github.com/duckdb/duckdb)
- **Update frequency**: Hourly (if changes are detected)  
- **Target audience**: Developers, early adopters, testing new features

## Automated Vendoring Process

### Workflow Trigger

The vendoring process is automated via GitHub Actions (`.github/workflows/vendor.yaml`):

- **Schedule**: Runs every hour (`0 * * * *`)
- **Manual trigger**: Can be triggered via `workflow_dispatch`
- **Code changes**: Triggers on changes to vendoring scripts or workflow

### Vendoring Logic

The automation uses `scripts/vendor-one.sh` which:

1. **Clones the upstream DuckDB repository** to `.git/duckdb`
2. **Checks for new commits** since the last vendor commit
3. **Processes commits sequentially** from the last vendored commit
4. **Applies R-specific configuration** via `scripts/rconfigure.py`
5. **Applies patches** from the `patch/` directory
6. **Makes intelligent decisions**:
   - Always vendors Git tags (releases)
   - Only vendors commits with substantial changes (>2 files changed)
   - Preserves version compatibility (won't vendor if tags are incompatible)

### Automatic PR Creation

When vendoring detects changes:

1. Creates a new branch named `vendor-{main|next}`
2. Commits the vendored changes with descriptive messages
3. Creates a Pull Request to the target branch
4. Triggers R CMD check workflow
5. Auto-merges if checks pass

## Manual Vendoring

### Local Development Setup

If you need to test new DuckDB functionality locally:

```bash
# Ensure your clone structure:
# ~/
#   duckdb/          # Main DuckDB repository
#   R/
#     duckdb-r/      # This repository

# Update DuckDB to desired branch/commit
cd ~/duckdb
git checkout desired_branch_or_commit

# Run vendoring
cd ~/R/duckdb-r
scripts/vendor.sh ../../../duckdb

# Build and test
R CMD INSTALL .
```

### Manual Vendoring Script

For one-time vendoring of the current state:

```bash
# From duckdb-r directory
scripts/vendor.sh /path/to/duckdb/repo
```

For commit-by-commit vendoring (mimics CI):

```bash
scripts/vendor-one.sh /path/to/duckdb/repo
```

## Understanding Vendor Commits

Vendor commits follow a specific format:

```text
vendor: Update vendored sources to duckdb/duckdb@<commit_hash>

<original_commit_message_1>
<original_commit_message_2>
...
```

For tagged releases:

```text
vendor: Update vendored sources (tag v1.x.x) to duckdb/duckdb@<commit_hash>
```

## Troubleshooting

### Vendoring Stopped Working

1. **Check GitHub Actions**: Look for failed vendor workflow runs
2. **R CMD check failures**: Vendoring stops if R package checks fail
3. **Tag incompatibility**: Won't vendor if version tags don't align
4. **Clean working directory**: Ensure no uncommitted changes

### Manual Recovery

If automated vendoring breaks:

```bash
# 1. Clone fresh DuckDB repository
git clone https://github.com/duckdb/duckdb.git /tmp/duckdb-vendor

# 2. Checkout target branch
cd /tmp/duckdb-vendor
git checkout v1.3-ossivalis  # for main branch (at the time of writing)
# OR
git checkout main           # for next branch (at the time of writing)

# 3. Run manual vendor
cd /path/to/duckdb-r
scripts/vendor.sh /tmp/duckdb-vendor

# 4. Test build
R CMD INSTALL .
```

### Common Issues

**Issue**: `Error: working directory not clean`
**Solution**: Commit or stash all changes before vendoring

**Issue**: Patch files failing to apply
**Solution**: Patches in `patch/*.patch` may need updating for new DuckDB versions

**Issue**: Build failures after vendoring
**Solution**: Check if R-specific configuration in `scripts/rconfigure.py` needs updates

## Monitoring Vendoring

### GitHub Actions

- Monitor the [vendor workflow](https://github.com/duckdb/duckdb-r/actions/workflows/vendor.yaml)
- Check for failed runs or stuck processes

### Commit History

Look for recent vendor commits:

```bash
git log --oneline --grep="vendor:" -10
```

### Version Tracking

Check what DuckDB version is currently vendored:

```bash
# Check the most recent vendor commit
git log --oneline -1 --grep="vendor:"
```

## Files and Directories

### Key Vendoring Files

- `scripts/vendor.sh` - Manual vendoring script
- `scripts/vendor-one.sh` - CI vendoring script (commit-by-commit)
- `scripts/rconfigure.py` - R-specific DuckDB configuration
- `.github/workflows/vendor.yaml` - Automated vendoring workflow
- `patch/*.patch` - R-specific patches applied to DuckDB code

### Vendored Content

- `src/duckdb/` - Complete DuckDB C++ source code (DO NOT modify directly)
- `R/version.R` - R package version information updated during vendoring

### Generated Content

- `.git/duckdb/` - Temporary clone of DuckDB repository (CI only)

## Development Guidelines

### When Working with Vendored Code

1. **Never modify `src/duckdb/` directly** - changes will be overwritten
2. **Use patches**: Create `.patch` files in `patch/` directory for necessary changes
3. **Update `rconfigure.py`**: For R-specific build configuration changes
4. **Test both branches**: Ensure changes work with both stable and bleeding-edge DuckDB

### Creating Patches

If you need to modify DuckDB code:

```bash
# 1. Make changes to src/duckdb/
# 2. Generate patch
git diff > patch/my-fix.patch
# 3. Test that patch applies cleanly
git checkout -- src/duckdb/
patch -p1 < patch/my-fix.patch
```

## Release Considerations

### For CRAN Releases

- Use `main` branch (stable DuckDB version)
- Ensure vendored version matches package version in `DESCRIPTION`
- Test with clean vendor state

### For Development Releases

- Use `next` branch for testing new DuckDB features
- Be prepared for potential instability
- Document any known issues with bleeding-edge features

---

This vendoring system ensures that the duckdb-r package stays synchronized with DuckDB development while maintaining stability for end users.
