package main

import (
	"code.google.com/p/goauth2/oauth"
	"github.com/martini-contrib/oauth2"
)

type OAuthTransport interface {
	Client() *http.Client
}

func OAuthTransportInjector() martini.Handler {
	return func(tokens oauth2.Tokens, c martini.Context) {
		t := &oauth.Transport{
			Token: &oauth.Token{
				AccessToken:  tokens.Access(),
				RefreshToken: tokens.Refresh(),
				Expiry:       tokens.ExpiryTime(),
				Extra:        tokens.ExtraData(),
			},
		}
		c.MapTo(t, (*OAuthTransport)(nil))
	}
}

/*
    m := martini.Classic()
	m.Use(OAuthTransportInjector())
	m.Get("/restricted",
		oauth2.LoginRequired,
		func(t OAuthTransport, params martini.Params, r *http.Request) string {
            ...
        }
    )
*/
