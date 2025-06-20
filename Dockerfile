# Use minimal image
FROM node:18-alpine

# Create app directory
WORKDIR /app

# Copy dependency files
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy app code
COPY . .

# Expose the port
EXPOSE 3000

# Run the app
CMD ["npm", "start"]
