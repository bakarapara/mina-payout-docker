Гайд по запуску ноды MINA
=========================

Данный гайд содержит информацию которая поможет запустить ноду MINA, архивную ноду, скрипт для подсчета ревардов и скрипт для отслеживания аптайма

Подготовительные работы
-----------

Создаем папку ~/keys и загружаем в нее ключи кошелька, на котором вы собираетесь запускать Block Producer

```
mkdir ~/keys
```
Даем права на запись и чтение

```
chmod 700 $HOME/keys
chmod 600 $HOME/keys/my-wallet
```
Экспортируем публичный ключ в файл .bashrc

```
echo 'export KEYPATH=$HOME/keys/my-wallet' >> $HOME/.bashrc
echo 'export MINA_PUBLIC_KEY=$(cat $HOME/keys/my-wallet.pub)' >> $HOME/.bashrc
source ~/.bashrc
```
Обновляем пакеты до последних версий

```
sudo apt update && sudo apt upgrade -y
```

Устанавливаем и активируем Docker

```
sudo apt install docker.io curl -y \
&& sudo systemctl start docker \
&& sudo systemctl enable docker
```


Описание docker-образа Mina+Archive
-----------

Образ собираемый по данному гайду является заменой образу `minaprotocol/mina-daemon-baked:x.x.x-xxxxx` и содержит ноду и архивную ноду в одном образе.

Как собрать
-----------

На машине, где будет собираться образ, необходимо выполнить:

```
git clone https://github.com/rakhmanovr/mina-payout-docker && \
cd mina-payout-docker && \
git clone https://github.com/jrwashburn/mina-pool-payout && \
docker build -t local/mina-archive-bp:1.1.5 .
```

Затем, работаем как с обычным образом minaprotocol/mina-daemon-baked:x.x.x-xxxxxxx

Как обновить
-----------

В `Dockerfile` этого репозитория директиву `FROM` поправить на актуальную версию. Актуальные версии можно найти на оф. сайте. https://minaprotocol.com/docs/connecting и https://minaprotocol.com/docs/advanced/archive-node. Пересобрать и перезапустить.

![mina-payout-docker:Dockerfile at main · rakhmanovr:mina-payout-docker 2021-03-11 16-01-22](https://user-images.githubusercontent.com/16775625/110784487-310a0900-8283-11eb-9e10-edf8488c9ecf.png)

Запуск ноды
-----------

Не забудьте заменить `LINK-TO-PEER-LIST` ссылка на файл со списком пиров, `COINBASE-RECEIVER-PUBKEY` в случае если хотите получать награду на адрес отличный от Block Producer и `PASSWORD` ваш пароль. 

_Если вы планируете запускать скрипт для сбора аналитики (обязателен для TOP120) - команда для запуска будет немного отличаться. Смотрите раздел Sadecar в конце статьи._

```
sudo docker run --name mina -d \
--restart always \
-p 8302:8302 \
-p 127.0.0.1:3085:3085 \
-v /root/keys:/root/keys:ro \
-v /root/.mina-config:/root/.mina-config \
-v /root/archive-data:/var/archive-data \
local/mina-archive-bp:1.1.5 daemon \
--peer-list-url LINK-TO-PEER-LIST \
--coinbase-receiver COINBASE-RECEIVER-PUBKEY \
-block-producer-key /root/keys/my-wallet \
-block-producer-password "PASSWORD" \
-insecure-rest-server \
-file-log-level Debug \
-log-level Info \
-archive-address 3086
```

Запуск скрипта подсчета ревардов
-----------

Заходим в контейнер:

```
$ docker exec -it mina /bin/bash
```

Далее:

```
apt-get install nano
cd mina-pool-payout
cp sample.env .env
nano .env
```

Редактируем следующие поля:

* `COMMISSION_RATE` Размер комиссии. По умолчанию 5% _(.05)_
* `POOL_PUBLIC_KEY` Адрес кошелька на который вам делегируют токены _(hot wallet)_
* `DATABASE:URL` postgres://archive:archive@127.0.0.1:5432/archive
* `GRAPHQL_ENDPOINT` http://127.0.0.1:3085/graphql

_Поля `POOL_MEMO` `SEND_TRANSACTION_FEE` `SEND_PRIVATE_KEY` `SEND_PUBLIC_KEY` можно оставить как есть, если вам нужно только произвести рассчеты. Поле `MIN_CONFIRMATIONS=290` отвечает за количество блоков (в данном случае 290), которое будет вычтено с конца указанного диапазона, чтобы удостоверится в том, что блок в canonical chain (зеленый)_

Пример:

![Screen Shot 2021-03-31 at 14 45 09](https://user-images.githubusercontent.com/16775625/113132592-b869ed00-922f-11eb-89d5-a29136d58a77.png)


Сохраняем файл. Создаем папку src/data/ledger и переходим в нее

```
mkdir src/data/ledger
cd src/data/ledger
```

Экспортируем и переименовываем ledger:  

```
mina ledger export staking-epoch-ledger > staking-epoch-ledger.json
hash --ledger-file staking-epoch-ledger.json | xargs -I % cp staking-epoch-ledger.json %.json

```

Для начала рассчета вводим 

```
npm start
```

На экране появятся результаты работы

```
This script will payout from block 0 to maximum height 2025
The pool total staking balance is 3815975.34
We won these blocks: 2005,1983,1873,1844,1723,1693,1629
We are paying out based on total rewards of 4320540000000 nanomina in this window.
That is 4320.54 mina
The Pool Fee is is 216.027 mina
Total Payout should be 4104513000000 nanomina or 4104.513 mina
The Total Payout is actually: 4104513000005 nm or 4104.513000005 mina
wrote payouts transactions to ./src/data/payout_transactions_20210311094926685_0_2025.json
wrote payout details to ./src/data/payout_details_20210311094926685_0_2025.json
```

Если вы планируете использовать данный скрипт для рассылки - смотрите инструкции в оригинальном репозитории автора: https://github.com/jrwashburn/mina-pool-payout

**В результате работы скрипта будут посчитаны только те блоки, которые были произведены в 
период ПОСЛЕ запуска архивной ноды. Информации о блоках ДО запуска в базе нет, соотвенно 
расчеты по ним производится не будут.**

В результате работы скрипта внутри докера появится файл типа `./src/data/payout_transactions_20210311094926685_0_2025.json` 
где последние две цифры - это диапазон просчитанных блоков, в данном случае 0-2025


Установка Sidecar, скрипта для отслеживания аптайма вашей ноды. 
-----------

Создаем сеть для докера

```
docker network create mina-network
```

Если у вас уже запущен образ, удаляем его

```
docker rm -f mina
```

И запускаем заново с дополнительными флагами 

--network mina-network
--open-limited-graphql-port
--limited-graphql-port 3095

Команда полностью:

```
sudo docker run --name mina -d \
--restart always \
--network mina-network \
-p 8302:8302 \
-p 127.0.0.1:3085:3085 \
-v /root/keys:/root/keys:ro \
-v /root/.mina-config:/root/.mina-config \
-v /root/archive-data:/var/archive-data \
local/mina-archive-bp:1.1.5 daemon \
--peer-list-url LINK-TO-PEER-LIST \
--coinbase-receiver COINBASE-RECEIVER-PUBKEY \
-block-producer-key /root/keys/my-wallet \
-block-producer-password "PASSWORD" \
-insecure-rest-server \
--open-limited-graphql-port \
--limited-graphql-port 3095 \
-file-log-level Debug \
-log-level Info \
-archive-address 3086
```

Создаем файл mina-sidecar-config.json содержащий адрес куда будет отправляться статистика. 

```
cd $HOME && touch ./mina-sidecar-config.json
cat << EOF > ./mina-sidecar-config.json
{
  "uploadURL": "https://us-central1-mina-mainnet-303900.cloudfunctions.net/block-producer-stats-ingest/?token=72941420a9595e1f4006e2f3565881b5",
  "nodeURL": "http://mina:3095"
}
EOF
```

Запускаем контейнер со скриптом

```
docker run \
--name mina-sidecar \
--network mina-network \
--restart=always -d \
-v $(pwd)/mina-sidecar-config.json:/etc/mina-sidecar.json \
minaprotocol/mina-bp-stats-sidecar:latest
```

Проверка логов

```
docker logs -f mina-sidecar
```

Пример нормальной работы скрипта

![Screen Shot 2021-03-15 at 15 29 38](https://user-images.githubusercontent.com/16775625/111146794-46dd3e00-85a3-11eb-987e-04ca4da70262.png)


Материалы использованные при составлении гайда
-----------

* https://github.com/jrwashburn/mina-pool-payout
* https://github.com/garethtdavies/mina-payout-script
* https://github.com/xni/mina-archive-docker
* https://icohigh.gitbook.io/mina-node-testnet/russian/varianty-zapuska-nody
* https://github.com/Fitblip/mina/tree/ryan/mina-bp-stats/automation/services/mina-bp-stats/sidecar

