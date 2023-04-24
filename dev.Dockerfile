FROM alpine:latest

RUN apk add --no-cache --update --upgrade \
  bash \
  tor \
  privoxy \
  haproxy \
  runit \
  && rm -rf /var/cache/apk/* /tmp/* /var/tmp/* \
  && adduser -D myuser

ENV TOR_INSTANCES=5

WORKDIR /app

COPY --chown=myuser:myuser . .

RUN chmod +x *.sh \
  && chmod -R +x service-templates \
  && mv torrc.template /etc/tor/torrc.template \
  && mv privoxy.config.template /etc/privoxy/config.template  \
  && mv haproxy.cfg.template /etc/haproxy/haproxy.cfg.template  \
  && mv service-templates/tor /etc/service/.tor.template \
  && mv service-templates/privoxy /etc/service/.privoxy.template  \
  && mv service-templates/haproxy /etc/service/haproxy

USER root

ENTRYPOINT ["/bin/bash", "./start.sh"]