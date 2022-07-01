# Multi-stage build to generate custom k6 with extension
FROM golang:1.17-alpine as builder
WORKDIR $GOPATH/src/go.k6.io/k6
ADD . .
RUN apk --no-cache add git
RUN CGO_ENABLED=0 go install go.k6.io/xk6/cmd/xk6@latest
RUN CGO_ENABLED=0 xk6 build \
    --with github.com/grafana/xk6-output-prometheus-remote=. \
    --with github.com/grafana/xk6-browser@latest \ 
    --output /tmp/k6

# Create image for running k6 with output for Prometheus Remote Write
FROM alpine:3.15
RUN apk add --no-cache ca-certificates \
    && adduser -D -u 12345 -g 12345 k6
COPY --from=builder /tmp/k6 /usr/bin/k6

# Installs latest Chromium package.
RUN apk upgrade --no-cache --available \
    && apk add --no-cache \
      chromium \
      ttf-freefont \
      font-noto-emoji

USER 12345
WORKDIR /home/k6

ENTRYPOINT ["k6"]
