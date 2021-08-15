package main

import (
	"github.com/BTBurke/twiml"
	"github.com/spf13/viper"
)

type Environment struct {
	Config *viper.Viper
}

func NewEnvironment(cfg *viper.Viper) (*Environment, error) {
	return &Environment{
		Config: cfg,
	}, nil
}

func (env *Environment) say(text string) twiml.Say {
	return twiml.Say{
		Text:     text,
		Voice:    env.Config.GetString("voice"),
		Language: env.Config.GetString("language"),
	}
}
