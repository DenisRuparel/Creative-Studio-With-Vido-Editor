# -------------------------
# 1️⃣ Dependencies stage
# -------------------------
FROM node:18-alpine AS deps

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci


# -------------------------
# 2️⃣ Build stage
# -------------------------
FROM node:18-alpine AS builder

WORKDIR /app

COPY --from=deps /app/node_modules ./node_modules
COPY . .

RUN npm run build


# -------------------------
# 3️⃣ Runtime stage
# -------------------------
FROM node:18-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production

# Copy only required files
COPY --from=builder /app/package.json ./
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/node_modules ./node_modules

EXPOSE 3000

CMD ["npm", "start"]