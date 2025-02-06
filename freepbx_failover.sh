#!/bin/bash
LOG_FILE="/var/log/dns_update.log"
exec >> "$LOG_FILE" 2>&1
echo "=== $(date) ==="

BEE_IP="195.239.80.210"
RTK_IP="94.25.71.242"

ZONE_FILE="/etc/bind/zones/dnsdev.ru"
ZONE_NAME="dnsdev.ru"
DNS_RECORD="call-freepbx"

check_ping() {
    ping -c 4 "$1" > /dev/null 2>&1
    return $?
}

update_serial_and_reload_zone() {    
    sed -i -E "s/([0-9]{10})/echo \$((\1+1))/e" "$ZONE_FILE"
    rndc reload "$ZONE_NAME"
}

CURRENT_IP=$(grep -E "$DNS_RECORD" "$ZONE_FILE" | awk '{print $NF}')

if check_ping "$BEE_IP"; then
    echo "BEE AVAILABLE"
    if [ "$CURRENT_IP" != "$BEE_IP" ]; then
        echo "Change RTK on BEE"
        sed -i "/^$DNS_RECORD/d" "$ZONE_FILE"
        echo "$DNS_RECORD            IN      A       $BEE_IP" >> "$ZONE_FILE"

        #sed -i "s/$CURRENT_IP/$BEE_IP/" "$ZONE_FILE"
        update_serial_and_reload_zone
   
    fi
elif check_ping "$RTK_IP"; then
    echo "WARNING BEE Offline"	
    if [ "$CURRENT_IP" != "$RTK_IP" ]; then
        echo "Change BEE on RTK"
        sed -i "/^$DNS_RECORD/d" "$ZONE_FILE"
        echo "$DNS_RECORD            IN      A       $RTK_IP" >> "$ZONE_FILE"


        #sed -i "s/$CURRENT_IP/$RTK_IP/" "$ZONE_FILE"
        update_serial_and_reload_zone
    fi
else
    echo "ERROR BEE and RTK not available"   
fi

