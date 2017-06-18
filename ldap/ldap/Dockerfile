FROM debian:stretch

# Install everything needed to run slapd, but do the actual real installation
# in start-ldap.sh when the base DN is known
RUN apt-get update; \
  DEBIAN_FRONTEND=noninteractive apt-get install -y slapd dumb-init ldap-utils procps; \
  apt-get download slapd; \
  apt-get purge -y slapd; \
  apt-get clean

ADD start-ldap.sh /
ADD ready.sh /

ENTRYPOINT ["/usr/bin/dumb-init", "--"]

# ADD server.crt /etc/ssl/ldap/
# ADD server.key /etc/ssl/ldap/
# ADD ca.crt /etc/ssl/ldap/
# ENV CA /etc/ssl/ldap/ca.crt
# ENV CERTFILE /etc/ssl/ldap/server.crt
# ENV KEYFILE /etc/ssl/ldap/server.key
# ENV MASTER ldap-master.tld
# ENV MASTERPW super-secret-repl-pw
# ENV ROOTPW admin-pw
# ENV LOGLEVEL 0x4120

CMD ["/start-ldap.sh"]
