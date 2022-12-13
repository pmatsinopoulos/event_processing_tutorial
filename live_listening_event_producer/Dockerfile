FROM public.ecr.aws/lambda/nodejs:16.2022.11.24.16-x86_64

RUN npm install yarn -g

COPY package.json yarn.lock ${LAMBDA_TASK_ROOT}

RUN yarn install --non-interactive

COPY app.js ${LAMBDA_TASK_ROOT}

CMD [ "app.handler" ]
