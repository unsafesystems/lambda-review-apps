FROM quay.io/oauth2-proxy/oauth2-proxy:v7.4.0 as base

FROM --platform=$BUILDPLATFORM golang:1.20.7-alpine3.17 as builder

WORKDIR /src
COPY . .

ARG TARGETOS
ARG TARGETARCH
RUN --mount=target=. \
	--mount=type=cache,target=/root/.cache/go-build \
    --mount=type=cache,target=/go/pkg \
    GOOS=$TARGETOS GOARCH=$TARGETARCH go build -o /bin/out .

FROM node:18.16.0-alpine3.18

RUN apk add --no-cache supervisor && \
    touch /etc/supervisord.conf && \
    chown 65532:65532 /etc/supervisord.conf && \
    chown 65532:65532 /home

COPY entrypoint.sh /entrypoint.sh
COPY server.js /home/server.js

COPY --from=base /etc/nsswitch.conf /etc/nsswitch.conf
COPY --from=base /bin/oauth2-proxy /bin/oauth2-proxy
COPY --from=base /etc/ssl/private/jwt_signing_key.pem /etc/ssl/private/jwt_signing_key.pem

COPY --from=builder /bin/out /bin/lambda-proxy

COPY oauth2-proxy.conf /etc/oauth2-proxy/oauth2-proxy.conf

# UID/GID 65532 is also known as nonroot user in distroless image
USER 65532:65532
WORKDIR /home

ENTRYPOINT ["/entrypoint.sh"]

CMD ["node /home/server.js"]
