# Описание `deploy.yml`

Workflow запускается при каждом push в ветку `master`. Он собирает Docker-образ из `Dockerfile` в корне репозитория и публикует его в GitHub Container Registry (GHCR) с тегами `latest` и коротким SHA коммита.

## Используемые значения

| Выражение или настройка | Назначение | Где взять или настроить |
| --- | --- | --- |
| `github.repository` | Имя репозитория в формате `владелец/репозиторий`; используется как имя образа `ghcr.io/<владелец>/<репозиторий>`. | Контекст GitHub Actions заполняет автоматически. Посмотреть значение можно в URL репозитория: `github.com/<владелец>/<репозиторий>`. |
| `github.actor` | Пользователь или GitHub App, запустившие workflow; используется как имя для входа в GHCR. | Контекст GitHub Actions заполняет автоматически для каждого запуска. |
| `secrets.GITHUB_TOKEN` | Временный токен запуска для авторизации в GHCR. | GitHub создаёт его автоматически. Добавлять его в `Settings → Secrets and variables → Actions` не нужно. |
| `steps.meta.outputs.tags` | Теги, сформированные шагом с `id: meta`: `latest` и короткий SHA коммита. | Автоматический выход `docker/metadata-action`; вручную не задаётся. |
| `steps.meta.outputs.labels` | Docker-метки образа, сформированные шагом `meta`. | Автоматический выход `docker/metadata-action`; вручную не задаётся. |
| `permissions.packages: write` | Разрешает `GITHUB_TOKEN` публиковать пакет в GHCR. | Уже задано в `deploy.yml`; это разрешение workflow, а не секрет или переменная репозитория. |

## Что нужно настроить в GitHub

Для текущего workflow не требуется создавать собственные Actions variables, secrets или Personal Access Token. `GITHUB_TOKEN` предоставляется GitHub автоматически.

Если публикация завершается ошибкой доступа, проверьте настройки разрешений workflow в `Settings → Actions → General → Workflow permissions` и ограничения организации на публикацию пакетов. Workflow также должен иметь право `packages: write`, уже указанное в `deploy.yml`.

После успешного запуска пакет появится в разделе **Packages** владельца или репозитория. Его имя будет иметь вид `ghcr.io/<владелец>/<репозиторий>`.
