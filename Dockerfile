# -------------------------
# 1️⃣ Dependencies stage (for production deps only)
# -------------------------
FROM node:20-alpine AS deps

WORKDIR /app

COPY package.json package-lock.json ./

# Install ONLY production dependencies
RUN npm ci --omit=dev

# -------------------------
# 2️⃣ Runtime stage (final image)
# -------------------------
FROM node:20-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

# Copy production node_modules
COPY --from=deps /app/node_modules ./node_modules

# Copy prebuilt Next.js standalone output (from CI build)
COPY .next/standalone ./
COPY .next/static ./.next/static
COPY public ./public

EXPOSE 5000

CMD ["node", "server.js"]
