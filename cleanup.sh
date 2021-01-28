#!/bin/sh

# check for mandatory values
if [[ $(expr "$RUN_INTERVAL" : '[0-9]\+$') -eq 0 ]]; then
   echo "error: RUN_INTERVAL is not a number, exiting"
   exit 1
elif [[ $(expr "$SEEDING_THRESHOLD" : '[0-9]\+$') -eq 0 ]]; then
   echo "error: SEEDING_THRESHOLD is not a number, exiting"
   exit 1
fi

RUN_INT_SECS=$(($RUN_INTERVAL * 3600))
SEED_THRS_SECS=$(($SEEDING_THRESHOLD * 3600 * 24))

# use auth only if defined
if [ "$TRANSMISSION_RPC_AUTH" = true ]; then
    if [ -z "$TRANSMISSION_RPC_USER" ] || [ -z "$TRANSMISSION_RPC_PASSWORD" ]; then
        echo "error: AUTH is enabled, but user or password is not set, exiting"
        exit 1
    fi
    TRANSMISSION_RPC_FULL="$TRANSMISSION_RPC -n $TRANSMISSION_RPC_USER:$TRANSMISSION_RPC_PASSWORD"
else
    TRANSMISSION_RPC_FULL="$TRANSMISSION_RPC"
fi

echo "Starting transmission cleanup, RPC: $TRANSMISSION_RPC, running every $RUN_INTERVAL hours, with seeding threshold (days): $SEEDING_THRESHOLD"

while true; do
    # get torrent list
    TORRENTLIST=$(transmission-remote $TRANSMISSION_RPC_FULL --list | sed -e '1d;$d;s/^ *//' | cut -s -d' ' -f1)

    # for each torrent in the list
    for TORRENTID in $TORRENTLIST; do
        TORRENT_DETAILS=$(transmission-remote $TRANSMISSION_RPC_FULL --torrent $TORRENTID --info)
        TORRENT_NAME=$(echo "$TORRENT_DETAILS" | grep -oE 'Name:.+' | cut -d' ' -f2-)

        # check seeding time
        SEEDING_SECONDS=$(echo "$TORRENT_DETAILS" | grep 'Seeding Time:' | grep -oE '[0-9]+ seconds' | cut -d' ' -f1 | tail -1)

        # check if torrent download completed
        DL_COMPLETED=$(echo "$TORRENT_DETAILS" | grep 'Percent Done: 100%')

        # check if torrent state is finished
        STATE_FINISHED=$(echo "$TORRENT_DETAILS" | grep 'State: Finished')

        # if torrent download completed
        if [ "$DL_COMPLETED" ]; then
            # if the torrent is marked as finished, remove it
            if [ "$STATE_FINISHED" ]; then
                echo "Torrent #$TORRENTID ($TORRENT_NAME) is completed, removing"
                transmission-remote $TRANSMISSION_RPC_FULL --torrent $TORRENTID --remove-and-delete
            # if the torrent has been seeding for more than the threshold, mark is as finished
            elif [ "$SEEDING_SECONDS" -gt "$SEED_THRS_SECS" ]; then
                echo "Torrent #$TORRENTID ($TORRENT_NAME) has been seeding for more than the defined threshold, marking as finished"
                transmission-remote $TRANSMISSION_RPC_FULL --torrent $TORRENTID -sr 0
            else
                echo "Torrent #$TORRENTID ($TORRENT_NAME) still in progress, ignoring"
            fi
        else
            echo "Torrent #$TORRENTID ($TORRENT_NAME) still in progress, ignoring"
        fi
    done

    sleep $RUN_INT_SECS

done
