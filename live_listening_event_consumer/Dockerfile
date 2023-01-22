# node:gallium-slim
FROM node@sha256:345bca77d12ad8f6d2c75c5b8ca0e6de34a84cd7d185af6a3a6c457e7ca64f77

COPY package.json yarn.lock ./

RUN yarn install --non-interactive

COPY app.js .

ENTRYPOINT [ "yarn", "consume" ]
