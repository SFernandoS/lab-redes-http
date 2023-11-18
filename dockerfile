FROM rust as quiche-builder

RUN apt-get update && apt-get install -y cmake golang

RUN git clone --recursive https://github.com/cloudflare/quiche \
    && cd quiche \
    && cargo build --release --features ffi,pkg-config-meta,qlog

FROM nginx:alpine

COPY --from=quiche-builder /quiche/target/release/libquiche.so /usr/lib/
COPY nginx-http3.conf /etc/nginx/nginx.conf
