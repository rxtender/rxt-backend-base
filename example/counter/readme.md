# Counter sample code

generate python bindings:

    rxtender \
    --framing rxt_backend_base.python3.framing.newline \
    --serialization rxt_backend_base.python3.serialization.json \
    --stream rxt_backend_base.python3.stream \
    --input counter.rxt > counter_rxt.py

start python server:

    python3 server.py

build javascript client:

    npm install
    npm build

start javascript client:

    npm start
