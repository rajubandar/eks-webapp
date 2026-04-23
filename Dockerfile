# Multi-stage Docker build for a production-ready Node.js app

###############################
# Stage 1: Builder
###############################
FROM node:18-alpine AS builder

# Create app directory
WORKDIR /usr/src/app

# Install dependencies first (leverage Docker layer cache)
COPY package*.json ./

# Install only production dependencies
RUN npm ci --omit=dev

# Copy application source
COPY app.js ./app.js

###############################
# Stage 2: Runtime image
###############################
FROM node:18-alpine

# Set NODE_ENV to production
ENV NODE_ENV=production

# Create non-root user and group
RUN addgroup -S nodejs && adduser -S nodejs -G nodejs

# Create app directory
WORKDIR /usr/src/app

# Copy dependencies and app code from builder image
COPY --from=builder /usr/src/app/node_modules ./node_modules
COPY --from=builder /usr/src/app/app.js ./app.js
COPY --from=builder /usr/src/app/package*.json ./

# Expose application port
EXPOSE 3000

# Use non-root user for security
USER nodejs

# Start the application
CMD ["node", "app.js"]
