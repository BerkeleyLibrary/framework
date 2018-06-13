#!/bin/sh

rm -rfv tmp/pids/*

exec rails "$@"
