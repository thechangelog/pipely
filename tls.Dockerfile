FROM golang:1.23 AS build
RUN go install github.com/nabsul/tls-exterminator@latest
RUN go install github.com/mattn/goreman@latest

FROM varnish:7.4.3
ENV VARNISH_HTTP_PORT=9000
COPY default.vcl /etc/varnish/default.vcl
COPY --from=build /go/bin/tls-exterminator /
COPY --from=build /go/bin/goreman /
COPY Procfile .

ENTRYPOINT [ "/goreman", "start" ]
