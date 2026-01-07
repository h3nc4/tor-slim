# Slim Tor Container

A single binary Docker container for Tor (**<30MB**), built built with static binaries and no OS layer. Contains two statically-linked binaries: Tor and Lyrebird.

**Why use this?** This Image runs Tor in a `FROM scratch` environment with no package manager, shell, or system libraries. This eliminates the entire OS attack surface.

## Running

Minimal steps to run the container as a Tor SOCKS5 proxy:

```bash
# In case you want to build the image yourself instead of pulling it from Docker Hub:
# docker build -t h3nc4/tor-slim .

docker run -d --name tor -p 9050:9050 h3nc4/tor-slim

curl --socks5-hostname 127.0.0.1:9050 https://check.torproject.org/api/ip
```

## License

Tor Slim is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

Tor Slim is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with Tor Slim. If not, see <https://www.gnu.org/licenses/>.
