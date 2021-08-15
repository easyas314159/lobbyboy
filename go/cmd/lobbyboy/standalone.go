// +build !serverless

package main

import (
	"context"
	"log"
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/spf13/viper"
)

func loadConfig() (*viper.Viper, error) {
	v := viper.New()

	v.SetConfigType("json")
	v.SetConfigName("config")          // name of config file (without extension)
	v.AddConfigPath("/etc/lobbyboy/")  // path to look for the config file in
	v.AddConfigPath("$HOME/.lobbyboy") // call multiple times to add many search paths
	v.AddConfigPath(".")               // optionally look for config in the working directory

	if err := v.ReadInConfig(); err != nil {
		if _, ok := err.(viper.ConfigFileNotFoundError); !ok {
			return nil, err
		}
		log.Printf("%v\n", err)
	} else {
		log.Printf("Configuration loaded from %v\n", v.ConfigFileUsed())
	}

	v.SetEnvPrefix("lobbyboy")
	v.SetEnvKeyReplacer(strings.NewReplacer(".", "_"))
	v.AutomaticEnv()

	return v, nil
}

func populateConfigOperationModeDefaults(v *viper.Viper) {
	v.SetDefault("address", ":14314")

	v.SetDefault("timeouts", map[string]interface{}{
		"read":  10 * time.Second,
		"write": 10 * time.Second,
		"idle":  10 * time.Second,
		"drain": 10 * time.Second,
	})
}

func (env *Environment) listenAndServe(ctx context.Context) error {
	var wg sync.WaitGroup
	var errShutdown error

	ctx, stop := context.WithCancel(ctx)
	defer stop()

	srv := &http.Server{
		Addr:    env.Config.GetString("address"),
		Handler: env.createRouter(),

		ReadTimeout:  env.Config.GetDuration("timeouts.read"),
		WriteTimeout: env.Config.GetDuration("timeouts.write"),
		IdleTimeout:  env.Config.GetDuration("timeouts.idle"),
	}

	log.Printf("Started server [%v]\n", srv.Addr)
	defer log.Println("Stopped server")

	wg.Add(1)
	go func(ctx context.Context) {
		defer wg.Done()

		<-ctx.Done()

		ctxShutdown, shutdown := context.WithTimeout(
			context.Background(),
			env.Config.GetDuration("timeouts.drain"),
		)
		defer shutdown()

		errShutdown = srv.Shutdown(ctxShutdown)
	}(ctx)

	err := srv.ListenAndServe()
	if err != nil {
		stop()

		// ListenAndServe returns immediately when Shutdown is called so actually wait to shutdown
		// See: https://pkg.go.dev/net/http#Server.Shutdown
		wg.Wait()

		if err == http.ErrServerClosed {
			return errShutdown
		}
	}

	return err
}
