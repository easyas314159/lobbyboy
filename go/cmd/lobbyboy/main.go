package main

import (
	"context"
	"log"
	"os/signal"
	"syscall"

	"github.com/spf13/viper"
)

func main() {
	ctx, shutdown := signal.NotifyContext(
		context.Background(),
		syscall.SIGINT,
		syscall.SIGTERM,
	)
	defer shutdown()

	cfg, err := loadConfig()
	if err != nil {
		log.Fatalf("Configuration load failed: %v\n", err)
	}

	populateConfigDefaults(cfg)

	env, err := NewEnvironment(cfg)
	if err != nil {
		log.Fatalf("Initialization failed: %v\n", err)
	}

	err = env.listenAndServe(ctx)
	if err != nil {
		log.Fatalf("Shutdown failed: %v\n", err)
	}
}

func populateConfigDefaults(v *viper.Viper) {
	v.SetDefault("language", "en")
	v.SetDefault("voice", "man")

	populateConfigOperationModeDefaults(v)
}
