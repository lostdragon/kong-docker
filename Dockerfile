FROM kong:1.4.0

COPY error-transformer/ /usr/local/share/lua/5.1/kong/plugins/error-transformer/

ENV KONG_PLUGINS=bundled,error-transformer