from flask import Flask, request, jsonify
import subprocess, json, os, glob

app = Flask(__name__)

def load_env(env_id):
    path = f"envs/{env_id}.json"
    if not os.path.exists(path):
        return None
    with open(path) as f:
        return json.load(f)

# POST /envs — create env
@app.route('/envs', methods=['POST'])
def create_env():
    data = request.json
    name = data.get('name', 'unnamed')
    ttl = data.get('ttl', 1800)
    result = subprocess.run(
        ['./platform/create_env.sh', name, str(ttl)],
        capture_output=True, text=True
    )
    return jsonify({"message": result.stdout.strip()}), 201

# GET /envs — list active envs
@app.route('/envs', methods=['GET'])
def list_envs():
    envs = []
    for file in glob.glob('envs/*.json'):
        with open(file) as f:
            envs.append(json.load(f))
    return jsonify(envs), 200

# DELETE /envs/:id — destroy env
@app.route('/envs/<env_id>', methods=['DELETE'])
def destroy_env(env_id):
    result = subprocess.run(
        ['./platform/destroy_env.sh', env_id],
        capture_output=True, text=True
    )
    return jsonify({"message": f"Env {env_id} destroyed"}), 200

# GET /envs/:id/logs — last 100 lines
@app.route('/envs/<env_id>/logs', methods=['GET'])
def get_logs(env_id):
    log_path = f"logs/{env_id}/app.log"
    if not os.path.exists(log_path):
        return jsonify({"error": "No logs found"}), 404
    result = subprocess.run(['tail', '-n', '100', log_path], capture_output=True, text=True)
    return jsonify({"logs": result.stdout}), 200

# GET /envs/:id/health — last 10 health checks
@app.route('/envs/<env_id>/health', methods=['GET'])
def get_health(env_id):
    log_path = f"logs/{env_id}/health.log"
    if not os.path.exists(log_path):
        return jsonify({"error": "No health logs found"}), 404
    result = subprocess.run(['tail', '-n', '10', log_path], capture_output=True, text=True)
    return jsonify({"health": result.stdout}), 200

# POST /envs/:id/outage — trigger simulation
@app.route('/envs/<env_id>/outage', methods=['POST'])
def simulate_outage(env_id):
    mode = request.json.get('mode', 'crash')
    result = subprocess.run(
        ['./platform/simulate_outage.sh', '--env', env_id, '--mode', mode],
        capture_output=True, text=True
    )
    return jsonify({"message": f"Outage simulation '{mode}' triggered"}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)