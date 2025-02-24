# VTU Writer

Reimplementation of https://github.com/phmkopp/vtu11 in Zig.

![build](https://github.com/mm318/vtu-writer/actions/workflows/test.yml/badge.svg)


## Development

```bash
git clone https://github.com/mm318/vtu-writer.git
```

To build and run demo:
```bash
zig build run                           # debug build
zig build -Doptimize=ReleaseSafe run    # release build
```

The outputted `test_ascii.vtu` will appear as the following when opened in ParaView  
![VTU Writer demo output](demo.jpg) 

To build and run tests:
```bash
zig build --summary all                             # debug build
zig build -Doptimize=ReleaseSafe test --summary all # release build
```

To format the source code:
```bash
zig fmt .
```


## Requirements

Developed using Ubuntu 20.04 and zig 0.14.0-dev.1911+3bf89f55c (2024.10.0-mach).
