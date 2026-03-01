#!/bin/bash
# Setup script for GitHub release secrets

set -e

echo "🔐 Terraform Provider Release Setup"
echo "===================================="
echo ""

# Check for GPG keys
echo "Checking for GPG keys..."
if ! gpg --list-secret-keys >/dev/null 2>&1; then
    echo "❌ No GPG keys found!"
    echo "Please create one with: gpg --full-generate-key"
    echo "  - Type: RSA and RSA"
    echo "  - Size: 4096"
    echo "  - Expiration: 0 (does not expire)"
    echo "  - Name/Email: Use your GitHub email"
    exit 1
fi

# List available keys
echo "✅ Available GPG keys:"
gpg --list-secret-keys --keyid-format=long

echo ""
echo "📝 Next Steps:"
echo ""
echo "1. Note your GPG key ID from above (e.g., rsa4096/ABCD1234EFGH5678)"
echo "2. Export your private key:"
echo "   gpg --armor --export-secret-keys YOUR_KEY_ID > gpg-private-key.asc"
echo ""
echo "3. Add GitHub Secrets:"
echo "   Go to: https://github.com/patrikwm/terraform-provider-coolify/settings/secrets/actions"
echo "   "
echo "   Secret 1:"
echo "   - Name: GPG_PRIVATE_KEY"
echo "   - Value: Contents of gpg-private-key.asc"
echo "   "
echo "   Secret 2:"
echo "   - Name: PASSPHRASE"
echo "   - Value: Your GPG key passphrase (empty if none)"
echo ""
echo "4. Add GPG public key to GitHub:"
echo "   gpg --armor --export YOUR_KEY_ID"
echo "   Then paste at: https://github.com/settings/keys"
echo ""
echo "5. Delete the private key file:"
echo "   rm gpg-private-key.asc"
echo ""
echo "6. Create and push the release tag:"
echo "   git tag -a v0.1.0 -m 'Release v0.1.0'"
echo "   git push origin v0.1.0"
echo ""
echo "7. Monitor the release:"
echo "   https://github.com/patrikwm/terraform-provider-coolify/actions"
echo ""
