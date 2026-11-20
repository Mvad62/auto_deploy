# Быстрый старт с Docker Compose

Если в Windows PowerShell Compose сообщает об ошибке подключения к `localhost:2375`, укажите канал Docker Desktop перед выполнением команд:

```powershell
$env:DOCKER_HOST = 'npipe:////./pipe/dockerDesktopLinuxEngine'
```

Настройка действует только в текущем окне PowerShell.

При push в ветку `master` GitHub Actions собирает и публикует образ в GHCR:

- `ghcr.io/<owner>/<repository>:latest`
- `ghcr.io/<owner>/<repository>:<commit-sha>`

1. Запуск всех сервисов:
```powershell
docker-compose up --build -d
```

2. Проверка статуса:
```powershell
docker-compose ps
```

3. Просмотр логов:
```powershell
docker-compose logs -f
```

4. Доступ к приложению:
- http://localhost — веб-интерфейс
- http://localhost:5000 — прямой доступ к API

5. Тестирование API:
```powershell
curl http://localhost/api/health
curl http://localhost/api/info
curl http://localhost/api/multiply/10/5
curl http://localhost/api/divide/20/4
```

6. Остановка:
```powershell
docker-compose down
```

7. Пересборка и запуск:
```powershell
docker-compose up --build -d
```
