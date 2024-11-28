#!/bin/sh
vncserver -securitytypes none -localhost no --I-KNOW-THIS-IS-INSECURE -geometry 1024x768 && tail -f /root/.vnc/*.log
