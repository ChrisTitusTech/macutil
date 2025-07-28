function updateall --description "Update all system packages and tools"
    set -l updated_items
    set -l failed_items
    set -l start_time (date +%s)
    
    # Colors for output
    set -l green (set_color green)
    set -l yellow (set_color yellow)
    set -l red (set_color red)
    set -l blue (set_color blue)
    set -l normal (set_color normal)
    
    echo $blue"╔════════════════════════════════════════════╗"$normal
    echo $blue"║        System Update Tool - Fish           ║"$normal
    echo $blue"║         Updating all packages...           ║"$normal
    echo $blue"╚════════════════════════════════════════════╝"$normal
    echo
    
    # macOS System Updates
    echo $yellow"[1/11] Checking macOS system updates..."$normal
    set -l system_updates (softwareupdate -l 2>&1)
    
    if string match -q "*No new software available*" -- $system_updates
        echo $green"✓ macOS is up to date"$normal
        set -a updated_items "macOS (already up to date)"
    else
        echo "Available macOS updates:"
        echo $system_updates | grep -E "^\s*\*" | sed 's/^[[:space:]]*/  /'
        echo
        echo -n "Do you want to install macOS updates? (may require restart) (y/N): "
        read -l install_macos
        
        if test "$install_macos" = "y" -o "$install_macos" = "Y"
            if sudo softwareupdate -ia
                echo $green"✓ macOS updates installed successfully"$normal
                set -a updated_items "macOS system updates"
            else
                echo $red"✗ macOS update failed"$normal
                set -a failed_items "macOS updates"
            end
        else
            echo $yellow"⚠ Skipping macOS system updates"$normal
        end
    end
    echo
    
    # Homebrew update
    if type -q brew
        echo $yellow"[2/11] Updating Homebrew..."$normal
        if brew update
            echo $green"✓ Homebrew updated successfully"$normal
            set -a updated_items "Homebrew"
            
            echo $yellow"[3/11] Upgrading Homebrew formulae..."$normal
            set -l formulae_before (brew outdated --formula | wc -l | string trim)
            if brew upgrade --formula
                echo $green"✓ Homebrew formulae upgraded successfully"$normal
                set -a updated_items "Homebrew formulae ($formulae_before packages)"
            else
                echo $red"✗ Some formulae failed to upgrade"$normal
                set -a failed_items "Some Homebrew formulae"
            end
            
            echo $yellow"[4/11] Upgrading Homebrew casks..."$normal
            set -l casks_before (brew outdated --cask | wc -l | string trim)
            if brew upgrade --cask --greedy
                echo $green"✓ Homebrew casks upgraded successfully"$normal
                set -a updated_items "Homebrew casks ($casks_before casks)"
            else
                echo $red"✗ Some casks failed to upgrade"$normal
                set -a failed_items "Some Homebrew casks"
            end
            
            # Cleanup old versions
            echo $yellow"Cleaning up old Homebrew versions..."$normal
            brew cleanup
        else
            echo $red"✗ Homebrew update failed"$normal
            set -a failed_items "Homebrew"
        end
    else
        echo $yellow"⚠ Homebrew not found, skipping..."$normal
    end
    echo
    
    # Mac App Store updates
    if type -q mas
        echo $yellow"[5/11] Updating Mac App Store apps..."$normal
        set -l mas_output (mas upgrade 2>&1)
        set -l mas_status $status
        
        if test $mas_status -eq 0
            echo $green"✓ Mac App Store apps updated successfully"$normal
            set -a updated_items "Mac App Store apps"
        else if string match -q "*No downloads began*" -- $mas_output
            echo $red"✗ Some apps cannot be updated (purchased with different Apple ID)"$normal
            echo $yellow"  Please update these apps manually through the App Store app:"$normal
            echo "$mas_output" | grep -E "^[A-Za-z].*\(" | sed 's/^/    /'
            set -a failed_items "Some Mac App Store apps (ownership issue)"
        else
            echo $red"✗ Some Mac App Store apps failed to update"$normal
            echo $mas_output | sed 's/^/    /'
            set -a failed_items "Some Mac App Store apps"
        end
    else
        echo $yellow"⚠ mas (Mac App Store CLI) not found, skipping..."$normal
    end
    echo
    
    # NPM global packages update
    if type -q npm
        echo $yellow"[6/11] Updating NPM global packages..."$normal
        
        if type -q jq
            set -l npm_packages (npm list -g --depth=0 --json 2>/dev/null | jq -r '.dependencies | keys[]' 2>/dev/null)
            
            if test -n "$npm_packages"
                set -l npm_updated 0
                
                # Update packages except npm and corepack
                for package in $npm_packages
                    if test "$package" != "npm" -a "$package" != "corepack"
                        echo "  Updating $package..."
                        if npm install -g $package@latest 2>/dev/null
                            set npm_updated (math $npm_updated + 1)
                        end
                    end
                end
                
                # Then update npm itself
                echo "  Updating npm..."
                if npm install -g npm@latest
                    set npm_updated (math $npm_updated + 1)
                end
                
                echo $green"✓ Updated $npm_updated NPM packages"$normal
                set -a updated_items "NPM global packages ($npm_updated packages)"
            else
                echo $yellow"⚠ No NPM global packages found"$normal
            end
        else
            echo $yellow"⚠ jq is required for NPM updates - please install it"$normal
        end
    else
        echo $yellow"⚠ NPM not found, skipping..."$normal
    end
    echo
    
    # Go modules and tools update
    if type -q go
        echo $yellow"[7/11] Updating Go and Go tools..."$normal
        
        # Update Go tools installed with 'go install'
        set -l go_updated 0
        set -l gopath (go env GOPATH)
        
        if test -d "$gopath/bin"
            # Common Go tools that might be installed
            set -l go_tools gopls goimports golangci-lint dlv staticcheck
            
            for tool in $go_tools
                if type -q $tool
                    echo "  Checking $tool..."
                    switch $tool
                        case gopls
                            if go install golang.org/x/tools/gopls@latest 2>/dev/null
                                set go_updated (math $go_updated + 1)
                            end
                        case goimports
                            if go install golang.org/x/tools/cmd/goimports@latest 2>/dev/null
                                set go_updated (math $go_updated + 1)
                            end
                        case golangci-lint
                            if go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest 2>/dev/null
                                set go_updated (math $go_updated + 1)
                            end
                        case dlv
                            if go install github.com/go-delve/delve/cmd/dlv@latest 2>/dev/null
                                set go_updated (math $go_updated + 1)
                            end
                        case staticcheck
                            if go install honnef.co/go/tools/cmd/staticcheck@latest 2>/dev/null
                                set go_updated (math $go_updated + 1)
                            end
                    end
                end
            end
            
            # Update any other Go binaries in GOPATH/bin
            echo "  Updating other Go tools in $gopath/bin..."
            go get -u all 2>/dev/null
            
            echo $green"✓ Updated $go_updated Go tools"$normal
            set -a updated_items "Go tools ($go_updated tools)"
        else
            echo $yellow"⚠ No Go tools found in GOPATH"$normal
        end
    else
        echo $yellow"⚠ Go not found, skipping..."$normal
    end
    echo
    
    # Rust toolchain update
    if type -q cargo
        echo $yellow"[8/11] Updating Rust toolchain..."$normal
        if type -q rustup
            if rustup update
                echo $green"✓ Rust toolchain updated successfully"$normal
                set -a updated_items "Rust toolchain"
            else
                echo $red"✗ Rust toolchain update failed"$normal
                set -a failed_items "Rust toolchain"
            end
        else
            # Rust installed via Homebrew
            if brew upgrade rust 2>/dev/null
                echo $green"✓ Rust (Homebrew) updated successfully"$normal
                set -a updated_items "Rust (Homebrew)"
            else
                echo $yellow"✓ Rust (Homebrew) is already up to date"$normal
                set -a updated_items "Rust (Homebrew)"
            end
        end
        
        echo $yellow"[9/11] Updating Cargo crates (global tools)..."$normal
        
        # Get list of installed cargo binaries
        set -l cargo_installs (cargo install --list | grep -E "^\S" | awk '{print $1}')
        
        if test -n "$cargo_installs"
            set -l cargo_updated 0
            
            for crate in $cargo_installs
                echo "  Updating $crate..."
                if cargo install $crate 2>/dev/null
                    set cargo_updated (math $cargo_updated + 1)
                end
            end
            
            echo $green"✓ Updated $cargo_updated Cargo crates"$normal
            set -a updated_items "Cargo crates ($cargo_updated crates)"
        else
            echo $yellow"⚠ No global Cargo crates found"$normal
        end
    else
        echo $yellow"⚠ Cargo/Rust not found, skipping..."$normal
    end
    echo
    
    # Flutter update
    if type -q flutter
        echo $yellow"[10/11] Updating Flutter and Dart SDK..."$normal
        set -l flutter_before (flutter --version | head -1)
        if flutter upgrade --force
            set -l flutter_after (flutter --version | head -1)
            echo $green"✓ Flutter upgraded successfully"$normal
            set -a updated_items "Flutter SDK"
            
            # Also run flutter doctor to ensure everything is set up correctly
            echo "Running flutter doctor..."
            flutter doctor
        else
            echo $red"✗ Flutter upgrade failed"$normal
            set -a failed_items "Flutter"
        end
    else
        echo $yellow"⚠ Flutter not found, skipping..."$normal
    end
    echo
    
    # Python pip update (optional)
    if type -q python3
        echo $yellow"[11/11] Python pip packages update"$normal
        echo -n "Do you want to update Python pip packages? (y/N): "
        read -l update_pip
        
        if test "$update_pip" = "y" -o "$update_pip" = "Y"
            # Update pip itself first
            if python3 -m pip install --user --upgrade --break-system-packages pip
                echo $green"✓ pip updated successfully"$normal
                
                # Get list of outdated packages
                set -l outdated_packages (python3 -m pip list --user --outdated --format=json 2>/dev/null | jq -r '.[].name' 2>/dev/null)
                
                if test -n "$outdated_packages"
                    set -l pip_updated 0
                    for package in $outdated_packages
                        echo "  Updating $package..."
                        if python3 -m pip install --user --upgrade --break-system-packages $package 2>/dev/null
                            set pip_updated (math $pip_updated + 1)
                        end
                    end
                    echo $green"✓ Updated $pip_updated pip packages"$normal
                    set -a updated_items "Python pip packages ($pip_updated packages)"
                else
                    echo $green"✓ All pip packages are up to date"$normal
                    set -a updated_items "Python pip (already up to date)"
                end
            else
                echo $red"✗ pip update failed"$normal
                set -a failed_items "pip"
            end
        else
            echo $yellow"⚠ Skipping pip updates"$normal
        end
    else
        echo $yellow"⚠ Python3 not found, skipping pip..."$normal
    end
    echo
    
    # CocoaPods update
    if type -q pod
        echo $yellow"Bonus: Updating CocoaPods..."$normal
        if gem update cocoapods 2>/dev/null
            echo $green"✓ CocoaPods updated successfully"$normal
            set -a updated_items "CocoaPods"
        else
            echo $yellow"⚠ CocoaPods update requires sudo or failed"$normal
        end
    end
    echo
    
    # Calculate elapsed time
    set -l end_time (date +%s)
    set -l elapsed_time (math $end_time - $start_time)
    set -l minutes (math $elapsed_time / 60)
    set -l seconds (math $elapsed_time % 60)
    
    # Summary
    echo $blue"╔════════════════════════════════════════════╗"$normal
    echo $blue"║              Update Summary                ║"$normal
    echo $blue"╚════════════════════════════════════════════╝"$normal
    
    if test (count $updated_items) -gt 0
        echo $green"Successfully updated:"$normal
        for item in $updated_items
            echo "  ✓ $item"
        end
    end
    
    if test (count $failed_items) -gt 0
        echo
        echo $red"Failed to update:"$normal
        for item in $failed_items
            echo "  ✗ $item"
        end
    end
    
    echo
    echo $blue"Time elapsed: $minutes minutes $seconds seconds"$normal
    echo $blue"Update completed at: "(date)$normal
    
    # Return failure count for automation
    return (count $failed_items)
end
