# Slim Tor Container

Docker container for Tor (**<30MB**), built as one statically-linked binary with no OS layer.

**Why use this?** This Image runs Tor in a `FROM scratch` environment with no package manager, shell, or system libraries. This eliminates the entire OS attack surface.

## Running

Minimal steps to run the container as a Tor SOCKS5 proxy:

```bash
# In case you want to build the image yourself instead of pulling it from Docker Hub:
# docker build -t h3nc4/tor-slim .

docker run -d --name tor -p 9050:9050 h3nc4/tor-slim

curl --socks5-hostname 127.0.0.1:9050 https://check.torproject.org/api/ip
```

## Configuration

The built-in `/etc/tor/torrc` sets up the SOCKS proxy and ends with:

```
%include /etc/tor/torrc.d/*.conf
```

So extra configuration can be dropped in without replacing the default `torrc`. Mount one or more `.conf` files, or a whole directory, at `/etc/tor/torrc.d/` and they are included in alphabetical order:

```bash
docker run -d --name tor -p 9050:9050 \
  -v ./my-service.conf:/etc/tor/torrc.d/my-service.conf:ro \
  h3nc4/tor-slim
```

A bare directory path errors when `torrc.d` is empty or absent, while the glob does not, so the image still starts with no drop-ins mounted. To replace the configuration wholesale instead, mount over `/etc/tor/torrc`.

`torrc.d` is root-owned and read-only to tor (UID 65534). `/var/lib/tor` is the data directory, owned by 65534 with mode 0700 as tor requires.

## License

Tor Slim is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

Tor Slim is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with Tor Slim. If not, see <https://www.gnu.org/licenses/>.
