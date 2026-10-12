#!/usr/bin/env bash
set -e

echo "========================================="
echo "   Git Identity & GPG Setup Script"
echo "========================================="

# 1. Scope (Global vs Local)
read -p "🌍 Do you want to configure this globally (all repos) or locally (current repo only)? [global/local] (default: global): " SCOPE
SCOPE=${SCOPE:-global}

if [[ "$SCOPE" != "global" && "$SCOPE" != "local" ]]; then
  echo "Invalid choice. Defaulting to global."
  SCOPE="global"
fi

if [[ "$SCOPE" == "global" ]]; then
  CONFIG_FLAG="--global"
  echo "✅ Setting up globally..."
else
  if [ ! -d .git ]; then
    echo "❌ Error: You are not in a git repository. Cannot set local config."
    exit 1
  fi
  CONFIG_FLAG="--local"
  echo "✅ Setting up locally for this repository..."
fi

# 2. Name and Email
echo "-----------------------------------------"
read -p "👉 Enter your Git username: " GIT_NAME
read -p "👉 Enter your Git email: " GIT_EMAIL

git config $CONFIG_FLAG user.name "$GIT_NAME"
git config $CONFIG_FLAG user.email "$GIT_EMAIL"
echo "✅ Name and Email configured."

# 3. GPG Setup
echo "-----------------------------------------"
echo "🔍 Looking for GPG secret keys..."
if ! command -v gpg &>/dev/null; then
  echo "⚠️  'gpg' is not installed. Skipping GPG setup."
  echo "   Install it via your package manager (e.g., brew install gnupg, sudo apt install gnupg)."
else
  KEY_IDS=$(gpg --list-secret-keys --keyid-format LONG 2>/dev/null | grep "^sec" | awk '{print $2}' | awk -F'/' '{print $2}')

  if [ -z "$KEY_IDS" ]; then
    echo "⚠️  No GPG secret keys found."
    echo "   To generate one, run: gpg --full-generate-key"
    echo "   Then re-run this script."
  else
    echo "✅ Found the following GPG Keys:"
    # Show a cleaner list of keys and UIDs
    gpg --list-secret-keys --keyid-format LONG | grep -E "^sec|^uid" | sed 's/^/   /'
    echo "-----------------------------------------"
    read -p "👉 Enter the GPG Key ID you want to use: " GPG_KEY_ID

    if [ -n "$GPG_KEY_ID" ]; then
      git config $CONFIG_FLAG user.signingkey "$GPG_KEY_ID"
      git config $CONFIG_FLAG commit.gpgsign true
      git config $CONFIG_FLAG gpg.program gpg
      echo "✅ GPG signing configured!"
      echo "-----------------------------------------"
      echo "🔑 Here is your Public Key. Copy the entire block below:"
      echo ""
      gpg --armor --export "$GPG_KEY_ID"
      echo ""
    fi
  fi
fi

# 4. Final wrap up
echo "========================================="
echo "🎉 Setup complete!"
echo "========================================="
