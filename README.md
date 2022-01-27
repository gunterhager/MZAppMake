# MZAppMake

Creates apps for the Sharp MZ-800 from binary files. It can create MZT tape files or WAV audio files.

## Usage

```
mz-app-make --input <input> [--input-as-tape] [--load <load>] [--start <start>] [--audio] [--fast]
```

| Option            | Description                                                          |
|-------------------|----------------------------------------------------------------------|
| `--input <input>` | Input: binary file or tape file.                                     |
| `--input-as-tape` | Interpret input file as tape file (`MZF`). (default: `false`)        |
| `--load <load>`   | Load address, has no effect when input is tape. (default: `0x1500`)  |
| `--start <start>` | Start address, has no effect when input is tape. (default: `0x1500`) |
| `--audio`         | Create WAV file. (default: `false`)                                  |
| `--fast`          | Using fast mode when creating `WAV` file. (default: `false`)         |
| `-h`, `--help`    | Show help information.                                               |
