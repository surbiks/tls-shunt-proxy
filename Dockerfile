FROM golang:1.19 AS builder
WORKDIR /build
COPY go.mod go.sum ./
RUN go mod download
COPY . .

ENV CGO_ENABLED=0 GOOS=linux GOARCH=amd64
RUN go build -ldflags="-s -w" -o tls-shunt-proxy .

FROM scratch AS app
COPY --from=builder "/build/tls-shunt-proxy" /
CMD ["/tls-shunt-proxy"]