# Use a specific version of Node on Alpine Linux
FROM node:18-alpine

# Set the working directory
WORKDIR /app

# Copy dependency definitions
COPY package*.json ./

# Install dependencies
RUN npm install 

# Copy the rest of the application source code
COPY . .

# Set the environment to production
ENV PORT=3000

# Create and switch to a non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

# Expose the application port
EXPOSE 3000

# The command to run the application
CMD ["node", "index.js"]