#!/bin/bash

cat > ~/registertoicinga.sh <<"EOF"
pki_dir=/etc/icinga2/pki
fqdn=sub.domain.com
icinga2_master=icinga.domain.com
icinga2_master_port=5665
ticket=somejibberjabberd35f7cfb3b678953aad4aad5

mkdir $pki_dir
chown icinga:icinga $pki_dir
chmod 0700 $pki_dir
icinga2 pki new-cert --cn $fqdn --key $pki_dir/$fqdn.key --cert $pki_dir/$fqdn.crt
icinga2 pki save-cert --key $pki_dir/$fqdn.key --cert $pki_dir/$fqdn.crt --trustedcert $pki_dir/trusted-master.crt --host $icinga2_master
icinga2 pki request --host $icinga2_master --port $icinga2_master_port --ticket $ticket --key $pki_dir/$fqdn.key --cert $pki_dir/$fqdn.crt --trustedcert $pki_dir/trusted-master.crt --ca $pki_dir/ca.key
chown icinga:icinga $pki_dir -R
icinga2 node setup --ticket $ticket --endpoint $icinga2_master --zone $fqdn --master_host $icinga2_master --trustedcert $pki_dir/trusted-master.crt --accept-commands --accept-config
EOF
chmod +x ~/registertoicinga.sh
~/registertoicinga.sh
systemctl restart icinga2
