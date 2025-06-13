# greet_service/app.py
from flask import Flask, os

app = Flask(__name__)

# Get message from environment variable, which will be sourced from ConfigMap
GREET_MESSAGE = os.environ.get('GREET_MESSAGE', 'Default Greetings from Greet Service!')

@app.route('/greet')
def greet_world():
    return GREET_MESSAGE

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)