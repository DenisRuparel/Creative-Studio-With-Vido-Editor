# -------------------------
# 1️⃣ Dependencies stage
# -------------------------
FROM node:20-alpine AS deps
WORKDIR /app

COPY package.json package-lock.json ./

# 🚀 Cached + faster install
RUN --mount=type=cache,target=/root/.npm \
    npm ci --prefer-offline --no-audit

# -------------------------
# 2️⃣ Builder stage
# -------------------------
FROM node:20-alpine AS builder
WORKDIR /app

# 🔥 Prevent crashes on 8GB machine
ENV NEXT_DISABLE_TURBOPACK=1
ENV NODE_OPTIONS="--max-old-space-size=2048"
ENV NEXT_CPU_COUNT=2
ENV NEXT_TELEMETRY_DISABLED=1

# Copy dependencies
COPY --from=deps /app/node_modules ./node_modules

# Copy project files
COPY . .

# 🚀 Build app (stable)
RUN npm run build

# -------------------------
# 3️⃣ Runner stage
# -------------------------
FROM node:20-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

# 🔐 Security (non-root user)
RUN addgroup -S nextjs && adduser -S nextjs -G nextjs

# Copy only required files
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/public ./public

USER nextjs

EXPOSE 5000
CMD ["node", "server.js"]
