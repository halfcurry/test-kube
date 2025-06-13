# demo-project-2/backend/app.py
from flask import Flask, request, jsonify
import os
import time
import random
# import requests # Uncomment if you want to integrate with an actual LLM API

app = Flask(__name__)

# Environment variables will be populated from Kubernetes Secrets and ConfigMaps
DB_HOST = os.environ.get('DB_HOST', 'localhost')
DB_NAME = os.environ.get('DB_NAME', 'chatbot_db')
DB_USER = os.environ.get('DB_USER', 'chatbot_user')
DB_PASSWORD = os.environ.get('DB_PASSWORD', 'default_password')

REDIS_HOST = os.environ.get('REDIS_HOST', 'localhost')
REDIS_PORT = os.environ.get('REDIS_PORT', '6379')

# Chatbot AI prompt (from ConfigMap)
AI_PROMPT = os.environ.get('AI_PROMPT', 'You are a friendly chatbot.')

@app.route('/chat', methods=['POST'])
def chat():
    """
    Handles chat messages, simulates AI processing, DB interaction, and messaging.
    """
    user_message = request.json.get('message', '')
    print(f"Received message: {user_message}")

    # Simulate database interaction (e.g., logging message, fetching user history)
    # In a real app, you'd connect to PostgreSQL here using psycopg2
    print(f"Simulating DB interaction for message: {user_message}")
    # time.sleep(0.1) # Simulate network latency

    # Simulate sending message to a queue (e.g., for async processing)
    # In a real app, you'd connect to Redis and publish/subscribe here
    print(f"Simulating Redis interaction for message: {user_message}")
    # time.sleep(0.05) # Simulate network latency

    # --- AI Logic (Minimalistic for demo) ---
    ai_response = "I'm a simple chatbot. I heard: " + user_message

    # Example of calling an LLM (uncomment and configure for actual use)
    # try:
    #     prompt_text = f"{AI_PROMPT}\nUser: {user_message}\nChatbot:"
    #     api_key = os.environ.get("GEMINI_API_KEY", "") # Get API key from environment
    #     if not api_key:
    #         raise ValueError("GEMINI_API_KEY not set for LLM integration.")
    #
    #     payload = {"contents": [{"role": "user", "parts": [{"text": prompt_text}]}]}
    #     api_url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key={api_key}"
    #     
    #     response = requests.post(api_url, headers={'Content-Type': 'application/json'}, json=payload)
    #     response.raise_for_status() # Raise HTTPError for bad responses (4xx or 5xx)
    #     result = response.json()
    #     
    #     if result.get('candidates') and result['candidates'][0].get('content') and result['candidates'][0]['content'].get('parts'):
    #         ai_response = result['candidates'][0]['content']['parts'][0]['text']
    #     else:
    #         ai_response = "Error: Could not get a valid response from the AI model."
    #         print(f"LLM API response structure unexpected: {result}")
    #
    # except requests.exceptions.RequestException as e:
    #     ai_response = f"Error connecting to AI: {e}"
    #     print(f"LLM API request failed: {e}")
    # except ValueError as e:
    #     ai_response = f"Configuration error: {e}"
    #     print(f"LLM API configuration error: {e}")
    # except Exception as e:
    #     ai_response = f"An unexpected error occurred: {e}"
    #     print(f"Unexpected error in LLM call: {e}")

    return jsonify({"response": ai_response})

@app.route('/healthz')
def healthz():
    """Simple health check endpoint for liveness and readiness probes."""
    return "OK", 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)