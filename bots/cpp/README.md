[![Unlicense](https://img.shields.io/badge/unliense-public%20domain-brightgreen.svg)](http://unlicense.org/)

Getting dependencies
--------------------

First, install [Boost] and [SFML] from your distribution's package manager.

Then, install [netorcai-client-cpp] and its dependency ([nlohmann_json]) with
the following script.

``` bash
INSTALL_DIRECTORY=/usr
# IMPORTANT NOTE: If you change the install directory,
# make sure ${INSTALL_DIRECTORY}/lib/pkgconfig is in your pkg-config path
# (environment variable $PKG_CONFIG_PATH)

# Get and install nlohmann_json-3.5.0
git clone https://github.com/nlohmann/json.git -b v3.5.0 --single-branch --depth 1
(cd json && meson build --prefix=${INSTALL_DIRECTORY})
(cd json/build && ninja install)

# Get and install netorcai-client-cpp
git clone https://github.com/netorcai/netorcai-client-cpp.git
(cd netorcai-client-cpp && meson build --prefix=${INSTALL_DIRECTORY})
(cd netorcai-client-cpp/build && ninja install)
```

Build instructions
------------------

```bash
meson build
(cd build && ninja)
```

Run instructions
----------------

```bash
./build/random
```

[Boost]: https://www.boost.org
[netorcai-client-cpp]: https://github.com/netorcai/netorcai-client-cpp
[nlohmann_json]: https://github.com/nlohmann/json
[pkg-config]: https://www.freedesktop.org/wiki/Software/pkg-config
[SFML]: https://www.sfml-dev.org
