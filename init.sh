#!/bin/bash
# Compatibilidade: ./init.sh continua funcionando e delega para bin/setup.
exec "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/bin/setup" "$@"
