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

################################################################################
# Tor Builder
FROM alpine:3.23@sha256:5b10f432ef3da1b8d4c7eb6c487f2f5a8f096bc91145e68878dd4a5019afde11 AS tor-builder
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
RUN mkdir -p /rootfs/var/lib/tor /rootfs/etc/tor && \
  mv src/app/tor /rootfs/tor && \
  chmod 700 /rootfs/var/lib/tor

RUN printf "SocksPort 0.0.0.0:9050\nDataDirectory /var/lib/tor\nLog notice stdout\n" >/rootfs/etc/tor/torrc

################################################################################
# Final squashed image
FROM scratch AS final

COPY --from=tor-builder /rootfs/ /

USER 65534:65534

ENTRYPOINT ["/tor" ]
CMD ["-f", "/etc/tor/torrc"]

LABEL org.opencontainers.image.title="Tor Slim" \
  org.opencontainers.image.description="A minimal, static Tor container built from scratch" \
  org.opencontainers.image.authors="Henrique Almeida <me@h3nc4.com>" \
  org.opencontainers.image.vendor="Henrique Almeida" \
  org.opencontainers.image.licenses="GPL-3.0-or-later" \
  org.opencontainers.image.source="https://github.com/h3nc4/tor-scratch"
