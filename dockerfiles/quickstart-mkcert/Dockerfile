FROM alpine:3.11

ENV if [ `uname -m` = aarch64 ]; then MKCERT_VERSION=1.4.2; PLAT=arm64; else MKCERT_VERSION=1.4.1; PLAT=amd64; fi 

# Run as root
RUN echo "${MKCERT_VERSION}, ${PLAT}"
RUN apk add --no-cache curl openssl \
    && curl -sSL -o /usr/local/bin/mkcert \
        "https://github.com/FiloSottile/mkcert/releases/download/v${MKCERT_VERSION}/mkcert-v${MKCERT_VERSION}-linux-arm64" \
    && chmod a+x /usr/local/bin/mkcert \
    && mkcert -version \
    && adduser --disabled-password mkcert \
    && mkcert -install \
    && mkdir -p /certs && chown -R mkcert /certs

## Install mkcert certification authorizty, must be done as root user
# Drop privileges
USER mkcert
WORKDIR /certs

# Generate certificate in current dir
RUN mkcert -key-file cert-key.pem -cert-file cert.pem open.io s3.open.io "*.openio" \
    && cp "$(mkcert -CAROOT)/rootCA.pem" ./rootCA.pem
