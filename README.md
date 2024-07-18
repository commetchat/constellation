<p align="center" style="padding-top:20px">
<h1 align="center">Constellation</h1>
<p align="center">A library to draw over the top of other windows and displays</p>

<p align="center">
    <a href="https://matrix.to/#/#commet:matrix.org">
        <img alt="Matrix" src="https://img.shields.io/matrix/commet%3Amatrix.org?logo=matrix">
    </a>
    <a href="https://fosstodon.org/@commetchat">
        <img alt="Mastodon" src="https://img.shields.io/mastodon/follow/109894490854601533?domain=https%3A%2F%2Ffosstodon.org">
    </a>
    <a href="https://twitter.com/intent/follow?screen_name=commetchat">
        <img alt="Twitter" src="https://img.shields.io/twitter/follow/commetchat?logo=twitter&style=social">
    </a>
</p>


# Development
Constellation is developed using Zig, currently version `0.13.0`. 

Rendering and Windowing is done using raylib

# Support
- [x] Linux (X11)
- [ ] Linux (Wayland)
- [x] Windows

# Usage
This library is designed specifically for use in Commet, and isn't really designed to be a general purpose library. Constellation only provides the functionality specifically required by Commet.

See [root.zig](./src/root.zig) for exported functions
