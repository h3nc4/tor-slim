# Copyright (C) 2026  Henrique Almeida
# This file is part of Tor Slim.
#
# Tor Slim is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Tor Slim is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Tor Slim.  If not, see <https://www.gnu.org/licenses/>.

########################################
# Versions
ARG TOR_VERSION="0.4.8.21"
ARG LYREBIRD_VERSION="0.8.0"

################################################################################
# Lyrebird Builder
FROM golang:1.25.5-alpine3.23@sha256:ac09a5f469f307e5da71e766b0bd59c9c49ea460a528cc3e6686513d64a6f1fb AS lyrebird-builder
ARG LYREBIRD_VERSION

RUN apk add --no-cache git

WORKDIR /src
RUN git clone --depth 1 --branch "lyrebird-${LYREBIRD_VERSION}" \
  https://gitlab.torproject.org/tpo/anti-censorship/pluggable-transports/lyrebird.git .

# Build statically
RUN CGO_ENABLED=0 go build -v -ldflags="-s -w" -o /bin/lyrebird ./cmd/lyrebird

################################################################################
# Tor Builder
FROM alpine:3.23@sha256:865b95f46d98cf867a156fe4a135ad3fe50d2056aa3f25ed31662dff6da4eb62 AS tor-builder
ARG TOR_VERSION

# Install build dependencies
RUN apk add --no-cache \
  build-base \
  gnupg \
  libevent-dev \
  libevent-static \
  linux-headers \
  openssl-dev \
  openssl-libs-static \
  xz \
  zlib-dev \
  zlib-static

WORKDIR /src

# Download and verify Tor
ADD "https://dist.torproject.org/tor-${TOR_VERSION}.tar.gz" "tor-${TOR_VERSION}.tar.gz"
ADD "https://dist.torproject.org/tor-${TOR_VERSION}.tar.gz.sha256sum" "tor-${TOR_VERSION}.tar.gz.sha256sum"
ADD "https://dist.torproject.org/tor-${TOR_VERSION}.tar.gz.sha256sum.asc" "tor-${TOR_VERSION}.tar.gz.sha256sum.asc"
ADD "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xB74417EDDF22AC9F9E90F49142E86A2A11F48D36" david_goulet_gpg_key.asc
ADD "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x514102454D0A87DB0767A1EBBE6A0531C18A9179" alexander_faroy_gpg_key.asc

# Import Tor developers' GPG keys
RUN gpg --batch --yes --import <"david_goulet_gpg_key.asc" && \
  gpg --batch --yes --import <"alexander_faroy_gpg_key.asc" && \
  gpg --batch --yes --verify "tor-${TOR_VERSION}.tar.gz.sha256sum.asc" "tor-${TOR_VERSION}.tar.gz.sha256sum" && \
  sha256sum -c "tor-${TOR_VERSION}.tar.gz.sha256sum"
RUN tar -xzf "tor-${TOR_VERSION}.tar.gz" --strip-components=1

# Compile static Tor
RUN ./configure \
  --enable-static-tor \
  --with-libevent-dir=/usr \
  --with-openssl-dir=/usr \
  --with-zlib-dir=/usr \
  --disable-asciidoc \
  --disable-html-manual \
  --disable-manpages \
  --disable-system-torrc \
  --disable-module-dirauth \
  --disable-module-relay \
  --disable-unittests \
  --disable-tool-name-check

RUN make -j"$(nproc)" && \
  strip --strip-all src/app/tor

# Setup directories and folder permissions
RUN mkdir -p /tmp/var/lib/tor /tmp/etc/tor && \
  chmod 700 /tmp/var/lib/tor

RUN printf "SocksPort 0.0.0.0:9050\nDataDirectory /var/lib/tor\nLog notice stdout\n" >/tmp/etc/tor/torrc

################################################################################
# Assemble runtime image
FROM scratch AS assemble

# Binaries
COPY --from=tor-builder /src/src/app/tor /tor
COPY --from=lyrebird-builder /bin/lyrebird /lyrebird

# Config and data directories
COPY --from=tor-builder --chown=65534:65534 /tmp/var/lib/tor /var/lib/tor
COPY --from=tor-builder /tmp/etc/tor /etc/tor

################################################################################
# Final squashed image
FROM scratch AS final

COPY --from=assemble "/" "/"

USER 65534:65534

ENTRYPOINT ["/tor" ]
CMD ["-f", "/etc/tor/torrc"]

LABEL org.opencontainers.image.title="Tor Slim" \
  org.opencontainers.image.description="A minimal, static Tor container built from scratch" \
  org.opencontainers.image.authors="Henrique Almeida <me@h3nc4.com>" \
  org.opencontainers.image.vendor="Henrique Almeida" \
  org.opencontainers.image.licenses="GPL-3.0-or-later" \
  org.opencontainers.image.source="https://github.com/h3nc4/tor-scratch"
