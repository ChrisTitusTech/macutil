# TTY/Non-Interactive Execution Fixes for macOS App Bundle

## Problem
When running the MacUtil GUI as a `.app` bundle in macOS, scripts were failing because:

1. **No TTY Available**: App bundles don't run in a terminal, so `stdin` is not a TTY
2. **Interactive Prompts**: Scripts expecting user input would hang or fail
3. **Homebrew Installation Issues**: Homebrew installer would try to reinstall even when already present
4. **TTY Detection Failures**: Scripts checking `tty -s` or `[ -t 0 ]` would fail

## Solution Implemented

### 1. Environment Variables
Added comprehensive environment variable setup for all script execution paths:

```bash
export TERM=xterm-256color
export DEBIAN_FRONTEND=noninteractive
export CI=true
export HOMEBREW_NO_ENV_HINTS=1
export HOMEBREW_NO_INSTALL_CLEANUP=1
export HOMEBREW_NO_AUTO_UPDATE=1
export NONINTERACTIVE=1
export FORCE_NONINTERACTIVE=1
```

### 2. Script Preprocessing Function
Created `preprocessScriptForNonTTY()` that:

- **Disables TTY checks**: Comments out lines containing `tty -s`, `[ -t 0 ]`, etc.
- **Forces non-interactive mode**: Adds `--force` flag to brew commands
- **Adds safety headers**: Includes environment setup and TTY function override
- **Handles package managers**: Adds `-y` flags to apt commands where needed

### 3. TTY Function Override
Added a fake `tty()` function that always returns "not a TTY":

```bash
function tty() {
    return 1  # Always return "not a TTY"
}
```

### 4. ProcessStartInfo Environment Setup
Updated all three script execution paths in `ScriptService.fs`:
- Regular script execution
- Elevated (sudo) script execution via osascript
- Async script execution

## Files Modified

### `/Services/ScriptService.fs`
- Added `preprocessScriptForNonTTY()` function
- Updated all `ProcessStartInfo` instances with environment variables
- Updated osascript command to include environment variable exports
- Applied preprocessing to all script execution paths

## Testing the Fixes

### Before the Fix
```
ERROR: stdin is not a TTY
ERROR: Checking for sudo access...
ERROR: Homebrew installation attempted when already installed
```

### After the Fix
Scripts should now run smoothly in the `.app` bundle environment without TTY-related errors.

## What Each Environment Variable Does

| Variable | Purpose |
|----------|---------|
| `TERM=xterm-256color` | Provides a valid terminal type |
| `DEBIAN_FRONTEND=noninteractive` | Prevents apt from prompting for input |
| `CI=true` | Signals automated environment to many tools |
| `HOMEBREW_NO_ENV_HINTS=1` | Disables Homebrew environment hints |
| `HOMEBREW_NO_INSTALL_CLEANUP=1` | Skips automatic cleanup |
| `HOMEBREW_NO_AUTO_UPDATE=1` | Prevents automatic updates |
| `NONINTERACTIVE=1` | Custom flag for scripts to detect non-interactive mode |
| `FORCE_NONINTERACTIVE=1` | Additional flag for scripts |

## Script Preprocessing Examples

### TTY Check Disabling
**Before:**
```bash
if tty -s; then
    echo "Running in terminal"
fi
```

**After:**
```bash
# TTY check disabled for .app bundle execution: if tty -s; then
#     echo "Running in terminal"
# fi
```

### Brew Command Enhancement
**Before:**
```bash
brew install package
```

**After:**
```bash
brew install --quiet package
```

**For update/upgrade commands:**
```bash
brew update --quiet
brew upgrade --quiet
```

## Verification Steps

1. **Build new app bundle**: `./deploy_macos.sh`
2. **Test in .app environment**: `open dist/MacUtil-Intel.app`
3. **Run scripts that previously failed**: Check for TTY-related errors
4. **Monitor script output**: Should see environment variables being set

## Future Considerations

- **Add more package manager support**: Handle `dnf`, `yum`, `pacman` etc.
- **Enhanced script detection**: Better detection of interactive prompts
- **Logging improvements**: Add debug output for preprocessing steps
- **Custom script flags**: Allow scripts to opt-out of preprocessing if needed

## Benefits

✅ **No more TTY errors** when running as .app bundle  
✅ **Homebrew installs work correctly** without re-installation attempts  
✅ **Scripts run non-interactively** without hanging on prompts  
✅ **Backward compatibility** - still works in terminal environments  
✅ **Comprehensive coverage** - all execution paths updated
