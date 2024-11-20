# Stage 1: Build the Application
FROM node:18 

# Set the working directory
WORKDIR /app

# Copy package.json and package-lock.json to the working directory
COPY package*.json ./

# Clean the npm cache
RUN npm cache clean --force

# Install npm dependencies
RUN npm install

# Copy the rest of the application code to the working directory
COPY . .

CMD ["npm","run","dev"]
