package main

import (
	"fmt"
	"os"
	"os/exec"
	"runtime"
	"time"
)

func main() {
	fmt.Println("🔌 Quick Network Disruption Tool")
	fmt.Println("This will temporarily disrupt your network to test MASQUE reconnection")

	if len(os.Args) < 2 {
		fmt.Println("Usage:")
		fmt.Println("  go run quick_network_test.go <command>")
		fmt.Println("")
		fmt.Println("Commands:")
		fmt.Println("  disable-wifi     - Disable WiFi adapter")
		fmt.Println("  enable-wifi      - Enable WiFi adapter")
		fmt.Println("  cycle-wifi       - Disable WiFi for 10 seconds then re-enable")
		fmt.Println("  flush-dns        - Flush DNS cache")
		fmt.Println("  reset-network    - Reset network stack")
		return
	}

	command := os.Args[1]

	switch command {
	case "disable-wifi":
		disableWiFi()
	case "enable-wifi":
		enableWiFi()
	case "cycle-wifi":
		cycleWiFi()
	case "flush-dns":
		flushDNS()
	case "reset-network":
		resetNetwork()
	default:
		fmt.Printf("❌ Unknown command: %s\n", command)
	}
}

func disableWiFi() {
	fmt.Println("📵 Disabling WiFi adapter...")
	if runtime.GOOS == "windows" {
		cmd := exec.Command("netsh", "interface", "set", "interface", "Wi-Fi", "disabled")
		err := cmd.Run()
		if err != nil {
			fmt.Printf("❌ Error: %v\n", err)
			fmt.Println("💡 Try running as Administrator")
		} else {
			fmt.Println("✅ WiFi disabled")
		}
	} else {
		fmt.Println("❌ Only Windows is currently supported")
	}
}

func enableWiFi() {
	fmt.Println("📶 Enabling WiFi adapter...")
	if runtime.GOOS == "windows" {
		cmd := exec.Command("netsh", "interface", "set", "interface", "Wi-Fi", "enabled")
		err := cmd.Run()
		if err != nil {
			fmt.Printf("❌ Error: %v\n", err)
			fmt.Println("💡 Try running as Administrator")
		} else {
			fmt.Println("✅ WiFi enabled")
		}
	} else {
		fmt.Println("❌ Only Windows is currently supported")
	}
}

func cycleWiFi() {
	fmt.Println("🔄 Cycling WiFi adapter...")

	disableWiFi()

	fmt.Println("⏳ Waiting 10 seconds...")
	for i := 10; i > 0; i-- {
		fmt.Printf("⏱️  %d seconds remaining...\n", i)
		time.Sleep(1 * time.Second)
	}

	enableWiFi()
	fmt.Println("✅ WiFi cycle complete")
}

func flushDNS() {
	fmt.Println("🔄 Flushing DNS cache...")
	if runtime.GOOS == "windows" {
		cmd := exec.Command("ipconfig", "/flushdns")
		err := cmd.Run()
		if err != nil {
			fmt.Printf("❌ Error: %v\n", err)
		} else {
			fmt.Println("✅ DNS cache flushed")
		}
	} else {
		fmt.Println("❌ Only Windows is currently supported")
	}
}

func resetNetwork() {
	fmt.Println("🔄 Resetting network stack...")
	if runtime.GOOS == "windows" {
		commands := [][]string{
			{"netsh", "winsock", "reset"},
			{"netsh", "int", "ip", "reset"},
			{"ipconfig", "/release"},
			{"ipconfig", "/renew"},
		}

		for _, cmdArgs := range commands {
			fmt.Printf("🔧 Running: %s\n", cmdArgs[0]+" "+cmdArgs[1])
			cmd := exec.Command(cmdArgs[0], cmdArgs[1:]...)
			err := cmd.Run()
			if err != nil {
				fmt.Printf("⚠️  Warning: %v\n", err)
			}
			time.Sleep(1 * time.Second)
		}
		fmt.Println("✅ Network stack reset complete")
		fmt.Println("💡 You may need to restart your computer for full effect")
	} else {
		fmt.Println("❌ Only Windows is currently supported")
	}
}
