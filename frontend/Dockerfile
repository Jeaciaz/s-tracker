FROM node:alpine as builder

WORKDIR /frontend
COPY package.json package-lock.json ./
ENV CI=1
RUN npm ci

COPY . .
RUN npm run build

FROM nginx:alpine

RUN rm -rf /usr/share/nginx/html/*
COPY --from=builder /frontend/dist /usr/share/nginx/html

COPY ./nginx/nginx.conf /etc/nginx/nginx.conf
COPY ./nginx/ssl /ssl

ENTRYPOINT ["nginx", "-g", "daemon off;"]
