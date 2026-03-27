# -------------------------
# 1️⃣ Dependencies stage
# -------------------------
FROM node:20-alpine AS deps
WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

# -------------------------
# 2️⃣ Builder stage
# -------------------------
FROM node:20-alpine AS builder
WORKDIR /app

ENV NEXT_TELEMETRY_DISABLED=1

# Copy deps
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# ❗ Disable turbopack explicitly
RUN npm run build -- --no-turbo

# -------------------------
# 3️⃣ Runner stage
# -------------------------
FROM node:20-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/public ./public

EXPOSE 5000
CMD ["node", "server.js"]
