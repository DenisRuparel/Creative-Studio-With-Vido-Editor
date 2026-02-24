# -------------------------
# 1️⃣ Dependencies stage (ALL deps, including dev)
# -------------------------
FROM node:20-bullseye AS deps

WORKDIR /app

COPY package.json package-lock.json ./

# Install ALL dependencies (needed for build)
RUN npm ci


# -------------------------
# 2️⃣ Build stage
# -------------------------
FROM node:20-bullseye AS builder

WORKDIR /app

COPY --from=deps /app/node_modules ./node_modules
COPY . .

ENV NODE_ENV=production

RUN npm run build


# -------------------------
# 3️⃣ Runtime stage (LEAN)
# -------------------------
FROM node:20-bullseye-slim AS runner

WORKDIR /app

ENV NODE_ENV=production

# Copy only what Next.js needs at runtime
COPY --from=builder /app/package.json ./
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static

EXPOSE 3000

CMD ["node", "server.js"]
