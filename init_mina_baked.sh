#!/bin/bash -x
mkdir -p .mina-config
touch .mina-config/mina-prover.log
touch .mina-config/mina-verifier.log
touch .mina-config/mina-best-tip.log
archive_data_dir="/var/archive-data"
chown -R postgres "$archive_data_dir"
need_db_init=0
if [ ! -f "$archive_data_dir/init" ]; then
    need_db_init=1
    su postgres -c "/usr/lib/postgresql/10/bin/initdb -D \"$archive_data_dir\""
    touch "$archive_data_dir/init"
fi
rm -rf "$archive_data_dir/postmaster.pid"
su postgres -c "/usr/lib/postgresql/10/bin/pg_ctl -D \"$archive_data_dir\" -l \"$archive_data_dir/postgres.logfile\" start"
echo "waiting for Postgres to start"
sleep 10
if [ $need_db_init == 1 ]
then
   su postgres -c '/usr/bin/psql -c "CREATE USER archive CREATEDB PASSWORD '"'"'archive'"'"'"'
   export PGPASSWORD=archive
   /usr/bin/createdb -U archive archive
   /usr/bin/psql     -U archive -d archive -f <(curl -Ls https://raw.githubusercontent.com/MinaProtocol/mina/master/src/app/archive/create_schema.sql)
fi

./run_archive_proxy.sh > /root/.mina-config/archive-proxy.log 2>&1 &

command=$1 
shift 
while true; do
  rm -f /root/.mina-config/.mina-lock
  mina "$command" "$@" 2>&1 >mina.log &
  mina_pid=$!
  tail -q -f mina.log &
  tail_pid=$!
  wait "$mina_pid"
  echo "Mina process exited with status code $?"
  sleep 10
  kill "$tail_pid"
  if [ ! -f stay_alive ]; then
    exit 0
  fi
done

