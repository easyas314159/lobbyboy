package main

import (
	"log"

	"github.com/BTBurke/twiml"
	"github.com/spf13/viper"
)

type Environment struct {
	Config    *viper.Viper
	Directory *Directory
}

func NewEnvironment(cfg *viper.Viper) (*Environment, error) {
	d := NewDirectory()
	cfgDir := cfg.Sub("directory")
	for _, name := range cfgDir.AllKeys() {
		numbers := cfgDir.GetStringSlice(name)
		for _, number := range numbers {
			err := d.Add(name, number)
			if err != nil {
				log.Printf("%s: %v\n", name, err)
			}
			continue
		}
	}

	return &Environment{
		Config:    cfg,
		Directory: d,
	}, nil
}

func (env *Environment) say(text string) twiml.Say {
	return twiml.Say{
		Text:     text,
		Voice:    env.Config.GetString("twilio.voice"),
		Language: env.Config.GetString("twilio.language"),
	}
}
