# -------------------------
# 1️⃣ Dependencies stage
# -------------------------
FROM node:20-bullseye AS deps

WORKDIR /app

COPY package.json package-lock.json ./

RUN npm ci --omit=dev


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
# 3️⃣ Runtime stage (SMALL & FAST)
# -------------------------
FROM node:20-bullseye AS runner

WORKDIR /app

ENV NODE_ENV=production

# Copy only what is required to run the app
COPY --from=builder /app/package.json ./
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static

EXPOSE 3000

CMD ["npm", "start"]