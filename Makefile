.PHONY: up down create destroy logs health simulate clean

up:
	docker rm -f nginx 2>/dev/null || true
	docker run -d --name nginx -p 80:80 \
		-v $(PWD)/nginx/nginx.conf:/etc/nginx/nginx.conf \
		-v $(PWD)/nginx/conf.d:/etc/nginx/conf.d \
		nginx:alpine
	nohup ./cleanup_daemon.sh > logs/cleanup.log 2>&1 &
	python3 platform/api.py > logs/api.log 2>&1 &

down:
	docker stop nginx && docker rm nginx
	for file in envs/*.json; do \
		ENV_ID=$$(basename $$file .json); \
		./platform/destroy_env.sh $$ENV_ID; \
	done
	pkill -f cleanup_daemon.sh || true
	pkill -f api.py || true

create:
	@read -p "Enter env name: " NAME; \
	read -p "Enter TTL (default 1800): " TTL; \
	./platform/create_env.sh $$NAME $${TTL:-1800}

destroy:
	./platform/destroy_env.sh $(ENV)

logs:
	tail -f logs/$(ENV)/app.log

health:
	@for file in envs/*.json; do \
		cat $$file | python3 -c "import sys,json; d=json.load(sys.stdin); print(f\"Env: {d['id']} | Status: {d['status']} | Failures: {d['consecutive_failures']}\")"; \
	done

simulate:
	./platform/simulate_outage.sh --env $(ENV) --mode $(MODE)

clean:
	rm -rf envs/* logs/archived/* logs/*.log