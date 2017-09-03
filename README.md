# RxTender Base backend

This is the base backend of [RxTender](http://rxtender.org). It contains
implementations of common programming languages for various serialization and
framing protocols.


The current implementation supports:

- python3:
    - serialization:
        - json
    - stream: source
    - framing:
        - json-lines
- es2015:
    - serialization:
        - json
    - stream: sink
    - framing:
        - json-lines

## Running tests

### es2015

    cd test/es2015
    npm run test
