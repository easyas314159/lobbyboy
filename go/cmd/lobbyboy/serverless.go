// +build serverless

package main

import (
	"bytes"
	"context"
	"os"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/appconfig"
	"github.com/awslabs/aws-lambda-go-api-proxy/gorillamux"
	"github.com/spf13/viper"
)

func loadConfig() (*viper.Viper, error) {
	cfg, err := config.LoadDefaultConfig(context.TODO())
	if err != nil {
		return nil, err
	}

	acApp := os.Getenv("AWS_APPCONFIG_APPLICATION")
	acEnv := os.Getenv("AWS_APPCONFIG_ENVIRONMENT")
	acConf := os.Getenv("AWS_APPCONFIG_CONFIGURATION")
	acClientId := os.Getenv("AWS_APPCONFIG_CLIENT_ID")

	ac := appconfig.NewFromConfig(cfg)
	conf, err := ac.GetConfiguration(
		context.TODO(),
		&appconfig.GetConfigurationInput{
			ClientId:      &acClientId,
			Application:   &acApp,
			Environment:   &acEnv,
			Configuration: &acConf,
		},
	)
	if err != nil {
		return nil, err
	}

	v := viper.New()
	v.SetConfigType("json")

	if err := v.ReadConfig(bytes.NewReader(conf.Content)); err != nil {
		return nil, err
	}

	return v, nil
}

func populateConfigOperationModeDefaults(v *viper.Viper) {

}

func (env *Environment) listenAndServe(ctx context.Context) error {
	lambda.Start(gorillamux.New(env.createRouter()).ProxyWithContext)
	return nil
}
