# x86_64 Coroutines Implementation

This project implements coroutines in x86_64 assembly language, demonstrating cooperative multitasking through a simple counter example.

## Acknowledgments

- This implementation is based on [Tsoding's YouTube video on Coroutines in Assembly](https://www.youtube.com/watch?v=sYSP_elDdZw)
- Code comments and documentation were enhanced with the assistance of GPT

## Overview

The project implements a basic coroutine system with the following features:
- Each coroutine gets its own 4KB stack space
- Round-robin scheduling between coroutines
- Cooperative multitasking through explicit yields
- Written in x86_64 assembly with a C demo program

## Building

Requires:
- FASM (Flat Assembler)
- GCC
- Make

To build:
```bash
make
```

## Running

After building, run the demo:
```bash
./main
```

The demo creates two counter coroutines that count from 0 to 9, yielding after each number. The output will show the counters executing in an interleaved fashion.

## Project Structure

- `coroutine.asm` - Core coroutine implementation in assembly
- `main.c` - Demo program showing usage
- `Makefile` - Build configuration
- `main.asm` - Alternative pure assembly implementation
