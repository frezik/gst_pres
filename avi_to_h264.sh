#!/bin/bash
AVI=$1
OUT=$2

gst-launch-1.0 filesrc location=${AVI} ! avidemux ! decodebin ! 'video/x-h264' ! filesink location=${OUT}
