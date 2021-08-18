FROM golang:1.16-alpine3.13 as builder
RUN apk add --no-cache git
RUN mkdir -p /pkg/bin/
ENV GOBIN=/pkg/bin/ GO111MODULE=on

ARG CLAIR_VERSION=4.1.1
RUN go get -ldflags "-s -w -X main.Version=${CLAIR_VERSION}" "github.com/quay/clair/v4/cmd/clair@v${CLAIR_VERSION}"
RUN go get -ldflags "-s -w"                                  "github.com/quay/clair/v4/cmd/clairctl@v${CLAIR_VERSION}"

################################################################################

FROM alpine:3.13
LABEL source_repository="https://github.com/sapcc/keppel"

# We also add some utilities here since user `nobody` will not be able to `apk add` in the running container.
RUN apk add --no-cache ca-certificates curl
USER nobody:nobody

COPY --from=builder /pkg/ /usr/
