FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY hello.py .

EXPOSE 5001

# Production server
CMD ["gunicorn", "-b", "0.0.0.0:5001", "hello:app", "--workers=2", "--threads=4", "--timeout=30"]
