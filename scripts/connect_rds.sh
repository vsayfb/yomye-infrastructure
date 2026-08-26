aws ssm start-session \
  --target i-0ff9cb97fb04f732f \
  --document-name AWS-StartPortForwardingSessionToRemoteHost \
  --parameters '{
    "host":["yevmiye-postgres.c3e2qawg4nkn.eu-central-1.rds.amazonaws.com"],
    "portNumber":["5432"],
    "localPortNumber":["15432"]
  }'