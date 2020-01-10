FROM node:latest
COPY entrypoint.sh ./entrypoint.sh
COPY package*.json ./
RUN npm install
ENTRYPOINT ["./entrypoint.sh"]
