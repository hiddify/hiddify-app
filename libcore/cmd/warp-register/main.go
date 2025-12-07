package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"time"

	"github.com/bepass-org/vwarp/masque"
)

func main() {
	var (
		configPath = flag.String("config", "", "Path to save the configuration file")
		deviceName = flag.String("device", "vwarp-test", "Device name for registration")
		timeout    = flag.Duration("timeout", 30*time.Second, "Registration timeout")
	)
	flag.Parse()

	if *configPath == "" {
		// Use default config path
		homeDir, err := os.UserHomeDir()
		if err != nil {
			log.Fatalf("Failed to get home directory: %v", err)
		}
		*configPath = filepath.Join(homeDir, "AppData", "Roaming", "vwarp", "masque_config.json")
	}

	// Ensure directory exists
	dir := filepath.Dir(*configPath)
	if err := os.MkdirAll(dir, 0755); err != nil {
		log.Fatalf("Failed to create config directory: %v", err)
	}

	fmt.Printf("Registering new WARP device: %s\n", *deviceName)
	fmt.Printf("Config will be saved to: %s\n", *configPath)
	fmt.Println()

	ctx, cancel := context.WithTimeout(context.Background(), *timeout)
	defer cancel()

	// Register and get legitimate WARP credentials
	config, err := masque.AutoRegisterOrLoad(ctx, *configPath, *deviceName)
	if err != nil {
		log.Fatalf("Registration failed: %v", err)
	}

	fmt.Println("✅ Registration successful!")
	fmt.Printf("Device ID: %s\n", config.ID)
	fmt.Printf("License: %s\n", config.License)
	fmt.Printf("IPv4: %s\n", config.IPv4)
	fmt.Printf("IPv6: %s\n", config.IPv6)
	fmt.Printf("Endpoint V4: %s\n", config.EndpointV4)
	fmt.Printf("Endpoint V6: %s\n", config.EndpointV6)
	fmt.Printf("Config saved to: %s\n", *configPath)

	// Test loading the saved config
	fmt.Println("\nTesting config loading...")
	loadedConfig, err := masque.LoadMasqueConfig(*configPath)
	if err != nil {
		log.Fatalf("Failed to load saved config: %v", err)
	}

	if loadedConfig.License == "test-license-key" {
		log.Fatalf("❌ Config still contains test values!")
	}

	fmt.Println("✅ Config validation successful!")
	fmt.Println("\nYou can now use this config for MASQUE connections.")
}
