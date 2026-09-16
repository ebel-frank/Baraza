FROM node:20-slim

# Prisma's query/schema engines need OpenSSL; node:20-slim (Debian bookworm) doesn't
# ship it by default, which otherwise fails migrations at container startup.
RUN apt-get update -y && apt-get install -y openssl && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm install

COPY tsconfig.json nest-cli.json ./
COPY prisma ./prisma
RUN npx prisma generate

COPY src ./src
RUN npm run build

# Needed at runtime by `npm run seed` (ts-node runs straight from src/, not dist/).
COPY seed_data ./seed_data

EXPOSE 3000
CMD ["node", "dist/main.js"]
