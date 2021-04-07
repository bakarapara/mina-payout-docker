FROM minaprotocol/mina-daemon-baked:1.1.5-a42bdee
RUN apt-get update && \
    apt-get -y install postgresql-client-10 \
		mina-archive=1.1.3-48401e9
RUN curl -sL https://deb.nodesource.com/setup_15.x | /bin/bash -
RUN apt-get update && \
    apt-get -y install nodejs
COPY mina-pool-payout /root/mina-pool-payout
RUN cd /root/mina-pool-payout && npm install
COPY init_mina_baked.sh /root
COPY run_archive_proxy.sh /root
RUN chmod +x /root/init_mina_baked.sh /root/run_archive_proxy.sh
EXPOSE 3086
