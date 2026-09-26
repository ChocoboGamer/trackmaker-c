#!/usr/bin/env bash

cd $(dirname "$0")
set -eou pipefail

data_home=${XDG_DATA_HOME:=$HOME/.local/share}
desktop_db=$data_home/applications
mime_db=$data_home/mime

echo "writing trackmaker-c.desktop to '$desktop_db/'"
mkdir -p "$desktop_db/"
sed "s~Exec=.*~Exec=$(pwd)/start.sh %f~" ./desktop/trackmaker-c.desktop > "$desktop_db/trackmaker-c.desktop"
sed -i "s~Icon=.*~Icon=$(pwd)/desktop/trackmaker-c.png~" "$desktop_db/trackmaker-c.desktop"
echo "writing MIME association for application-xdrv to '$mime_db/packages/'"
mkdir -p "$mime_db/packages/"
cp ./desktop/application-xdrv.xml "$mime_db/packages/"

echo "updating .desktop database"
update-desktop-database "$desktop_db"
echo "updating MIME database"
update-mime-database "$mime_db"

echo "done!"
echo "make sure to re-run this script if the location of this folder changes"