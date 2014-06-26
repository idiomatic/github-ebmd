package main

import (
	"github.com/go-martini/martini"
	"log"
	"net/http"
)

type Foo struct {
	Data string
}
type Fooer interface {
	String() string
}

func (f *Foo) String() string {
	return f.Data
}

func DITest() martini.Handler {
	return func(c martini.Context) {
		foo := &Foo{Data: "bar"}
		c.MapTo(foo, (*Fooer)(nil))
	}
}

func main() {
	m := martini.Classic()
	m.Use(DITest())
	m.Get("/",
		func(f Fooer) string {
			return "yay: " + f.String()
		})
	log.Fatal(http.ListenAndServe(":8081", m))
}
