package masque

import (
	"os"
	"path/filepath"
	"runtime"
)

// GetDefaultConfigPath returns the platform-specific default config path
// iOS: Application Support directory
// Android: app data directory
// Windows: %APPDATA%\vwarp
// macOS: ~/Library/Application Support/vwarp
// Linux: ~/.config/vwarp
func GetDefaultConfigPath() string {
	configDir := GetConfigDirectory()
	return filepath.Join(configDir, "masque_config.json")
}

// GetConfigDirectory returns the platform-specific config directory
func GetConfigDirectory() string {
	switch runtime.GOOS {
	case "windows":
		// Windows: %APPDATA%\vwarp
		appData := os.Getenv("APPDATA")
		if appData == "" {
			appData = filepath.Join(os.Getenv("USERPROFILE"), "AppData", "Roaming")
		}
		return filepath.Join(appData, "vwarp")

	case "darwin":
		// macOS: ~/Library/Application Support/vwarp
		home := os.Getenv("HOME")
		if home == "" {
			home = os.Getenv("USERPROFILE")
		}
		return filepath.Join(home, "Library", "Application Support", "vwarp")

	case "linux":
		// Linux: ~/.config/vwarp (XDG Base Directory)
		configHome := os.Getenv("XDG_CONFIG_HOME")
		if configHome == "" {
			home := os.Getenv("HOME")
			if home == "" {
				home = "."
			}
			configHome = filepath.Join(home, ".config")
		}
		return filepath.Join(configHome, "vwarp")

	case "android":
		// Android: Use app's internal storage path
		// This should be passed from the Android app via environment or parameter
		dataDir := os.Getenv("ANDROID_DATA_DIR")
		if dataDir == "" {
			// Fallback to /data/data/com.yourapp.vwarp/files
			// The actual app will need to set this properly
			dataDir = "/data/local/tmp/vwarp"
		}
		return dataDir

	case "ios":
		// iOS: Application Support directory in app sandbox
		// This should be set by the iOS app
		appSupport := os.Getenv("IOS_APP_SUPPORT")
		if appSupport == "" {
			// Fallback - the iOS app should set this properly
			home := os.Getenv("HOME")
			if home != "" {
				return filepath.Join(home, "Library", "Application Support", "vwarp")
			}
			return "./vwarp"
		}
		return filepath.Join(appSupport, "vwarp")

	default:
		// Fallback: current directory
		return "./vwarp"
	}
}

// GetConfigPathWithFallback tries platform-specific path, falls back to current directory
func GetConfigPathWithFallback() string {
	defaultPath := GetDefaultConfigPath()

	// Try to create directory
	dir := filepath.Dir(defaultPath)
	if err := os.MkdirAll(dir, 0755); err != nil {
		// If we can't create the directory, fall back to current directory
		return "masque_config.json"
	}

	return defaultPath
}

// GetMobileConfigPath returns config path for mobile platforms with proper app context
// For Android: pass the app's getFilesDir() path
// For iOS: pass the app's Application Support directory path
func GetMobileConfigPath(appDataDir string) string {
	if appDataDir == "" {
		return GetDefaultConfigPath()
	}
	return filepath.Join(appDataDir, "masque_config.json")
}
