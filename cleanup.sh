#!/bin/sh

RUN_INT_SECS=$(($RUN_INTERVAL_MINS * 60))
SEEDING_THRESHOLD_SECONDS=$(($SEEDING_THRESHOLD_HOURS * 3600))

echo "Starting transmission cleanup, RPC: $TRANSMISSION_RPC, running every $RUN_INTERVAL_MINS minutes, with seeding threshold (hours): $SEEDING_THRESHOLD_HOURS"

while true; do
    # use transmission-remote to get torrent list
    # use sed to delete first / last line of output and remove leading spaces
    # use cut to get first field from each line
    TORRENTLIST=`transmission-remote $TRANSMISSION_RPC --list | sed -e '1d;$d;s/^ *//' | cut -s -d " " -f 1`

    # for each torrent in the list
    for TORRENTID in $TORRENTLIST; do
        TORRENT_NAME=`transmission-remote $TRANSMISSION_RPC --torrent $TORRENTID --info | grep -oE 'Name:.+' | cut -f2- -d' '`

        # check if we seeded for 2 days
        SEEDING_SECONDS=`transmission-remote $TRANSMISSION_RPC --torrent $TORRENTID --info | grep "Seeding Time" | grep -oE '[0-9]+ seconds' | cut -f1 -d' ' | tail -1`

        # check if torrent download is completed
        DL_COMPLETED=`transmission-remote $TRANSMISSION_RPC --torrent $TORRENTID --info | grep "Percent Done: 100%"`

        # check torrents current state is
        STATE_FINISHED=`transmission-remote $TRANSMISSION_RPC --torrent $TORRENTID --info | grep "State: Finished"`

        # if the torrent finished downloading AND state is "Stopped", "Finished" OR seeding for threshold+
        if [ "$DL_COMPLETED" ]; then
            if [ "$STATE_FINISHED" ]; then
                echo "Torrent #$TORRENTID ($TORRENT_NAME) is completed, removing"
                transmission-remote $TRANSMISSION_RPC --torrent $TORRENTID --remove-and-delete
            elif [ "$SEEDING_SECONDS" -gt "$SEEDING_THRESHOLD_SECONDS" ]; then
                echo "Torrent #$TORRENTID ($TORRENT_NAME) has been seeding for more than the defined threshold, marking as finished"
                transmission-remote $TRANSMISSION_RPC --torrent $TORRENTID -sr 0
            else
                echo "Torrent #$TORRENTID ($TORRENT_NAME) still in progress, ignoring"
            fi
        else
            echo "Torrent #$TORRENTID ($TORRENT_NAME) still in progress, ignoring"
        fi
    done

    sleep $RUN_INT_SECS

done