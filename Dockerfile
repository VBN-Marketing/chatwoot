ARG CHATWOOT_VERSION=v4.13.0
FROM chatwoot/chatwoot:${CHATWOOT_VERSION}

COPY lib/tasks/enterprise_activation.rake /app/lib/tasks/enterprise_activation.rake
COPY docker-entrypoint-custom.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["bundle", "exec", "rails", "s", "-p", "3000", "-b", "0.0.0.0"]
