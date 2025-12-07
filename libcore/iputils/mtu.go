package iputils

import (
	"fmt"
	"log/slog"
	"net"
	"os/exec"
	"runtime"
	"strconv"
	"strings"
)

// getSystemMTU attempts to get MTU using system commands, returns empty map on failure
func getSystemMTU() map[string]int {
	mtuMap := make(map[string]int)

	switch runtime.GOOS {
	case "windows":
		cmd := exec.Command("netsh", "interface", "ipv4", "show", "subinterfaces")
		output, err := cmd.Output()
		if err != nil {
			return mtuMap
		}

		lines := strings.Split(string(output), "\n")
		for i, line := range lines {
			if i < 3 || strings.TrimSpace(line) == "" {
				continue
			}

			fields := strings.Fields(line)
			if len(fields) >= 2 {
				if mtu, err := strconv.Atoi(fields[0]); err == nil {
					interfaceName := fields[len(fields)-1]
					mtuMap[interfaceName] = mtu
				}
			}
		}

	case "linux":
		cmd := exec.Command("ip", "link", "show")
		output, err := cmd.Output()
		if err != nil {
			return mtuMap
		}

		lines := strings.Split(string(output), "\n")
		for _, line := range lines {
			if strings.Contains(line, "mtu") && strings.Contains(line, ":") {
				parts := strings.Fields(line)
				var interfaceName string
				var mtu int

				for _, part := range parts {
					if strings.Contains(part, ":") {
						interfaceName = strings.TrimSuffix(part, ":")
						break
					}
				}

				for i, part := range parts {
					if part == "mtu" && i+1 < len(parts) {
						if parsedMTU, err := strconv.Atoi(parts[i+1]); err == nil {
							mtu = parsedMTU
							break
						}
					}
				}

				if interfaceName != "" && mtu > 0 {
					mtuMap[interfaceName] = mtu
				}
			}
		}

	case "darwin":
		cmd := exec.Command("ifconfig")
		output, err := cmd.Output()
		if err != nil {
			return mtuMap
		}

		lines := strings.Split(string(output), "\n")
		var currentInterface string

		for _, line := range lines {
			line = strings.TrimSpace(line)

			if !strings.HasPrefix(line, " ") && strings.Contains(line, ":") {
				parts := strings.Fields(line)
				if len(parts) > 0 {
					currentInterface = strings.TrimSuffix(parts[0], ":")
				}
			}

			if currentInterface != "" && strings.Contains(line, "mtu") {
				parts := strings.Fields(line)
				for i, part := range parts {
					if part == "mtu" && i+1 < len(parts) {
						if mtu, err := strconv.Atoi(parts[i+1]); err == nil {
							mtuMap[currentInterface] = mtu
							break
						}
					}
				}
			}
		}
	}

	return mtuMap
}

// DetectAndCheckMTUForMasque detects network MTU and warns if it's too low for MASQUE
func DetectAndCheckMTUForMasque(logger *slog.Logger) {
	logger.Info("Starting MASQUE MTU compatibility check")

	minMTU, maxMTU, interfaces, err := detectNetworkMTU()
	if err != nil {
		logger.Error("Failed to detect network MTU", "error", err)
		logger.Warn("Using default MTU assumption", "default_mtu", 1396)
		return
	}

	actualMinMTU := minMTU

	logger.Info("Network interface MTU analysis",
		"active_interfaces", interfaces,
		"go_detected_min_mtu", minMTU,
		"actual_min_mtu", actualMinMTU,
		"max_mtu", maxMTU)

	if actualMinMTU < 1300 {
		logger.Warn("MASQUE COMPATIBILITY WARNING: Low MTU detected!",
			"limiting_mtu", actualMinMTU,
			"recommended_minimum", 1300)
		logger.Warn("MASQUE may experience timeouts or connection failures with MTU < 1300")
		logger.Warn("Your current MTU is too low for reliable MASQUE operation")

		if runtime.GOOS == "windows" {
			logger.Warn("To fix on Windows: netsh interface ipv4 set subinterface \"Wi-Fi\" mtu=1500")
			logger.Warn("Verify current MTU: netsh interface ipv4 show subinterfaces")
		}
	} else {
		logger.Info("Network interfaces have sufficient MTU for MASQUE",
			"detected_min_mtu", actualMinMTU)
	}
}

// detectNetworkMTU detects the MTU of active network interfaces using system commands when possible
func detectNetworkMTU() (minMTU int, maxMTU int, interfaceInfo []string, err error) {
	// First try to get system MTU values using appropriate commands
	systemMTU := getSystemMTU()

	// Get Go's interface detection for comparison and fallback
	interfaces, err := net.Interfaces()
	if err != nil {
		return 1396, 1396, []string{"fallback"}, fmt.Errorf("failed to get network interfaces: %w", err)
	}

	minMTU = 9999
	maxMTU = 0
	activeCount := 0

	for _, iface := range interfaces {
		// Skip loopback and inactive interfaces
		if iface.Flags&net.FlagLoopback != 0 || iface.Flags&net.FlagUp == 0 {
			continue
		}

		// Skip interfaces without addresses
		addrs, err := iface.Addrs()
		if err != nil || len(addrs) == 0 {
			continue
		}

		// Try to use system MTU first, fallback to Go's detection
		mtuValue := iface.MTU // Default fallback
		if systemValue, exists := systemMTU[iface.Name]; exists {
			mtuValue = systemValue // Use actual system value
		}

		if mtuValue <= 0 {
			continue // Skip interfaces with invalid MTU
		}

		activeCount++
		source := "go"
		if _, exists := systemMTU[iface.Name]; exists {
			source = "system"
		}
		interfaceInfo = append(interfaceInfo, fmt.Sprintf("%s:%d(%s)", iface.Name, mtuValue, source))

		if mtuValue < minMTU {
			minMTU = mtuValue
		}
		if mtuValue > maxMTU {
			maxMTU = mtuValue
		}
	}

	if activeCount == 0 {
		return 1396, 1396, []string{"no_active_interfaces"}, fmt.Errorf("no active network interfaces found")
	}

	return minMTU, maxMTU, interfaceInfo, nil
}
