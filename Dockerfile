FROM node:22.17.1-alpine3.22

WORKDIR /app

COPY package.json package.json
COPY package-lock.json package-lock.json

RUN npm ci

COPY tsconfig.json tsconfig.json
COPY rollup.config.ts rollup.config.ts
COPY entrypoint.sh entrypoint.sh
COPY src/ src/

RUN npm run build

RUN ls -l /app

ENTRYPOINT ["/bin/sh", "-c", "/app/entrypoint.sh"]
