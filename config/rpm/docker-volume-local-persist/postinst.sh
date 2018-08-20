echo "postinst"

# register service
%systemd_post docker-volume-local-persist.service

# non standard stuff, start the service asap
systemctl start docker-volume-local-persist.service
