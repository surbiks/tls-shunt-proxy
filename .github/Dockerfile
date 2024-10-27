# build stage
FROM golang:alpine AS build
RUN apk update && apk add git
ADD . /src
WORKDIR /src
ENV CGO_ENABLED=0
RUN go build \
    -ldflags "-X github.com/surbiks/tls-shunt-proxy/share.BuildVersion=$(git describe --abbrev=0 --tags)" \
    -o /tmp/bin

# run stage
FROM scratch
WORKDIR /app
COPY --from=build /tmp/bin /app/bin
ENTRYPOINT ["/app/bin"]
CMD ["/app/bin/tls-shunt-proxy"]