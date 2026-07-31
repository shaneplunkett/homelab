#!/bin/sh
set -eu

package_root=/pal/Package
server_binary="$package_root/Pal/Binaries/Linux/PalServer-Linux-Shipping"
steamclient_source="$package_root/linux64/steamclient.so"
steamclient_destination="$package_root/Pal/Binaries/Linux/steamclient.so"

sudo chown -R user:usergroup "$package_root/Pal/Saved"

if [ ! -f "$steamclient_destination" ]; then
  cp "$steamclient_source" "$steamclient_destination"
fi

chmod +x "$server_binary"
cd "$package_root"

# Pocketpair's PalServer.sh starts the game as a child of /bin/sh. Running the
# binary as PID 1 instead lets Docker deliver SIGINT to PalServer itself so it
# can flush the world save before exiting.
exec "$server_binary" Pal "$@"
