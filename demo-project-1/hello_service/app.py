# hello_service/app.py
from flask import Flask
import os

app = Flask(__name__)

# Get message from environment variable, which will be sourced from ConfigMap
HELLO_MESSAGE = os.environ.get('HELLO_MESSAGE', 'Default Hello from Hello Service!')

@app.route('/hello')
def hello_world():
    return HELLO_MESSAGE

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)