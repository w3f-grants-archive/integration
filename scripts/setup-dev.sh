#!/bin/bash
git submodule update --init --recursive --force --checkout
cd ./protocol && yarn
