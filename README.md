TalkASM - Simple Chat written in x86 NASM
============

![TalkASM Preview](https://raw2.github.com/OzTamir/TalkASM/master/demo.png)

## Introduction
TalkASM is a simple instant-messaging (IM) utility written almost entirly in x86 Assembly language (NASM) and is meant to be run on a Ubuntu host (both client and server). For a GUI I've used the great Gtk+ library.

## Files

#### Main files:
 - client.asm: The client version of TalkASM
 - server.asm: The server version of TalkASM
 - chat.glade: Glade XML file; Layout and UI definitions

#### Data Files
 - constants.asm: Naming conventions for many int 80h calls (for readability)
 - data.asm: Data and variables shared between the client and server

#### Macros
 - GUIMacros.asm: Various GUI-related macros
 - macros.asm: Various macros

#### Utilities
 - sockets.asm: Sub-routines to ease Socket Actions
 - util.asm: Utilities sub-routines
 - util.c: An example of C/NASM interplay using few helper functions written in C

### Note
This repo is the result of a school-project I've worked on for few monthes now. The final result are in "Project" sub-directory, but the files in the main folder are subject to refactoring and are NOT the final project files.
