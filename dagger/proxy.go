package main

import (
	"errors"
	"strings"
)

type Proxy struct {
	TlsExterminator string
	Port            string
	Fqdn            string
	Host            string
}

func NewProxy(hint string) (*Proxy, error) {
	proxyParts := strings.Split(hint, ":")
	if len(proxyParts) != 3 {
		return nil, errors.New("must be of format 'PORT:FQDN:HOST'")
	}

	return &Proxy{
		TlsExterminator: strings.Join(proxyParts[:2], ":"),
		Port:            proxyParts[0],
		Fqdn:            proxyParts[1],
		Host:            proxyParts[2],
	}, nil
}
