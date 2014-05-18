//usr/local/bin/go run ebmd.go ebmd_config.go $@ ; exit

// based on http://golangtutorials.blogspot.com/2011/11/oauth2-3-legged-authorization-in-go-web.html

// TODO AppEngineify: init()

package main

import (
	"fmt"
	"bytes"
	"encoding/json"
	"net/http"
	"html/template"
	"code.google.com/p/goauth2/oauth"
	"io/ioutil"
)

var notAuthenticated = `
<html><body>go
<a href="/authorize">authorize</a>
</body></html>
`

var userInfoTemplate = template.Must(template.New("").Parse(`
<html><body>your details:
<pre>{{.}}</pre>
</body></html>
`));

var oauthConfig = &oauth.Config {
	ClientId: OAUTH2_CLIENT_ID,
	ClientSecret: OAUTH2_CLIENT_SECRET,
	AuthURL: "https://github.com/login/oauth/authorize",
	TokenURL: "https://github.com/login/oauth/access_token",
	RedirectURL: "http://localhost:8080/oauth2callback",
	Scope: "user,repo",
	AccessType: "offline",
}

const profileInfoURL = "https://api.github.com/user"

func main() {
	http.HandleFunc("/", handleRoot)
	http.HandleFunc("/authorize", handleAuthorize)
	http.HandleFunc("/oauth2callback", handleOAuth2Callback)
	fmt.Println("listening on :8080")
	http.ListenAndServe(":8080", nil)
}

func handleRoot(w http.ResponseWriter, r *http.Request) {
	fmt.Fprint(w, notAuthenticated)
}

func handleAuthorize(w http.ResponseWriter, r *http.Request) {
	http.Redirect(w, r, oauthConfig.AuthCodeURL("state"), http.StatusFound)
}

func handleOAuth2Callback(w http.ResponseWriter, r *http.Request) {
	// assert r.FormValue("state") == "state"
	t := &oauth.Transport{Config: oauthConfig}
	t.Exchange(r.FormValue("code"))
	c := t.Client()
	resp, _ := c.Get(profileInfoURL)
	buf, _ := ioutil.ReadAll(resp.Body)
	var out bytes.Buffer
	json.Indent(&out, buf, "", "  ")
	userInfoTemplate.Execute(w, out.String())
}
