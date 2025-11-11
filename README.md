# JVer

JVer is a lightweight Java version selector for Windows. It lets you pick which installed JDK should be exposed via `JAVA_HOME` and added to the beginning of your `PATH` by updating the user environment variables in the Windows Registry.

> Designed for local development scenarios where multiple JDKs (e.g. `jdk-17`, `jdk-21`, `jdk-24`) coexist under a single directory like `C:\Program Files\Java`.

## Features

- Lists all installed JDKs matching the naming pattern `jdk-*`.
- Marks the currently persisted JDK (`JAVA_HOME` in Registry).
- Sets a new JDK as `JAVA_HOME` and prepends its `bin` to `PATH` (Registry only).
- Uses `%JAVA_HOME%\\bin` expansion (REG_EXPAND_SZ) for portability.
- Requires only a new terminal session to take effect (no service restarts).


## Requirements

- Windows 10/11
- Python >= 3.8
- JDKs installed under a common directory (default: `C:\Program Files\Java`)
- User permissions to write HKCU `Environment` keys

## Installation



## Commands

| Command | Description |
|---------|-------------|
| `JVer list` | Show all JDKs and mark the persisted one. |
| `JVer set`  | Interactive selector: choose number -> updates `JAVA_HOME` + `PATH` in Registry. |
| `JVer current` | Show the currently persisted `JAVA_HOME` (as stored in Registry). |



## How It Works

1. Scans `C:\\Program Files\\Java` for directories starting with `jdk-`.
2. On `set`, writes `JAVA_HOME` as REG_SZ and rewrites user `Path` as REG_EXPAND_SZ placing `%JAVA_HOME%\\bin` first after removing previous Java bin entries.
3. Windows shells started afterwards load the updated environment automatically.


## Install via prebuilt binary

Once releases are published (tag push `vX.Y.Z`), you can install without Python:

```powershell
powershell -ExecutionPolicy Bypass -NoProfile -Command "iex (iwr -useb 'https://raw.githubusercontent.com/Gabzk/jver/main/scripts/install-jver.ps1')"
```

To uninstall (one line):

```powershell
powershell -ExecutionPolicy Bypass -NoProfile -Command "iex (iwr -useb 'https://raw.githubusercontent.com/Gabzk/jver/main/scripts/uninstall-jver.ps1')"
```

## Roadmap / Ideas

- Configurable JDK root directory via env or CLI flag.
- Install Java JDKs directly from the cli.

## Contributing

PRs and issues welcome. Keep changes focused and documented.

## License

MIT License. See `LICENSE`.

---
Made for fast Java version switching on Windows.
