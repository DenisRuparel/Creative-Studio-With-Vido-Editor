# -------------------------
# 1️⃣ Dependencies stage (cached layer)
# -------------------------
FROM node:20-alpine AS deps

WORKDIR /app

# Install dependencies separately (better caching)
COPY package.json package-lock.json ./
RUN npm ci

# -------------------------
# 2️⃣ Build stage
# -------------------------
FROM node:20-alpine AS builder

WORKDIR /app

ENV NEXT_TELEMETRY_DISABLED=1

# Reuse node_modules from deps
COPY --from=deps /app/node_modules ./node_modules

# Copy only necessary files (better cache behavior)
COPY package.json package-lock.json ./
COPY next.config.js ./
COPY public ./public
COPY src ./src

# Build app
RUN npm run build

# -------------------------
# 3️⃣ Runtime stage (lightweight)
# -------------------------
FROM node:20-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

# Copy standalone output (smaller image)
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/public ./public

EXPOSE 5000

CMD ["node", "server.js"]
