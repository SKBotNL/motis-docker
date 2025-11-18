FROM alpine:3.22 AS builder

ARG MOTIS_VERSION=v2.7.5

WORKDIR /build

RUN apk update
RUN apk add clang18 llvm18-dev libc++-dev pkgconf build-base cmake pnpm git ninja-build ninja-is-really-ninja

RUN git clone https://github.com/motis-project/motis

WORKDIR /build/motis

RUN git checkout ${MOTIS_VERSION}

RUN cmake -G Ninja -DNO_BUILDCACHE=yes -S . -B build

RUN cmake --build build --target motis motis-test motis-web-ui

RUN mkdir motis && \
    mv build/motis motis/motis && \
    mv ui/build motis/ui && \
    cp -r deps/tiles/profile motis/tiles-profiles && \
    tar -C ./motis -cjf motis.tar.bz2 ./motis ./tiles-profiles ./ui

FROM alpine:3.22 AS motis
COPY --from=builder /build/motis/motis/motis /
COPY --from=builder /build/motis/motis/tiles-profiles /tiles-profiles
COPY --from=builder /build/motis/motis/ui /ui

RUN apk add --no-cache libc++ llvm18
RUN addgroup --system motis && adduser --system --ingroup motis motis && \
    mkdir /data && \
    chown motis:motis /data 
EXPOSE 8080
VOLUME ["/data"]
USER motis
CMD ["/motis", "server", "/data"]
