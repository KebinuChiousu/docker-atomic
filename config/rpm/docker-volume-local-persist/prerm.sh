echo "prerm"

# non standard stuff, stop the service asap
systemctl stop docker-volume-local-persist.service

# unregister the service
%systemd_preun docker-volume-local-persist.service
