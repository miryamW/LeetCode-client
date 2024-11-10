# Stage 1: Build the Application
FROM node:18 AS build

WORKDIR /app

# Copy project files
COPY . .

# Install dependencies
RUN npm install

# Set environment variable for license key
ARG NUXT_UI_PRO_LICENSE
ENV NUXT_UI_PRO_LICENSE=${NUXT_UI_PRO_LICENSE}

# Build the application
RUN npm run build

# Stage 2: Nginx Server
FROM nginx:alpine

# Copy built content to the second stage
COPY --from=build /app/.nuxt /usr/share/nginx/html

# Copy Nginx configuration file
COPY nginx.conf /etc/nginx/nginx.conf

# Port on which the server will listen
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
