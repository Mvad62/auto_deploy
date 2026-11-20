# Описание `deploy.yml`

Workflow запускается при каждом push в ветку `master`. Сначала он собирает backend-образ из `Dockerfile` в корне репозитория и публикует его в GitHub Container Registry (GHCR) с тегами `latest` и коротким SHA коммита. Затем job `deploy` использует встроенные OpenSSH `scp`/`ssh`, копирует Compose-файл, frontend и deploy-скрипт на VPS, загружает образ и перезапускает приложение через Docker Compose.

Деплой выполняется напрямую через Docker Compose, вне управления Coolify. Порты `80`/`443` используются reverse proxy Coolify, а `8080` уже занят `coolify-proxy`, поэтому frontend публикуется на `8081`. После разрешения порта в firewall приложение доступно по адресу `http://<VPS_HOST>:8081`.

## Используемые значения

| Выражение или настройка | Назначение | Где взять или настроить |
| --- | --- | --- |
| `github.repository` | Имя репозитория в формате `владелец/репозиторий`; используется как имя образа `ghcr.io/<владелец>/<репозиторий>`. | Контекст GitHub Actions заполняет автоматически. Посмотреть значение можно в URL репозитория: `github.com/<владелец>/<репозиторий>`. |
| `github.actor` | Пользователь или GitHub App, запустившие workflow; используется как имя для входа в GHCR. | Контекст GitHub Actions заполняет автоматически для каждого запуска. |
| `secrets.GITHUB_TOKEN` | Временный токен запуска для авторизации в GHCR. | GitHub создаёт его автоматически. Добавлять его в `Settings → Secrets and variables → Actions` не нужно. |
| `steps.meta.outputs.tags` | Теги, сформированные шагом с `id: meta`: `latest` и короткий SHA коммита. | Автоматический выход `docker/metadata-action`; вручную не задаётся. |
| `steps.meta.outputs.labels` | Docker-метки образа, сформированные шагом `meta`. | Автоматический выход `docker/metadata-action`; вручную не задаётся. |
| `needs.build-and-push.outputs.image` | Точный SHA-тег опубликованного образа; передаётся в deploy job, чтобы сервер загрузил именно собранную версию, а не изменяемый `latest`. | Формируется в job сборки из тегов `docker/metadata-action`. |
| `permissions.packages: write` | Разрешает `GITHUB_TOKEN` публиковать пакет в GHCR. | Уже задано в `deploy.yml`; это разрешение workflow, а не секрет или переменная репозитория. |

## Секреты GitHub Actions

Создайте следующие repository secrets в `Settings → Secrets and variables → Actions → New repository secret`:

| Secret | Значение |
| --- | --- |
| `VPS_HOST` | IP-адрес или DNS-имя VPS. |
| `VPS_USERNAME` | SSH-пользователь для деплоя; он должен иметь доступ к Docker. |
| `VPS_SSH_KEY` | Приватный SSH-ключ. Соответствующий публичный ключ должен быть добавлен в `~/.ssh/authorized_keys` этого пользователя на VPS. |
| `VPS_SSH_FINGERPRINT` | Только отпечаток вида `SHA256:...` Ed25519 host key сервера. Из вывода `ssh-keygen -lf` скопируйте часть, начинающуюся с `SHA256:`; не включайте `256`, имя хоста или тип ключа. |
| `VPS_SSH_PORT` | SSH-порт, если он отличается от `22`; необязателен. |

`GITHUB_TOKEN` и `github.actor` предоставляет GitHub автоматически; создавать для них secrets не нужно. Токен используется workflow для GHCR и временно передаётся на VPS только для `docker pull`; Docker credentials очищаются после деплоя.

## Подготовка VPS

1. На своём компьютере (не на VPS) создайте SSH-ключ `ed25519` для GitHub Actions. В Windows PowerShell:

   ```powershell
   $keyPath = Join-Path $HOME '.ssh\github-actions-deploy'
   New-Item -ItemType Directory -Force (Split-Path $keyPath) | Out-Null
   ssh-keygen -t ed25519 -C 'github-actions-deploy' -f $keyPath
   ```

   Оставьте passphrase пустым: workflow использует ключ без интерактивного запроса. Добавьте содержимое файла `$keyPath.pub` в `~/.ssh/authorized_keys` пользователя `VPS_USERNAME` на VPS. Содержимое приватного файла `$keyPath` сохраните в GitHub Secret `VPS_SSH_KEY`; не коммитьте и не отправляйте его в чат.
2. Для `VPS_SSH_FINGERPRINT` нужен отпечаток **host key VPS**, а не отпечаток ключа `github-actions-deploy`. На VPS получите его командой `sudo ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub` и сверьте по доверенному каналу.
3. Дайте `VPS_USERNAME` доступ к Docker (например, добавьте его в группу `docker`) и проверьте, что работает команда `docker compose version`. Пользователь группы `docker` фактически получает root-доступ к серверу.
4. Создайте каталог для файлов деплоя и назначьте его владельцем SSH-пользователя. В примере замените `deploy` на значение `VPS_USERNAME`:

   ```sh
   DEPLOY_USER=deploy
   sudo mkdir -p /opt/auto-deploy
   sudo chown "$DEPLOY_USER:$DEPLOY_USER" /opt/auto-deploy
   sudo usermod -aG docker "$DEPLOY_USER"
   ```

5. Backend привязан только к `127.0.0.1:5000`; frontend публикуется на `8081`. На VPS с root-доступом разрешите входящий трафик:

   ```sh
   ufw allow 8081/tcp
   ufw status
   ```

   Если у провайдера есть отдельный firewall/security group, разрешите `TCP 8081` и там.

После успешного запуска пакет появится в разделе **Packages** владельца или репозитория под именем `ghcr.io/<владелец>/<репозиторий>`. Контейнеры этого Compose-проекта Coolify напрямую не управляет.
