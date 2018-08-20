echo "postrm"

# not sure what this does...
%systemd_postun_with_restart docker-volume-local-persist.service
