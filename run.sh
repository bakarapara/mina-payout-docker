mkdir -p /root/archive-data && \
chmod 700 /root/archive-data && \
sudo docker run --name mina -d \
--restart always \
-p 8302:8302 \
-p 127.0.0.1:3085:3085 \
-v /root/keys:/root/keys:ro \
-v /root/.mina-config:/root/.mina-config \
-v /root/archive-data:/var/archive-data \
nikitin/mina-archive-bp:1.0.2 daemon \
--peer-list-url https://storage.googleapis.com/seed-lists/finalfinal3_seeds.txt \
-block-producer-key /root/keys/my-wallet \
-block-producer-password "" \
-insecure-rest-server \
-file-log-level Debug \
-log-level Info \
-archive-address 3086
