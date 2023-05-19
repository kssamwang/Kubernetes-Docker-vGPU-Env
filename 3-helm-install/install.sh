#!/bin/bash
chown root:root ./helm
cp -f ./helm /usr/local/bin/helm
helm version
