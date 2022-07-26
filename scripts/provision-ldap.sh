#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o xtrace

# get domain name
IPA_DOMAIN=$(dnsdomainname)
DC1=${IPA_DOMAIN/.*/}
DC2=${IPA_DOMAIN/*./}

# Create testgroup ldif
cat << EOF > group.ldif
dn: cn=testgroup,cn=groups,cn=accounts,dc=${DC1},dc=${DC2}
cn: testgroup
objectClass: top
objectClass: groupofnames
objectClass: nestedgroup
objectClass: ipausergroup
objectClass: ipaobject
objectClass: posixgroup
gidNumber: 93800001
member: uid=test,cn=users,cn=accounts,dc=${DC1},dc=${DC2}
EOF

# Create test user ldif
cat << EOF > user.ldif
dn: uid=test,cn=users,cn=accounts,dc=${DC1},dc=${DC2}
givenName: Max
sn: Muster
uid: test
cn: Max Muster
displayName: Max Muster
initials: MM
gecos: Max Muster
krbPrincipalName: test@${DC1^^}.${DC2^^}
objectClass: top
objectClass: person
objectClass: organizationalperson
objectClass: inetorgperson
objectClass: inetuser
objectClass: posixaccount
objectClass: krbprincipalaux
objectClass: krbticketpolicyaux
objectClass: ipaobject
objectClass: ipasshuser
objectClass: ipaSshGroupOfPubKeys
objectClass: mepOriginEntry
loginShell: /bin/sh
homeDirectory: /home/test
mail: test@${DC1}.${DC2}
krbCanonicalName: test@${DC1^^}.${DC2^^}
userPassword: test
uidNumber: 93800003
gidNumber: 93800003
memberOf: cn=ipausers,cn=groups,cn=accounts,dc=${DC1},dc=${DC2}
memberOf: cn=testgroup,cn=groups,cn=accounts,dc=${DC1},dc=${DC2}
EOF

# Create test user for KV access
cat << EOF > kv-writer.ldif
dn: uid=kv-writer,cn=users,cn=accounts,dc=${DC1},dc=${DC2}
givenName: KV
sn: Writer
uid: kv-writer
cn: KV Writer
displayName: KV Writer
initials: KW
gecos: KV Writer
krbPrincipalName: kv-writer@${DC1^^}.${DC2^^}
objectClass: top
objectClass: person
objectClass: organizationalperson
objectClass: inetorgperson
objectClass: inetuser
objectClass: posixaccount
objectClass: krbprincipalaux
objectClass: krbticketpolicyaux
objectClass: ipaobject
objectClass: ipasshuser
objectClass: ipaSshGroupOfPubKeys
objectClass: mepOriginEntry
loginShell: /bin/sh
homeDirectory: /home/kv-writer
mail: kv-writer@${DC1}.${DC2}
krbCanonicalName: kv-writer@${DC1^^}.${DC2^^}
userPassword: kv-writer
uidNumber: 1997000001
gidNumber: 1997000001
krbPasswordExpiration: 20211027132312Z
krbLastPwdChange: 20211027132312Z
krbExtraData:: AALAUnlhcm9vdC9hZG1pbkBJREVOVElUWS5ORVQA
memberOf: cn=ipausers,cn=groups,cn=accounts,dc=${DC1},dc=${DC2}
EOF

# Apply the ldifs
ldapadd -x -w Secret123 -D uid=admin,cn=users,cn=accounts,dc=${DC1},dc=${DC2} -f group.ldif
ldapadd -x -w Secret123 -D uid=admin,cn=users,cn=accounts,dc=${DC1},dc=${DC2} -f user.ldif
ldapadd -x -w Secret123 -D uid=admin,cn=users,cn=accounts,dc=${DC1},dc=${DC2} -f kv-writer.ldif
