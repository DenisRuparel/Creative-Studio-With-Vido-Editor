# -------------------------
# 1️⃣ Dependencies stage
# -------------------------
FROM node:20-alpine AS deps

WORKDIR /app

# Install dependencies (cached layer)
COPY package.json package-lock.json ./
RUN npm ci

# -------------------------
# 2️⃣ Build stage
# -------------------------
FROM node:20-alpine AS builder

WORKDIR /app

ENV NEXT_TELEMETRY_DISABLED=1

# Reuse node_modules
COPY --from=deps /app/node_modules ./node_modules

# ✅ Copy full project (fixes missing src/next.config issues)
COPY . .

# Build Next.js app
RUN npm run build

# -------------------------
# 3️⃣ Runtime stage (lightweight)
# -------------------------
FROM node:20-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

# ✅ Use standalone output (smaller image)
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/public ./public

EXPOSE 5000

CMD ["node", "server.js"]
