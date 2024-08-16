FROM alpine:latest
LABEL maintainer="Patric Eckhart <mail@patriceckhart.com>"

RUN apk add --no-cache attr avahi avahi-compat-libdns_sd avahi-tools dbus samba-common-tools s6 samba-server &&\
  touch /etc/samba/lmhosts &&\
  rm /etc/samba/smb.conf &&\
  rm /etc/avahi/services/*.service &&\
  mkdir /var/run/dbus

COPY s6 /etc/s6
COPY entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]
CMD ["s6-svscan","/etc/s6"]
