#!/bin/bash

find . -name '*.DS_Store' -type f -delete
dpkg -b com.elijahandandrew.MultiplexerTutorial/ multiplexertutorial.deb

