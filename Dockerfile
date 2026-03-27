# syntax=docker/dockerfile:1

# -------------------------
# 1) Dependencies stage
# -------------------------
FROM node:20-alpine AS deps
WORKDIR /app

# Keep install deterministic and quiet.
ENV npm_config_audit=false \
    npm_config_fund=false \
    npm_config_loglevel=warn

COPY package.json package-lock.json ./
RUN npm ci --omit=dev --prefer-offline

# -------------------------
# 2) Builder stage
# -------------------------
FROM node:20-alpine AS builder
WORKDIR /app

# Low-resource build tuning for 2 vCPU / 2 GB runners.
ENV NEXT_DISABLE_TURBOPACK=1 \
    NEXT_TELEMETRY_DISABLED=1 \
    CI=true \
    NODE_OPTIONS="--max-old-space-size=1024"

# Copy only what is needed first for better cache hits.
COPY package.json package-lock.json ./
COPY --from=deps /app/node_modules ./node_modules

# Project files (reduced by .dockerignore)
COPY . .

# Build in production mode to reduce memory footprint.
RUN npm run build

# -------------------------
# 3) Runtime stage
# -------------------------
FROM node:20-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production \
    NEXT_TELEMETRY_DISABLED=1 \
    PORT=5000

RUN addgroup -S nextjs && adduser -S nextjs -G nextjs

# Only runtime artifacts.
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/public ./public

USER nextjs
EXPOSE 5000
CMD ["node", "server.js"]
