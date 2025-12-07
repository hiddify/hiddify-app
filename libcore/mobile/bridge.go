package main

import "C"

import (
	"log"
	"os"
	"strings"
	"sync"

	"github.com/GFW-knocker/Xray-core/core"
	_ "github.com/GFW-knocker/Xray-core/main/distro/all"
)

var (
	server *core.Instance
	mu     sync.Mutex
)

//export Start
func Start(configStr *C.char) *C.char {
	mu.Lock()
	defer mu.Unlock()

	if server != nil {
		return C.CString("Core already running")
	}

	// Set asset location if needed, usually defaults to executable dir or env 'xray.location.asset'
	// For android, assets might be tricky.
	// For now we assume config is self-contained or assets are in env.
	assetPath := os.Getenv("XRAY_LOCATION_ASSET")
	if assetPath == "" {
		// Fallback or ignore
	}

	confJson := C.GoString(configStr)

	// LoadConfig with "json" format
	// standard Xray distribution registers "json" loader.
	config, err := core.LoadConfig("json", strings.NewReader(confJson))
	if err != nil {
		log.Printf("Failed to load config: %v", err)
		return C.CString("Failed to load config: " + err.Error())
	}

	inst, err := core.New(config)
	if err != nil {
		log.Printf("Failed to create instance: %v", err)
		return C.CString("Failed to create instance: " + err.Error())
	}

	if err := inst.Start(); err != nil {
		log.Printf("Failed to start instance: %v", err)
		return C.CString("Failed to start instance: " + err.Error())
	}

	server = inst
	log.Println("Xray Core started successfully")
	return nil
}

//export Stop
func Stop() {
	mu.Lock()
	defer mu.Unlock()
	if server != nil {
		server.Close()
		server = nil
		log.Println("Xray Core stopped")
	}
}

func main() {}
