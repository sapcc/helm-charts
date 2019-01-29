rates:
  # global rate limits counted across all projects
  global:
    auth/tokens:
      - action: authenticate
        limit: 2000r/m

  # default local rate limits counted per project
  default:
    auth/tokens:
      - action: authenticate
        limit: 200r/m
