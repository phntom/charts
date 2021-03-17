FROM mattermost/mattermost-team-edition:5.32.1
RUN rm -rfv client/* || true
COPY --chown=2000:2000 dist/ client/
