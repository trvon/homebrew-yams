# Homebrew Yams

[YAMS (Yet Another Memory System)](https://github.com/trvon/yams) Homebrew formulae

## Installation

### Stable Release (Recommended)
```bash
brew install trvon/yams/yams
```

### Nightly Build (Latest Development)
For bleeding-edge features and updates:
```bash
brew install trvon/yams/yams@nightly

# To upgrade to the latest nightly
brew upgrade trvon/yams/yams@nightly
```

**Note:** You can only have one version installed at a time. The nightly and stable versions conflict because they install the same binaries.

## Service Management

Start YAMS daemon as a background service:
```bash
# For stable
brew services start yams

# For nightly
brew services start yams@nightly
```

## More Information

- Homepage: https://github.com/trvon/yams
- Documentation: https://yamsmemory.ai
