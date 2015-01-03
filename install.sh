#!/bin/bash

# Prompt client for install
read -p "Would you like to setup your dev machine? (y/n)" PROMPT

# Exit if install not confirmed
if [[ $PROMPT != "Y" && $PROMPT != "y" ]]; then
    exit
fi

echo "Starting setup..."

# Install XCode Command Line Tools
xcode-select --install

# Check for Homebrew & install if not found
if test ! "$(which brew)"; then
    echo "Installing homebrew..."
    ruby <(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)
fi

# Update Homebrew recipes & check status
brew update
brew doctor

# Install binaries with Homebrew
binaries=(
    git
    gh
    tmux
    shellcheck
    tree
    postgres
    redis
    rbenv
    rbenv-gem-rehash
    ruby-build
    nvm
)

echo "Installing binaries..."
brew install "${binaries[@]}"

# Set git to use the osxkeychain credential helper
git config --global credential.helper osxkeychain

# update ~/.bashrc to put Homebrew's nvm in PATH
printf "\nsource $(brew --prefix nvm)/nvm.sh" >> ~/.bashrc

# Restart launchctl for Postgres
brew_launchctl_restart() {
    local name="$(brew_expand_alias "$1")"
    local domain="homebrew.mxcl.$name"
    local plist="$domain.plist"

    mkdir -p "$HOME/Library/LaunchAgents"
    ln -sfv "/usr/local/opt/$name/$plist" "$HOME/Library/LaunchAgents"

    if launchctl list | grep -q "$domain"; then
        launchctl unload "$HOME/Library/LaunchAgents/$plist" >/dev/null
    fi
    launchctl load "$HOME/Library/LaunchAgents/$plist" >/dev/null
}
brew_expand_alias() {
  brew info "$1" 2>/dev/null | head -1 | awk '{gsub(/:/, ""); print $1}'
}
echo "Restarting Postgres..."
brew_launchctl_restart postgresql

# Update Ruby to latest version (currently 2.1.5)
echo "Updating Ruby..."
rbenv install 2.1.5
rbenv global 2.1.5
gem update --system

# Install Node.js with nvm
echo "Installing Node..."
source $(brew --prefix nvm)/nvm.sh
nvm install stable
nvm use stable
nvm alias default stable

# NPM global packages
echo "Installing global npm packages..."
npm install -g yo
npm install -g gulp
npm install -g bower
npm install -g nodemon
npm install -g grunt-cli
npm install -g phantomjs

# Homebrew-cask
echo "Installing Homebrew-cask and OS X applications..."
brew install caskroom/cask/brew-cask

# Install applications with Homebrew-Cask
apps=(
    google-chrome
    firefox
    opera
    atom
    sourcetree
    sequel-pro
    pgadmin3
    virtualbox
    vagrant
    vagrant-manager
    dropbox
    skype
    vlc
    spotify
    cheatsheet
    qlcolorcode
    qlstephen
    qlmarkdown
    quicklook-json
    quicklook-csv
    betterzipql
    suspicious-package
)

brew cask install "${apps[@]}"

# Clean up after installation
brew cleanup

echo "We're done!"
