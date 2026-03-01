FROM node:22.17.1-alpine3.22

WORKDIR /app

COPY package.json package.json
COPY package-lock.json package-lock.json

RUN npm ci

COPY tsconfig.json tsconfig.json
COPY rollup.config.ts rollup.config.ts
COPY entrypoint.sh entrypoint.sh
COPY src/ src/

# Fix line endings for the entrypoint script and make it executable
RUN sed -i 's/\r$//' /app/entrypoint.sh && chmod +x /app/entrypoint.sh

RUN npm run build

RUN ls -l /app

ENTRYPOINT ["/app/entrypoint.sh"]
