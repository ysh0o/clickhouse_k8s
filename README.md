# ClickHouse in Kubernetes 

Простая установка одиночного инстанса ClickHouse в Kubernetes с параметрами версии и пользователей.

## Что это

- Поднимается один Pod с ClickHouse (single‑instance).
- Версия ClickHouse задаётся через файл `config.env` и образ `clickhouse/clickhouse-server:<version>`.
- Пользователи и пароли задаются в `config.env`, из них генерируется `users.xml`, который кладётся в Kubernetes Secret.


## Настройка параметров

Файл `config.env`:

Версия образа ClickHouse
CLICKHOUSE_VERSION="24.3"

Основной админ-пользователь
CH_ADMIN_USER="admin"
CH_ADMIN_PASSWORD="admin_password"

Обычный пользователь №1
CH_USER1_NAME="user1"
CH_USER1_PASSWORD="user1_password"

Обычный пользователь №2 
CH_USER2_NAME="user2"
CH_USER2_PASSWORD="user2_password"

Namespace в Kubernetes
K8S_NAMESPACE="clickhouse"


Перед установкой можно поменять версию ClickHouse и логины/пароли под свои нужды.

## Установка

Требования:
- Работающий Kubernetes‑кластер.
- Установлен и настроен `kubectl` для доступа к кластеру.

Шаги:

git clone https://github.com/<your_login>/clickhouse_k8s.git
cd clickhouse_k8s

По желанию отредактировать параметры
nano config.env

Сделать скрипт исполняемым
chmod +x install.sh

Установка ClickHouse
./install.sh


Скрипт:
- создаёт namespace ;
- генерирует файл `users.xml` с пользователями из `config.env`;
- создаёт/обновляет Secret `clickhouse-users`;
- применяет манифесты в папке `k8s/` (`ConfigMap`, `Deployment`, `Service`).

## Проверка

Проверить Pod и Service:

kubectl -n clickhouse get pods
kubectl -n clickhouse get svc


Ожидается:
- один Pod `clickhouse-...` в статусе `Running`;
- Service `clickhouse` с портами `9000` (TCP) и `8123` (HTTP).

Посмотреть логи ClickHouse:

kubectl -n clickhouse logs -l app=clickhouse


## Подключение к ClickHouse

Подключиться к базе из Pod:

kubectl -n clickhouse exec -it deploy/clickhouse --
clickhouse-client -u admin --password admin_password --query "SELECT 1"


Логин и пароль берутся из `config.env` (`CH_ADMIN_USER` и `CH_ADMIN_PASSWORD`).

Проверка обычного пользователя `user1`:

kubectl -n clickhouse exec -it deploy/clickhouse --
clickhouse-client -u user1 --password user1_password --query "SELECT currentUser()"


## Как поменять версию ClickHouse

1. В `config.env` поменять:

CLICKHOUSE_VERSION="24.3"


2. В манифесте `k8s/clickhouse-deployment.yaml` отредактировать строку с образом:

image: clickhouse/clickhouse-server:24.3


3. Применить изменения:

kubectl -n clickhouse apply -f k8s/clickhouse-deployment.yaml


Так можно указать нужный тег образа ClickHouse.

## Как удалить установку

kubectl -n clickhouse delete -f k8s/clickhouse-service.yaml
kubectl -n clickhouse delete -f k8s/clickhouse-deployment.yaml
kubectl -n clickhouse delete -f k8s/clickhouse-configmap.yaml
kubectl -n clickhouse delete secret clickhouse-users
kubectl delete namespace clickhouse


После этого ClickHouse и все связанные ресурсы будут удалены из кластера Kubernetes.
