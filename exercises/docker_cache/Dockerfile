# This will be our base layer
FROM alpine:3.18

# Layer 1: Install some packages
RUN apk add --no-cache curl wget

# Layer 2: Create a directory and add some content
RUN mkdir -p /app/data && echo "Initial data" > /app/data/file1.txt

# Layer 3: Add more content
RUN echo "More data" > /app/data/file2.txt

# Layer 4: Set working directory
WORKDIR /app

# Layer 5: Copy a local file (we'll create this)
COPY hello.txt .

# Layer 6: Final setup
RUN echo "Setup complete" > setup.log
