Набор скриптов для создания базовых образов Docker
```
Использование: make <target>

 * 'print-%' - print-{ПЕРЕМЕННАЯ} - выводит значение переменной во время выполнения программы

 * 'prepare' - Установить все необходимые для работы конвейера зависимости

 * 'shellcheck' - Выполнить проверку bash скриптов линтером
 * 'typos' - Выполнить проверку на грамматические ошибки
 * 'fix-typos' - Исправить грамматические ошибки

 * 'install-docker' - Установить docker-ce
 * 'install-podman' - Установить podman
 * 'install-trivy' - Установить trivy - инструмент для сканирования образов docker на уязвимости
 * 'enable-docker-experimental' - Включить экспериментальные функции docker-ce
 * 'install-qemu-user-static' - Зарегистрировать в системе binfmt_misc, скачать и установить qemu-user-static

 ============================
  ** Debian Linux targets **
 ============================

|debian11|
|debian11-java|
|debian11-java-slim|
|debian11-graal|
|debian11-graal-slim|
|debian11-java-slim-maven|
|debian11-java-slim-gradle|
```