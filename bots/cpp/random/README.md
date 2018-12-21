[![Unlicense](https://img.shields.io/badge/unliense-public%20domain-brightgreen.svg)](http://unlicense.org/)

Getting dependencies
--------------------

Here is the list of the bot dependencies:
- [netorcai-client-cpp](https://github.com/netorcai/netorcai-client-cpp)
  and its dependencies ([nlohmann_json](https://github.com/nlohmann/json),
  [SFML](https://www.sfml-dev.org/)-network)
- Boost

Make sure netorcai-client-cpp and nlohmann_json can be found from
[pkg-config](https://www.freedesktop.org/wiki/Software/pkg-config/):
`pkg-config --cflags --libs netorcai-client-cpp` should return no error.

Make sure boost is installed in your system.

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
