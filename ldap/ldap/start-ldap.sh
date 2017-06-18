#!/bin/bash

set -euo pipefail

cat << _EOF_ > /etc/ldap/ldap.conf
TLS_CACERT  ${CA:?}
TLS_REQCERT hard
_EOF_

touch /tmp/ldap.secret
chmod 600 /tmp/ldap.secret
echo -n ${MASTERPW:?} > /tmp/ldap.secret

BASE_DN=$(ldapsearch -y /tmp/ldap.secret -x -D "cn=admin,cn=config" \
  -b "olcDatabase={1}hdb,cn=config" -H ldaps://${MASTER:?} -LLL -s base \
  | awk '/olcSuffix:/ {print $2}')
DOMAIN=$(echo ${BASE_DN} | sed 's/,dc=/./' | sed 's/^dc=//')

echo "Detected base DN ${BASE_DN} (${DOMAIN})"

echo "BASE ${BASE_DN}" >> /etc/ldap/ldap.conf
echo "slapd slapd/domain string ${DOMAIN}" | debconf-set-selections

DEBIAN_FRONTEND=noninteractive dpkg -i /slapd*.deb

echo "Installing slapd configuration"

cat << _EOF_ >> /etc/ldap/slapd.d/cn=config.ldif
olcTLSCACertificateFile: ${CA:?}
olcTLSVerifyClient: never
olcTLSCertificateFile: ${CERTFILE:?}
olcTLSCertificateKeyFile: ${KEYFILE:?}
_EOF_

/usr/sbin/slapd -h ldapi:/// -g openldap -u openldap -F /etc/ldap/slapd.d

echo "Creating root account"
touch /tmp/modify_client
chmod 600 /tmp/modify_client
cat << _EOF_ | ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f /dev/stdin
dn: olcDatabase={0}config,cn=config
changetype: modify
add: olcRootPW
olcRootPW: $ROOTPW
_EOF_

# slapd might have crashed at this point (bug in ldap), so we restart
# service slapd restart || true

# Copy schemas
echo "Copying schemas"
ldapsearch -y /tmp/ldap.secret -x -D "cn=admin,cn=config" -b "cn=schema,cn=config" \
  -H ldaps://${MASTER:?} -LLL > /tmp/ldap_schema.ldif
# Schemas might already exist, so ignore exit code
ldapadd -c -Q -Y EXTERNAL -H ldapi:/// -f /tmp/ldap_schema.ldif || true
rm /tmp/ldap_schema.ldif

function copy_ldap
{
  local var=$1
  echo "Copying $var"
  # Modify
  cat << _EOF_ > /tmp/modify_client
dn: olcDatabase={1}mdb,cn=config
changetype: modify
replace: $var
_EOF_

  ldapsearch -y /tmp/ldap.secret -x -D "cn=admin,cn=config" \
    -b "olcDatabase={1}hdb,cn=config" -H ldaps://${MASTER:?} -LLL $var \
    | sed 1d | head -n -2 >> /tmp/modify_client

  ldapmodify -c -Q -Y EXTERNAL -H ldapi:/// -f /tmp/modify_client
  rm /tmp/modify_client
}

copy_ldap olcAccess
copy_ldap olcSyncRepl
copy_ldap olcDbIndex

# Mark current contextCSN to know when replication has caught up
ldapsearch -y /tmp/ldap.secret -x -b "${BASE_DN}" -H ldaps://${MASTER:?} \
  -s base -LLL contextCSN | awk '/contextCSN:/ {print $2}' > /initial-contextCSN

rm /tmp/ldap.secret

pkill slapd

# Regenerate index
su openldap -s /usr/sbin/slapindex

# Start final slapd
exec /usr/sbin/slapd -h 'ldaps:/// ldapi:///' -g openldap -u openldap -F /etc/ldap/slapd.d "-d${LOGLEVEL}"