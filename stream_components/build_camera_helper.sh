#!/bin/bash

#realpath $0
cd $(dirname $(realpath $0))/build && cmake .. && make
