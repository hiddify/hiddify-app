package main

import (
	"context"
	"log"
	"log/slog"
	"os"

	"github.com/bepass-org/vwarp/masque"
	"github.com/bepass-org/vwarp/warp"
)

// Example 1: Auto-registration with MASQUE (like masque-plus)
func ExampleMasqueAutoRegister() {
	ctx := context.Background()
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))

	// This will automatically:
	// 1. Check if config exists
	// 2. If not, register a new device
	// 3. Save the config
	// 4. Connect to MASQUE
	client, err := masque.AutoLoadOrRegister(ctx, "masque_config.json", "vwarp-device", logger)
	if err != nil {
		log.Fatal(err)
	}
	defer client.Close()

	log.Println("MASQUE connected successfully!")

	// Use the client...
	buf := make([]byte, 1500)
	n, err := client.Read(buf)
	if err != nil {
		log.Fatal(err)
	}
	log.Printf("Read %d bytes", n)
}

// Example 2: Auto-registration with options (like masque-plus with flags)
func ExampleMasqueAutoRegisterWithOptions() {
	ctx := context.Background()

	client, err := masque.AutoLoadOrRegisterWithOptions(ctx, masque.AutoRegisterOptions{
		ConfigPath: "./config/masque.json",
		DeviceName: "vwarp-advanced",
		Model:      "PC",
		Locale:     "en_US",
		ForceRenew: false,               // Set to true to force re-registration
		Endpoint:   "162.159.198.1:443", // Custom endpoint
		UseIPv6:    false,
		Logger:     slog.Default(),
	})
	if err != nil {
		log.Fatal(err)
	}
	defer client.Close()

	log.Println("MASQUE connected!")
}

// Example 3: WireGuard auto-registration (like wgcf)
func ExampleWarpAutoRegister() {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))

	// This automatically:
	// 1. Checks if wgcf-identity.json exists
	// 2. If not, creates new identity and registers
	// 3. Saves to wgcf-identity.json
	identity, err := warp.LoadOrCreateIdentity(logger, "./warp_data", "")
	if err != nil {
		log.Fatal(err)
	}

	log.Printf("WireGuard identity loaded: %s", identity.ID)
	log.Printf("IPv4: %s", identity.Config.Interface.Addresses.V4)
	log.Printf("IPv6: %s", identity.Config.Interface.Addresses.V6)
}

// Example 4: WireGuard with license key update
func ExampleWarpWithLicense() {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))

	// Automatically updates license if it differs
	identity, err := warp.LoadOrCreateIdentity(logger, "./warp_data", "your-warp-plus-license")
	if err != nil {
		log.Fatal(err)
	}

	if identity.Account.WarpPlus {
		log.Println("WARP+ enabled!")
	} else {
		log.Println("Free WARP")
	}
}

// Example 5: Combined usage - fallback from MASQUE to WireGuard
func ExampleCombinedAutoRegister() {
	ctx := context.Background()
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))

	// Try MASQUE first
	masqueClient, err := masque.AutoLoadOrRegister(ctx, "masque_config.json", "vwarp", logger)
	if err != nil {
		logger.Warn("MASQUE failed, falling back to WireGuard", "error", err)

		// Fallback to WireGuard
		warpIdentity, err := warp.LoadOrCreateIdentity(logger, "./warp_data", "")
		if err != nil {
			log.Fatal("Both MASQUE and WireGuard failed:", err)
		}

		log.Printf("Using WireGuard: %s", warpIdentity.ID)
		// Use WireGuard...
		return
	}
	defer masqueClient.Close()

	log.Println("Using MASQUE")
	// Use MASQUE...
}

// Example 6: Validate and reset config
func ExampleConfigManagement() {
	// Validate config
	if err := masque.ValidateConfig("masque_config.json"); err != nil {
		log.Printf("Config invalid: %v", err)

		// Delete and re-register
		if err := masque.DeleteConfig("masque_config.json"); err != nil {
			log.Fatal(err)
		}

		log.Println("Config deleted, will auto-register on next connection")
	}
}

// Example 7: Programmatic registration (no auto)
func ExampleManualRegistration() {
	// Manual registration for more control
	cfg, err := masque.RegisterAndEnroll(
		"PC",         // model
		"en_US",      // locale
		"team-token", // optional team token
		"my-device",
		true, // accept TOS
	)
	if err != nil {
		log.Fatal(err)
	}

	// Save to custom location
	if err := masque.SaveConfig(cfg, "/etc/vwarp/masque.json"); err != nil {
		log.Fatal(err)
	}

	log.Printf("Registered: IPv4=%s, IPv6=%s", cfg.IPv4, cfg.IPv6)
}

func main() {
	// Run any example
	ExampleMasqueAutoRegister()
}
