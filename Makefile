build:
	docker build -t meredithkm/atomic .
rebuild:
	docker build --no-cache -t meredithkm/atomic .
start:
	docker-compose up -d
stop:
	docker-compose down
destroy:
	sudo rm -rf $(shell docker inspect docker-atomic_fedora | jq '.[].Mountpoint' -r)
	docker-compose down -v
check:
	docker-compose ps
