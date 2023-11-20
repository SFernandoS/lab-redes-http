# Fase de construção do Quiche
FROM rust:latest as quiche-builder
RUN apt-get update && apt-get install -y cmake golang \
    && git clone --recursive https://github.com/cloudflare/quiche

# Fase de construção do Nginx com suporte ao Quiche
FROM debian:buster as nginx-builder

# Instalar dependências necessárias para a compilação
RUN apt-get update && apt-get install -y curl gcc libc-dev make patch

# Baixar e descompactar a fonte do Nginx
RUN curl -O https://nginx.org/download/nginx-1.16.1.tar.gz \
    && tar xzvf nginx-1.16.1.tar.gz

# Mudar para o diretório do Nginx e aplicar o patch do Quiche
WORKDIR /nginx-1.16.1
COPY --from=quiche-builder /quiche /quiche
RUN patch -p01 < ../quiche/extras/nginx/nginx-1.16.patch

# Configurar o Nginx com suporte ao Quiche
RUN ./configure \
    --prefix=/etc/nginx \
    --with-http_ssl_module \
    --with-http_v2_module \
    --with-http_v3_module \
    --with-openssl=/quiche/deps/boringssl \
    --with-quiche=/quiche \
    && make \
    && make install

# Imagem final
FROM debian:buster

# Copiar o Nginx compilado
COPY --from=nginx-builder /etc/nginx /etc/nginx

# Configuração e certificados
COPY ./nginx-http3.conf /etc/nginx/nginx.conf
COPY ./dummy.crt /etc/nginx/ssl/dummy.crt
COPY ./dummy.key /etc/nginx/ssl/dummy.key

# Conteúdo HTML (se necessário)
COPY ./html /usr/share/nginx/html

# Porta e comando de execução
EXPOSE 443
CMD ["nginx", "-g", "daemon off;"]
