Docker-образ Mina+Archive
=========================

Образ `local/mina-archive-bp:1.0.2` является заменой образу 
`minaprotocol/mina-daemon-baked:1.0.2-06f3c5c`. Можно заменить 
один другим и нода станет нодой + архивной нодой.

Как собрать
-----------

На машине, где будет собираться образ, необходимо выполнить:

```
git clone https://github.com/rakhmanovr/mina-payout-docker && \
cd mina-archive-docker && \
git clone https://github.com/jrwashburn/mina-pool-payout && \
docker build -t local/mina-archive-bp:1.0.2 .
```

Затем, работаем как с обычным образом minaprotocol/mina-daemon-baked:1.0.2-06f3c5c.

Как обновить
============

В `Dockerfile` этого репозитория директиву `FROM` поправить на актуальную версию. Пересобрать и перезапустить.

![mina-payout-docker:Dockerfile at main · rakhmanovr:mina-payout-docker 2021-03-11 16-01-22](https://user-images.githubusercontent.com/16775625/110784487-310a0900-8283-11eb-9e10-edf8488c9ecf.png)


Запуск скрипта
===============

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

* `MIN_HEIGHT` Указываем 0, если мы запускаем скрипт первый раз, или номер блока, на котором закончили расчет в прошлый раз.
* `MAX_HEIGHT` Указываем на каком блоке закончить подсчет. 
* `STARTING_NONCE` Получаем командой `mina advanced get-nonce --address PUBLICKEY`
* `COMMISSION_RATE` Размер комиссии. По умолчанию 5% _(.05)_
* `DATABASE:URL` postgres://archive:archive@127.0.0.1:5432/archive

_Поля `POOL_PUBLIC_KEY` `SEND_TRANSACTION_FEE` `SEND_PRIVATE_KEY` можно оставить как есть, так как в текущем виде скрипт только производит рассчеты. Поле `MIN_CONFIRMATIONS=290` отвечает за количество блоков (в данном случае 290), которое будет вычтено с конца указанного диапазона, чтобы удостоверится в том, что блок в canonical chain (зеленый) _

Пример:

![Screen Shot 2021-03-11 at 16 06 29](https://user-images.githubusercontent.com/16775625/110785019-d91fd200-8283-11eb-8191-5ee9ef43e7ad.png)


Сохраняем файл и вводим команду:  

```
mina ledger export staking-epoch-ledger > staking-epoch-ledger.json
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

Нажимаем Ctrl+C для выхода

**В результате работы скрипта будут посчитаны только те блоки, которые были произведены в 
период ПОСЛЕ запуска архивной ноды. Информации о блоках ДО запуска в базе нет, соотвенно 
рассчеты по ним производится не будут.**

В результате работы скрипта внутри докера появится файл типа `./src/data/payout_transactions_20210311094926685_0_2025.json` 
где последние две цифры - это диапазон просчитанных блоков, в данном случае 0-2025 (поможет запускать в следующий раз)



