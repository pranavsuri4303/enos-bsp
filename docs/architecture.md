# ENOS Board — Architecture

## SPI0 Bus Layout

```
Raspberry Pi 5 (BCM2712 / RP1)
│
└── SPI0 (/axi/pcie@1000120000/rp1/spi@50000)
    │
    ├── CS0 (GPIO 8,  pin 24) ─── LoRa #1 (E28-2G4M27SX / SX1280)
    │                              └── /dev/spidev0.0  (userspace)
    │
    ├── CS1 (GPIO 7,  pin 26) ─── LoRa #2 (E28-2G4M27SX / SX1280)
    │                              └── /dev/spidev0.1  (userspace)
    │
    └── CS2 (GPIO 21, pin 40) ─── MCP2518FD (CAN Controller)
                                   ├── can0  (kernel socketCAN)
                                   ├── INT → GPIO 26 (pin 37), active low
                                   └── CLK → 20 MHz ext osc (40 MHz prod)
```

## Pin Map

| Signal | BCM GPIO | Physical Pin | Direction | Function              |
|--------|----------|--------------|-----------|-----------------------|
| MOSI   | 10       | 19           | Out       | SPI0 data out         |
| MISO   | 9        | 21           | In        | SPI0 data in          |
| SCLK   | 11       | 23           | Out       | SPI0 clock            |
| CS0    | 8        | 24           | Out       | LoRa #1 chip select   |
| CS1    | 7        | 26           | Out       | LoRa #2 chip select   |
| CS2    | 21       | 40           | Out       | MCP2518FD chip select |
| INT    | 26       | 37           | In        | MCP2518FD interrupt   |

## Software Stack

```
┌──────────────────┐  ┌──────────────────┐  ┌──────────────────────┐
│  User Application │  │  User Application │  │  socketCAN (kernel)  │
│  (Python/C)       │  │  (Python/C)       │  │  ip link / candump   │
└────────┬─────────┘  └────────┬─────────┘  └──────────┬───────────┘
         │                     │                        │
    /dev/spidev0.0       /dev/spidev0.1           mcp251xfd driver
         │                     │                        │
└────────┴─────────────────────┴────────────────────────┘
                          SPI0 Bus (RP1)
```

## Device Tree Overlay Strategy

| What                          | How                              |
|-------------------------------|----------------------------------|
| Enable SPI0 (2 default CS)    | `dtparam=spi=on` (stock)         |
| spidev0.0 + spidev0.1         | Automatic from `dtparam=spi=on`  |
| MCP2518FD on CS2 (GPIO 21)   | `dtoverlay=enos-can` (custom)    |
| CAN interface auto-config     | systemd-networkd (80-can0.network) |

## CAN Bus

- Controller: MCP2518FD (CAN FD capable)
- Bitrate: 250 kbps (configurable in `can0.network`)
- Oscillator: 20 MHz development / 40 MHz production
- Transceiver: (external, not controlled by overlay)
