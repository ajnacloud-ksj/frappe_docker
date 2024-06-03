#!/bin/bash

if [ -z "$SITES" ]; then
  echo "SITES variable is empty. Exiting."
  exit 1
fi

ls -1 apps > sites/apps.txt
bench set-config -g db_host "$DB_HOST"
bench set-config -gp db_port "$DB_PORT"
bench set-config -g redis_cache "redis://$REDIS_CACHE"
bench set-config -g redis_queue "redis://$REDIS_QUEUE"
bench set-config -g redis_socketio "redis://$REDIS_QUEUE"
bench set-config -gp socketio_port "$SOCKETIO_PORT"

for site in $(echo $SITES | tr "," "\n" | tr -d "\`"); do
  if [ ! -d "sites/$site" ]; then
    bench new-site "$site" --no-mariadb-socket --db-root-password "$DB_PASSWORD" --admin-password "$SITE_ADMIN_PASS" --install-app erpnext --set-default
  fi
done

for site in $(echo $SITES | tr "," "\n" | tr -d "\`"); do
  if [ -d "sites/$site" ]; then
    existing_apps=$(bench --site "$site" list-apps)
    for app in $(cat sites/apps.txt); do
      if ! echo "$existing_apps" | grep -q "$app"; then
        bench --site "$site" install-app "$app"
      fi
    done
    bench --site "$site" migrate --skip-failing
  else
    echo "Site $site does not exist!"
  fi
done

sleep 5