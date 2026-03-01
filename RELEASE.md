# Creating a GitHub Release for Terraform Provider Coolify

This guide walks you through creating a GitHub release for this Terraform provider.

## Prerequisites

### 1. GPG Key Setup (Required for Terraform Registry)

Terraform Registry requires all provider releases to be signed with a GPG key.

#### Create a GPG Key (if you don't have one)

```bash
# Generate a new GPG key
gpg --full-generate-key

# Select:
# - Kind: (1) RSA and RSA
# - Keysize: 4096
# - Expiration: 0 (does not expire) or your preference
# - Enter your name and email (use the same email as your GitHub account)
```

#### Export Your GPG Key

```bash
# List your keys and note the key ID
gpg --list-secret-keys --keyid-format=long

# Example output:
# sec   rsa4096/ABCD1234EFGH5678 2024-01-01 [SC]
#       1234567890ABCDEF1234567890ABCDEF12345678
# uid                 [ultimate] Your Name <your.email@example.com>
# ssb   rsa4096/9876543210FEDCBA 2024-01-01 [E]

# The key ID is: ABCD1234EFGH5678 (or the full fingerprint)

# Export the private key (ASCII armored)
gpg --armor --export-secret-keys ABCD1234EFGH5678 > gpg-private-key.asc

# Get the fingerprint (needed for signing)
gpg --list-keys --fingerprint ABCD1234EFGH5678
```

### 2. Add GitHub Secrets

Add the following secrets to your GitHub repository:

1. Go to: https://github.com/patrikwm/terraform-provider-coolify/settings/secrets/actions
2. Click "New repository secret"
3. Add these secrets:

   - **Name:** `GPG_PRIVATE_KEY`
     - **Value:** Contents of `gpg-private-key.asc` file
   
   - **Name:** `PASSPHRASE`
     - **Value:** Your GPG key passphrase (leave empty if no passphrase)

**Important:** Delete the `gpg-private-key.asc` file after adding to GitHub:
```bash
rm gpg-private-key.asc
```

### 3. Add GPG Public Key to GitHub Profile

For Terraform Registry to verify signatures:

```bash
# Export your public key
gpg --armor --export ABCD1234EFGH5678

# Copy the output and add it to:
# https://github.com/settings/keys -> "New GPG key"
```

## Creating a Release

### Step 1: Ensure Your Code is Ready

```bash
# Make sure you're on main and up to date
git checkout main
git pull origin main

# Run tests
make test

# Optionally run acceptance tests (requires COOLIFY_TOKEN)
make testacc
```

### Step 2: Update CHANGELOG.md

The CHANGELOG already has v0.1.0 prepared. If you need to make changes:

```bash
# Edit CHANGELOG.md
# Move items from [Unreleased] to [0.1.0] - YYYY-MM-DD
# Create a new [Unreleased] section
```

### Step 3: Create and Push a Tag

```bash
# Create an annotated tag (e.g., v0.1.0)
git tag -a v0.1.0 -m "Release v0.1.0"

# Push the tag to GitHub
git push origin v0.1.0
```

### Step 4: Monitor the Release Workflow

1. Go to: https://github.com/patrikwm/terraform-provider-coolify/actions
2. Watch for the "Release" workflow to start
3. The workflow will:
   - Build binaries for multiple platforms
   - Sign them with your GPG key
   - Create a draft release on GitHub
   - Generate a changelog

### Step 5: Publish the Release

1. Go to: https://github.com/patrikwm/terraform-provider-coolify/releases
2. Find your draft release
3. Review the generated changelog and assets
4. Click "Publish release"

## Using the Released Provider in Terraform

After publishing, you can use the provider in several ways:

### Option 1: Direct from GitHub (Immediate)

Create a `~/.terraformrc` file:

```hcl
provider_installation {
  filesystem_mirror {
    path    = "/usr/local/share/terraform/plugins"
    include = ["github.com/patrikwm/coolify"]
  }
  direct {
    exclude = ["github.com/patrikwm/coolify"]
  }
}
```

Then download and install manually:

```bash
# Create directory structure
VERSION="0.1.0"
OS="darwin"  # or linux, windows
ARCH="arm64" # or amd64

mkdir -p ~/.terraform.d/plugins/github.com/patrikwm/coolify/${VERSION}/${OS}_${ARCH}

# Download from release
cd ~/.terraform.d/plugins/github.com/patrikwm/coolify/${VERSION}/${OS}_${ARCH}
curl -LO https://github.com/patrikwm/terraform-provider-coolify/releases/download/v${VERSION}/terraform-provider-coolify_${VERSION}_${OS}_${ARCH}.zip

# Extract
unzip terraform-provider-coolify_${VERSION}_${OS}_${ARCH}.zip
chmod +x terraform-provider-coolify_v${VERSION}
```

In your Terraform code:

```hcl
terraform {
  required_providers {
    coolify = {
      source  = "github.com/patrikwm/coolify"
      version = "~> 0.1.0"
    }
  }
}

provider "coolify" {
  # Configuration here
}
```

### Option 2: Publish to Terraform Registry (Recommended)

For public use, publish to the Terraform Registry:

1. Sign in to https://registry.terraform.io with your GitHub account
2. Click "Publish" → "Provider"
3. Select your repository: `patrikwm/terraform-provider-coolify`
4. The registry will:
   - Verify your GPG signature
   - Pull releases from GitHub
   - Generate documentation from your `docs/` directory

Once published, users can reference it directly:

```hcl
terraform {
  required_providers {
    coolify = {
      source  = "patrikwm/coolify"
      version = "~> 0.1.0"
    }
  }
}
```

### Option 3: Local Development Override

For testing during development, create `~/.terraformrc`:

```hcl
provider_installation {
  dev_overrides {
    "patrikwm/coolify" = "/Users/patrik/go/bin"
  }
  
  # For all other providers, install them directly from their origin provider
  # registries as normal.
  direct {}
}
```

Then install locally:
```bash
make install
```

## Troubleshooting

### GPG Signing Fails

- Ensure `GPG_PRIVATE_KEY` secret contains the complete ASCII-armored key
- Verify `PASSPHRASE` secret is correct
- Check the GitHub Actions logs for specific errors

### Release Workflow Doesn't Trigger

- Ensure the tag starts with `v` (e.g., `v0.1.0`)
- Check that you pushed the tag: `git push origin v0.1.0`
- Verify GitHub Actions are enabled for your repository

### Binary Build Fails

- Check Go version compatibility in `go.mod`
- Review GoReleaser configuration in `.goreleaser.yml`
- Check GitHub Actions logs for specific errors

## Next Steps

1. **Documentation**: Ensure `docs/` directory is up to date
2. **Examples**: Verify `examples/` directory has working examples
3. **Testing**: Run acceptance tests before each release
4. **Versioning**: Follow [Semantic Versioning](https://semver.org/)
   - MAJOR: Breaking changes
   - MINOR: New features (backward compatible)
   - PATCH: Bug fixes

## Automated Releases

You can also trigger releases manually:

1. Go to: https://github.com/patrikwm/terraform-provider-coolify/actions/workflows/release.yml
2. Click "Run workflow"
3. Enter the tag name (e.g., `v0.1.1`)
4. Click "Run workflow"

This is useful for testing the release process without creating a tag first.

## References

- [Terraform Provider Publishing](https://developer.hashicorp.com/terraform/registry/providers/publishing)
- [GoReleaser Documentation](https://goreleaser.com/)
- [GPG Documentation](https://docs.github.com/en/authentication/managing-commit-signature-verification)
