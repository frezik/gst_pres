#!/bin/bash
gst-launch-1.0 v4l2src device=/dev/video0 \
    ! 'video/x-raw,width=320,height=240' \
    ! videoconvert \
    ! edgedetect \
    ! videoconvert \
    ! xvimagesink
