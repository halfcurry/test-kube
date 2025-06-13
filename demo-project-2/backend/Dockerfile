# demo-project-2/backend/Dockerfile
FROM python:3.9-slim-buster

WORKDIR /app

# Install Python dependencies
COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the Flask application
COPY backend/app.py .

EXPOSE 5000

CMD ["python", "app.py"]