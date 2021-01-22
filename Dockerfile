FROM kong:1.4.0

COPY plugins/ /usr/local/share/lua/5.1/kong/plugins/

ENV KONG_PLUGINS=bundled,error-transformer,tcp-body-log,skywalking