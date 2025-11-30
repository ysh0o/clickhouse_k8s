#!/bin/bash
# install.sh - Установка ClickHouse в Kubernetes

set -e  # Если какая-то команда падает - скрипт завершится с ошибкой

# Загружаем переменные из config.env 
source ./config.env

# Проверяем, что kubectl доступен
if ! command -v kubectl >/dev/null 2>&1; then
  echo "Установите kubectl."
  exit 1
fi

echo "=== Установка ClickHouse в namespace: ${K8S_NAMESPACE} ==="

# Создаём namespace 
kubectl get namespace "${K8S_NAMESPACE}" >/dev/null 2>&1 || \
  kubectl create namespace "${K8S_NAMESPACE}"

# Генерируем временный файл users.xml на основе переменных из config.env
cat > /tmp/clickhouse-users.xml <<EOF
<clickhouse>
    <users>
        <${CH_ADMIN_USER}>
            <password>${CH_ADMIN_PASSWORD}</password>
            <profile>default</profile>
            <networks>
                <ip>::/0</ip>
            </networks>
        </${CH_ADMIN_USER}>

        <${CH_USER1_NAME}>
            <password>${CH_USER1_PASSWORD}</password>
            <profile>default</profile>
            <networks>
                <ip>::/0</ip>
            </networks>
        </${CH_USER1_NAME}>

        <${CH_USER2_NAME}>
            <password>${CH_USER2_PASSWORD}</password>
            <profile>default</profile>
            <networks>
                <ip>::/0</ip>
            </networks>
        </${CH_USER2_NAME}>
    </users>
</clickhouse>
EOF

# Создаём/обновляем Secret с пользователями в Kubernetes
kubectl -n "${K8S_NAMESPACE}" delete secret clickhouse-users 2>/dev/null || true
kubectl -n "${K8S_NAMESPACE}" create secret generic clickhouse-users \
  --from-file=users.xml=/tmp/clickhouse-users.xml

echo "Secret clickhouse-users создан."

# Применяем манифесты Kubernetes 
kubectl -n "${K8S_NAMESPACE}" apply -f k8s/clickhouse-configmap.yaml
kubectl -n "${K8S_NAMESPACE}" apply -f k8s/clickhouse-deployment.yaml
kubectl -n "${K8S_NAMESPACE}" apply -f k8s/clickhouse-service.yaml

echo "=== Установка завершена. Проверьте pod и сервис: ==="
echo "kubectl -n ${K8S_NAMESPACE} get pods"
echo "kubectl -n ${K8S_NAMESPACE} get svc"
