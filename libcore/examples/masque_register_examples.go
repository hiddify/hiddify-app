package main

import (
	"context"
	"fmt"
	"log/slog"
	"os"
	"time"

	"github.com/bepass-org/vwarp/masque"
)

// Example 1: Simple auto-registration
func example1() {
	ctx := context.Background()

	// This will automatically register if config doesn't exist
	client, err := masque.AutoLoadOrRegisterWithOptions(ctx, masque.AutoRegisterOptions{
		ConfigPath: "./my_config.json",
		DeviceName: "my-laptop",
		Logger:     slog.Default(),
	})
	if err != nil {
		panic(err)
	}
	defer client.Close()

	fmt.Println("✅ Client created successfully!")
}

// Example 2: Manual registration with more control
func example2() {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	// Create registration handler
	cr := masque.NewCloudflareRegistration()

	// Register and enroll MASQUE key
	config, err := cr.RegisterAndEnroll(ctx, "PC", "en_US", "my-device")
	if err != nil {
		panic(err)
	}

	// Save configuration
	if err := config.SaveToFile("./manual_config.json"); err != nil {
		panic(err)
	}

	fmt.Printf("✅ Registered successfully!\n")
	fmt.Printf("Device ID: %s\n", config.ID)
	fmt.Printf("IPv4: %s\n", config.IPv4)
	fmt.Printf("IPv6: %s\n", config.IPv6)
	fmt.Printf("License: %s\n", config.License)
}

// Example 3: Using existing config
func example3() {
	ctx := context.Background()

	// Load existing config
	config, err := masque.LoadMasqueConfig("./my_config.json")
	if err != nil {
		panic(err)
	}

	fmt.Printf("Loaded config for device: %s\n", config.ID)

	// Create client with custom options
	client, err := masque.NewMasqueClient(ctx, masque.MasqueClientConfig{
		ConfigPath:  "./my_config.json",
		Endpoint:    config.EndpointV4 + ":443",
		UseIPv6:     false,
		ConnectPort: 443,
		Logger:      slog.Default(),
	})
	if err != nil {
		panic(err)
	}
	defer client.Close()

	fmt.Println("✅ Connected to MASQUE server")
}

// Example 4: Force re-registration
func example4() {
	ctx := context.Background()

	// Delete old config first (if exists)
	_ = masque.DeleteConfig("./my_config.json")

	// Or use ForceRenew option
	client, err := masque.AutoLoadOrRegisterWithOptions(ctx, masque.AutoRegisterOptions{
		ConfigPath: "./my_config.json",
		DeviceName: "my-device-renewed",
		ForceRenew: true, // This will re-register even if config exists
		Logger:     slog.Default(),
	})
	if err != nil {
		panic(err)
	}
	defer client.Close()

	fmt.Println("✅ Device re-registered successfully!")
}

// Example 5: Quick test - auto-register and connect
func example5() {
	ctx := context.Background()

	// One-liner: auto-load or register
	config, err := masque.AutoRegisterOrLoad(ctx, "./test_config.json", "test-device")
	if err != nil {
		panic(err)
	}

	fmt.Printf("✅ Ready to use!\n")
	fmt.Printf("Device: %s\n", config.ID)
	fmt.Printf("Endpoint: %s:443\n", config.EndpointV4)

	// Now create a client
	client, err := masque.NewMasqueClient(ctx, masque.MasqueClientConfig{
		ConfigPath: "./test_config.json",
	})
	if err != nil {
		panic(err)
	}
	defer client.Close()

	fmt.Println("✅ Connected!")
}

func main() {
	if len(os.Args) < 2 {
		fmt.Println("Usage:")
		fmt.Println("  go run examples_register.go <example_number>")
		fmt.Println("")
		fmt.Println("Examples:")
		fmt.Println("  1 - Simple auto-registration")
		fmt.Println("  2 - Manual registration with control")
		fmt.Println("  3 - Use existing config")
		fmt.Println("  4 - Force re-registration")
		fmt.Println("  5 - Quick test (one-liner)")
		return
	}

	switch os.Args[1] {
	case "1":
		example1()
	case "2":
		example2()
	case "3":
		example3()
	case "4":
		example4()
	case "5":
		example5()
	default:
		fmt.Println("Unknown example number")
	}
}
