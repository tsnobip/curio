# --- Stage 1: Build ---
FROM oven/bun:1 AS builder
WORKDIR /app

COPY package.json bun.lock ./
RUN bun install --trust && chmod +x node_modules/sury-ppx/ppx-linux*.exe 2>/dev/null; true

COPY . .
RUN bun run build

# --- Stage 2: Lambda Web Adapter ---
FROM public.ecr.aws/awsguru/aws-lambda-web-adapter:0.9.1 AS adapter

# --- Stage 3: Runtime ---
FROM oven/bun:1-slim

COPY --from=adapter /lambda-adapter /opt/extensions/lambda-adapter

WORKDIR /app

COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/src ./src
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/public ./public
COPY --from=builder /app/package.json ./

ENV PORT=8080
ENV NODE_ENV=production

ENTRYPOINT ["bun", "run", "src/Server.res.mjs"]
