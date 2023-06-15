#!/bin/sh

cat <<EOF > /etc/supervisord.conf
[supervisord]
nodaemon=true
logfile=syslog

[program:oauth2-proxy]
command=/bin/oauth2-proxy --config=/etc/oauth2-proxy/oauth2-proxy.conf --reverse-proxy=true --http-address="127.0.0.1:8081"
redirect_stderr=true
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes = 0

[program:lambda-proxy]
command=/bin/lambda-proxy
redirect_stderr=true
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes = 0

[program:cmd]
command=$@
redirect_stderr=true
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes = 0


[eventlistener:processes]
command=sh -c "echo READY && read line && kill -SIGQUIT $PPID"
events=PROCESS_STATE_FATAL
EOF

exec "supervisord"