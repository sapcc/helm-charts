FROM golang:1.16-alpine3.13 as builder
RUN apk add --no-cache git
RUN mkdir -p /pkg/bin/
ENV GOBIN=/pkg/bin/ GO111MODULE=on

ARG CLAIR_VERSION=4.1.0
# RUN go get -ldflags "-s -w -X main.Version=${CLAIR_VERSION}" "github.com/quay/clair/v4/cmd/clair@v${CLAIR_VERSION}"
# RUN go get -ldflags "-s -w"                                  "github.com/quay/clair/v4/cmd/clairctl@v${CLAIR_VERSION}"
#
# We currently run a patched Clair to work around <https://github.com/quay/clair/issues/1283>. When bumping
# CLAIR_VERSION, either revert back to the default build steps (in the comment block above) or make a new branch in
# https://github.com/sapcc/clair that carries the same patches. We are currently on the "sapcc-4.1.0" branch.
RUN git clone https://github.com/sapcc/clair /src/clair && cd /src/clair && git checkout 1290f8a451d682cb001eb0180cc09fad8b7ed990 && go install -ldflags "-s -w -X main.Version=${CLAIR_VERSION}" ./cmd/clair && go install -ldflags "-s -w" ./cmd/clairctl

################################################################################

FROM alpine:3.13
LABEL source_repository="https://github.com/sapcc/keppel"

# We also add some utilities here since user `nobody` will not be able to `apk add` in the running container.
RUN apk add --no-cache ca-certificates curl
USER nobody:nobody

COPY --from=builder /pkg/ /usr/
