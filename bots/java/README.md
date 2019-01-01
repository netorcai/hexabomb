[![Unlicense](https://img.shields.io/badge/unlicense-public%20domain-brightgreen.svg)](http://unlicense.org/)

Getting dependencies
--------------------
This example requires [Apache Maven] and [netorcai-client-java].

netorcai-client-java can be installed with the following commands.

``` bash
git clone https://github.com/netorcai/netorcai-client-java.git
cd netorcai-client-java
mvn install
```

Build instructions
------------------
The following commands generates an executable jar (in the `target` directory).
```bash
mvn clean compile assembly:single
```

Run instructions
----------------

```bash
java -jar target/random-*.jar
```

[Apache Maven]: https://maven.apache.org/
[netorcai-client-java]: https://maven.apache.org/
