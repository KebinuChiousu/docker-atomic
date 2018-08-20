#!/bin/sh
echo Stopping docker-volume-local-persist service if running
sudo systemctl stop docker-volume-local-persist || true
