package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"

	"github.com/BTBurke/twiml"
	"github.com/awslabs/aws-lambda-go-api-proxy/core"
	"github.com/gorilla/handlers"
	"github.com/gorilla/mux"
	twilio "github.com/kevinburke/twilio-go"
)

type contextKey string

const (
	keyTwilioVoiceRequest contextKey = "twilioVoiceRequest"
	keyTwilioResponse     contextKey = "twilioVoiceResponse"
)

func (env *Environment) createRouter() *mux.Router {
	r := mux.NewRouter()
	r.Use(
		handlers.ProxyHeaders,
		func(next http.Handler) http.Handler {
			return handlers.LoggingHandler(os.Stdout, next)
		},
		func(next http.Handler) http.Handler {
			return handlers.CompressHandlerLevel(next, 7)
		},
		handlers.RecoveryHandler(),
		env.twilioValidation,
		env.twilioVoiceRequest,
		env.twilioVoiceResponse,
		env.twilioAllowList,
	)

	r.Path("/menu").Methods("POST").HandlerFunc(env.handleMenu)

	r.NotFoundHandler = http.HandlerFunc(notFound)
	r.MethodNotAllowedHandler = http.HandlerFunc(methodNotAllowed)

	return r
}

func (env *Environment) twilioValidation(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		err := r.ParseForm()
		if err != nil {
			http.Error(w, http.StatusText(http.StatusBadRequest), http.StatusBadRequest)
			log.Printf("Failed to parse form: %v\n", err)
			return
		}

		if env.Config.IsSet("twilio.secret") {
			twilioSecret := env.Config.GetString("twilio.secret")

			url := r.URL.String()
			apiGatewayContext, exists := core.GetAPIGatewayContextFromContext(r.Context())
			if exists {
				tmpURL := *r.URL
				tmpURL.Path = fmt.Sprintf("/%s%s", apiGatewayContext.Stage, tmpURL.Path)
				url = tmpURL.String()
			}

			expected := r.Header.Get("X-Twilio-Signature")
			actual := twilio.GetExpectedTwilioSignature("", twilioSecret, url, r.PostForm)

			if expected != actual {
				http.Error(w, http.StatusText(http.StatusForbidden), http.StatusForbidden)
				log.Println("Twilio request validation failure.")
				return
			}
		}

		next.ServeHTTP(w, r)
	})
}

func (env *Environment) twilioVoiceRequest(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		var vr twiml.VoiceRequest
		if err := twiml.Bind(&vr, r); err != nil {
			http.Error(w, http.StatusText(http.StatusBadRequest), http.StatusBadRequest)
			return
		}

		ctx := context.WithValue(r.Context(), keyTwilioVoiceRequest, vr)
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

func (env *Environment) twilioVoiceResponse(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		res := twiml.NewResponse()

		ctx := context.WithValue(r.Context(), keyTwilioResponse, res)
		next.ServeHTTP(w, r.WithContext(ctx))

		b, err := res.Encode()
		if err != nil {
			http.Error(w, http.StatusText(http.StatusInternalServerError), http.StatusInternalServerError)
			log.Println(err)
			return
		}

		if _, err := w.Write(b); err != nil {
			http.Error(w, http.StatusText(http.StatusInternalServerError), http.StatusInternalServerError)
			log.Println(err)
			return
		}

		w.Header().Set("Content-Type", "application/xml")
	})
}

func (env *Environment) twilioAllowList(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if env.Allowed != nil {
			from, ok := r.PostForm["From"]
			if !ok || len(from) != 1 {
				http.Error(w, http.StatusText(http.StatusBadRequest), http.StatusBadRequest)
				return
			}

			for _, value := range env.Allowed {
				if from[0] == value {
					next.ServeHTTP(w, r)
					return
				}
			}

			log.Printf("%s is not an allowed incoming number.\n", from[0])

			res, _ := r.Context().Value(keyTwilioResponse).(*twiml.Response)
			res.Add(&twiml.Hangup{})

			return
		}

		next.ServeHTTP(w, r)
	})
}

func (env *Environment) handleMenu(w http.ResponseWriter, r *http.Request) {
	res, _ := r.Context().Value(keyTwilioResponse).(*twiml.Response)

	say := env.say("Test")
	res.Add(&say)
}
