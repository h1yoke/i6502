#include "bus_module.h"

#include <stdint.h>
#include <stdlib.h>

/* MARK: - Bus initializer & deinitializer */

BusState * bus_create() {
    BusState *bus = malloc(sizeof(BusState));
    for (size_t i = 0; i < 65536; ++i) {
        bus->ram[i] = rand();
    }
}

void bus_destroy(BusState *bus) {
    free(bus);
}

/* MARK: - Bus actions */

uint8_t bus_read(BusState *bus, uint16_t address) {
    return bus->ram[address];
}

void bus_write(BusState *bus, uint16_t address, uint8_t value) {
    bus->ram[address] = value;
}
