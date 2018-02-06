#!/bin/sh

/usr/bin/str2str -in tcpsvr://127.0.0.1:3123#rtcm3 -out tcpsvr://:3133#rtcm3 -msg "1006(10)" -t 1 -s 30000


