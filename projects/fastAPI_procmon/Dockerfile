FROM python:3.11-slim

WORKDIR /app

# gcc is needed for psutil
RUN apt update && apt install gcc -y \
	&& rm -rf /var/lib/apt/lists/*

# requirements might change later in the project that's why I am not combining their installation with prev RUN
COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

# code is more likely to change than requirements.txt which is why i seperated their copy
COPY main.py .

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
