package main

import (
	"github.com/go-martini/martini"
	"github.com/martini-contrib/oauth2"
	"github.com/martini-contrib/sessions"
	"io/ioutil"
	"log"
	"net/http"
)

func main() {
	m := martini.Classic()
	m.Use(sessions.Sessions(
		"my_sessions",
		sessions.NewCookieStore([]byte("sekrit")),
	))
	m.Use(oauth2.Github(&oauth2.Options{
		ClientId:     OAUTH2_CLIENT_ID,
		ClientSecret: OAUTH2_CLIENT_SECRET,
		Scopes:       []string{"user,repo"},
	}))
	m.Get("/", func() string {
		return `<html><body><ul>
<li><a href="/user">user</a></li>
<li><a href="/user/orgs">user/orgs</a></li>
<li><a href="/orgs/LawLoop">orgs/LawLoop</a></li>
<li><a href="/orgs/LawLoop/repos">orgs/LawLoop/repos</a></li>
<li><a href="/repos/LawLoop/mayhem/issues">repos/LawLoop/mayhem/issues</a></li>
<li><a href="/repos/LawLoop/mayhem/issues?state=all&filter=all">repos/LawLoop/mayhem/issues?state=all&filter=all</a></li>
<li><a href="/orgs/LawLoop/mayhem/milestones">orgs/LawLoop/mayhem/milestones</a></li>
<li><a href="/logout">logout</a></li>
</ul></body></html>`
	})
	m.Get("/favicon.ico", func() (int, string) {
		return http.StatusNotFound, "not found\n"
	})
	m.Get("/(?P<suffix>.+)",
		oauth2.LoginRequired,
		func(t oauth2.Transport, params martini.Params, r *http.Request) string {
			c := t.Client()
			var profileInfoURL = "https://api.github.com/" +
				params["suffix"] + "?" + r.URL.RawQuery
			resp, _ := c.Get(profileInfoURL)
			buf, _ := ioutil.ReadAll(resp.Body)
			return string(buf)
		})
	log.Fatal(http.ListenAndServe(":8080", m))
}
