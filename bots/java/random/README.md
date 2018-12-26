[![Unlicense](https://img.shields.io/badge/unlicense-public%20domain-brightgreen.svg)](http://unlicense.org/)

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
