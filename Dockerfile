# -------------------------
# 1️⃣ Dependencies stage
# -------------------------
FROM node:20-alpine AS deps
WORKDIR /app

COPY package.json package-lock.json ./

# 🚀 Faster + cached install
RUN --mount=type=cache,target=/root/.npm \
    npm ci --prefer-offline --no-audit

# -------------------------
# 2️⃣ Builder stage
# -------------------------
FROM node:20-alpine AS builder
WORKDIR /app

ENV NEXT_TELEMETRY_DISABLED=1

# Copy dependencies
COPY --from=deps /app/node_modules ./node_modules

# Copy only necessary files first (better caching)
COPY package.json package-lock.json ./
COPY . .

# 🚀 Build app
RUN npm run build

# -------------------------
# 3️⃣ Runner stage
# -------------------------
FROM node:20-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

# 🚀 Reduce image size
RUN addgroup -S nextjs && adduser -S nextjs -G nextjs

COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/public ./public

USER nextjs

EXPOSE 5000
CMD ["node", "server.js"]
