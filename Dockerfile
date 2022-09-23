FROM fuzzers/afl:2.52 as builder

RUN apt-get update
RUN apt install -y build-essential clang cmake  automake autotools-dev libtool zlib1g zlib1g-dev libexif-dev libssl-dev
ADD . /mongo-c-driver
WORKDIR /mongo-c-driver
RUN cmake -DENABLE_MONGOC=OFF -DENABLE_CLIENT_SIDE_ENCRYPTION=OFF -DENABLE_BSON=ON -DCMAKE_C_COMPILER=afl-gcc -DCMAKE_CXX_COMPILER=afl-g++ .
RUN make
RUN mkdir /json_corpus
ADD testcase/*.json /json_corpus/
WORKDIR /mongo-c-driver/src/libbson
RUN afl-gcc -I ./src/ -L.  ./examples/json-to-bson.c -o fuzzer -lbson-1.0

FROM fuzzers/afl:2.52

COPY --from=builder /json_corpus/*.json /testsuite/
COPY --from=builder /mongo-c-driver/src/libbson/fuzzer /json-to-bson
COPY --from=builder /mongo-c-driver/src/libbson/*.so.* /sharedlib/
ENV LD_LIBRARY_PATH=/sharedlib

ENTRYPOINT ["afl-fuzz", "-i", "/testsuite/", "-o", "libbsonOut"]
CMD ["/json-to-bson", "@@"]
