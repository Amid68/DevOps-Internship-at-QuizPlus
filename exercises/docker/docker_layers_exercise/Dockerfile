FROM alpine:latest

# Layer 1: Update package manager
RUN apk update

# Layer 2: Install a package
RUN apk add --no-cache curl

# Layer 3: Create a directory
RUN mkdir -p /app/data

# Layer 4: Add some content
# RUN echo "Hello from layer 4" > /app/data/message.txt
RUN echo "Hello from layer 5 - now with caching magic!" > /app/data/message.txt
