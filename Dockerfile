FROM ubuntu:24.04 AS build
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl git unzip xz-utils libglu1-mesa && rm -rf /var/lib/apt/lists/*
RUN git clone --depth 1 --branch 3.47.5 https://github.com/flutter/flutter.git /opt/flutter
ENV PATH="/opt/flutter/bin:${PATH}"
WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN flutter config --no-analytics && flutter pub get
COPY . .
ARG SUPABASE_URL
ARG SUPABASE_PUBLISHABLE_KEY
ARG ENABLE_NUTRITION_ASSISTANT=false
RUN test -n "$SUPABASE_URL" && test -n "$SUPABASE_PUBLISHABLE_KEY" && \
    case "$SUPABASE_PUBLISHABLE_KEY" in sb_publishable_*) ;; *) echo 'Use a Supabase publishable key, never a server secret'; exit 1 ;; esac && \
    flutter build web --release --base-href / \
    --dart-define="SUPABASE_URL=$SUPABASE_URL" \
    --dart-define="SUPABASE_PUBLISHABLE_KEY=$SUPABASE_PUBLISHABLE_KEY" \
    --dart-define="ENABLE_NUTRITION_ASSISTANT=$ENABLE_NUTRITION_ASSISTANT"

FROM nginx:1.28-alpine
ENV PORT=8080
# Substitute PORT only; preserve nginx variables such as $uri.
ENV NGINX_ENVSUBST_FILTER=^PORT$
COPY deploy/default.conf.template /etc/nginx/templates/default.conf.template
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 8080
