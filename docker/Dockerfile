# Stage 1 ---- Build Stage
FROM python:3.9-slim AS builder
WORKDIR /app
COPY app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Stage 2 ---- Final Stage
FROM python:3.9-slim
WORKDIR /app
COPY --from=builder /usr/local/lib/python3.9/site-packages /usr/local/lib/python3.9/site-packages
COPY app/ .
ENV PYTHONUNBUFFERED=1
EXPOSE 5001
CMD ["python", "app.py"]