FROM node:17.8.0-slim

ARG NODE_ENV=production
ENV NODE_ENV=$NODE_ENV

ARG PORT=5000
ENV PORT=$PORT

RUN groupadd -g 10001 app && \
  useradd -u 10000 -g app app

COPY package.json package-lock.json ./
RUN npm ci
COPY . ./

USER 10000:10001

EXPOSE ${PORT}
CMD [ "npm", "start" ]