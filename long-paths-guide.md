# Включение поддержки длинных путей в Git и Windows

## Ситуация 1: Репозиторий ещё не склонирован

> Вы планируете клонировать репозиторий, но ещё не сделали этого.

### Шаг 1: Настройка Git (глобально)

```bash
git config --global core.longpaths true
```

### Шаг 2: Настройка Windows Registry

**Без админских прав:**
```powershell
New-Item -Path 'HKCU:\SYSTEM\CurrentControlSet\Control\FileSystem' -Force | Out-Null
New-ItemProperty -Path 'HKCU:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name 'LongPathsEnabled' -Value 1 -PropertyType DWORD -Force
```

**С админскими правами:**
```powershell
New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name 'LongPathsEnabled' -Value 1 -PropertyType DWORD -Force
```

> ⚠️ Требуется перелогиниться или перезагрузиться.

### Шаг 3: Клонирование репозитория

```bash
git clone <url>
```

---

## Ситуация 2: Репозиторий уже склонирован

> У вас уже есть локальный репозиторий, но возникают проблемы с длинными путями.

### Шаг 1: Настройка Git (локально для этого репо)

```bash
git config core.longpaths true
```

или в папке репозитория:
```bash
git config --local core.longpaths true
```

### Шаг 2: Проверка настроек

```bash
# Показать локальную настройку
git config --get core.longpaths

# Показать глобальную настройку
git config --global --get core.longpaths
```

### Шаг 3: Если проблемы остались — настройка Windows Registry

**Без админских прав:**
```powershell
New-Item -Path 'HKCU:\SYSTEM\CurrentControlSet\Control\FileSystem' -Force | Out-Null
New-ItemProperty -Path 'HKCU:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name 'LongPathsEnabled' -Value 1 -PropertyType DWORD -Force
```

**С админскими правами:**
```powershell
New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name 'LongPathsEnabled' -Value 1 -PropertyType DWORD -Force
```

> ⚠️ Требуется перелогиниться или перезагрузиться.

---

## Проверка настроек

```bash
# Git — локальная настройка репозитория
git config --get core.longpaths

# Git — глобальная настройка
git config --global --get core.longpaths

# Windows Registry (HKLM — система)
reg query "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v LongPathsEnabled

# Windows Registry (HKCU — пользователь)
reg query "HKCU\SYSTEM\CurrentControlSet\Control\FileSystem" /v LongPathsEnabled
```

---

## Быстрые команды

### Всё сразу (без админа) — для нового репо

```powershell
git config --global core.longpaths true
New-Item -Path 'HKCU:\SYSTEM\CurrentControlSet\Control\FileSystem' -Force | Out-Null
New-ItemProperty -Path 'HKCU:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name 'LongPathsEnabled' -Value 1 -PropertyType DWORD -Force
```

### Всё сразу (с админом) — для нового репо

```powershell
git config --global core.longpaths true
New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name 'LongPathsEnabled' -Value 1 -PropertyType DWORD -Force
```