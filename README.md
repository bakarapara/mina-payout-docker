Docker-образ Mina+Archive
=========================

Образ `local/mina-archive-bp:1.0.2` является полной и прозрачной
заменой образу `minaprotocol/mina-daemon-baked:1.0.2-06f3c5c`. Можно просто 
заменить один другим и нода сразу станет нодой + архивной нодой.

Как собрать
-----------
Самому собирать образ нужно только если очень хочется :)

На машине, где будет собираться образ, необходимо выполнить:

```
git clone https://github.com/xni/mina-archive-docker && \
cd mina-archive-docker && \
git clone https://github.com/jrwashburn/mina-pool-payout && \
docker build -t local/mina-archive-bp:1.0.2 .
```

Затем, работаем как с обычным образом minaprotocol/mina-daemon-baked:1.0.2-06f3c5c.

Как обновить
============
В `Dockerfile` этого репозитория директиву `FROM` поправить на актуальную версию.

Запуск скрипта
===============

Запрыгиваем в контейнер:

```
$ docker exec -it mina /bin/bash
```

И уже там начинаем.

```
apt-get install nano
cd mina-pool-payout
cp sample.env .env
nano .env
```

Редактируем следующие поля:

`MIN_HEIGHT=` -- тут надо указать 0, если мы запускаем скрипт первый раз, или номер блока,
    на котором закончили расчет в прошлый раз (да, это надо как-то хранить самому отдельно)

`MAX_HEIGHT=` -- на каком блоке закончить подсчет. Не всегда имеет смысл идти до самого свежего,
    лучше подождать что блок не "красный".

`STARTING_NONCE=` -- надо получить командой `mina advanced get-nonce --address PUBLICKEY`

`COMMISSION_RATE=` -- размер комиссии

`POOL_PUBLIC_KEY=` -- публичный ключ кошелька, награды с делегации на который мы считаем

`SEND_TRANSACTION_FEE=` -- сколько мы хотим тратить на транзакции по рассылке выплат

Дальше нам нужен приватный ключ, получить его можно так
`mina advanced dump-keypair --privkey-path keys/my-payout-wallet`.

И заносим его в SEND_PRIVATE_KEY а публичный в SEND_PUBLIC_KEY

`DATABASE:URL` -- postgres://archive:archive@127.0.0.1:5432/archive

Затем можно сохранить и написать следующее: 
mina ledger export staking-epoch-ledger > staking-epoch-ledger.json

И вводим `npm start`, начинается расчет

Когда он закончится программа сообщит и можно нажать Ctrl+C

В результате внутри докера появится файл типа ./src/data/payout_transactions_20210311030118768_1_1676.json

где последние две цифры - это как раз с какого по какой блок учтены расчеты (поможет запускать в следующий раз)

Можно посмотреть глазами на этот файл, все ли там в порядке и отправить все награды записанные там, пользователям!



