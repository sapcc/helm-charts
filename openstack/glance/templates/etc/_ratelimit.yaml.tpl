rates:
  # global rate limits counted across all projects
  global:
    images:
      - action: read/list
        limit: 500r/s
    images/image:
      - action: read
        limit: 1000r/s
    images/image/file:
      - action: read
        limit: 50r/s

  # default local rate limits applied to each project
  default:
    images:
      - action: read/list
        limit: 10r/s
      - action: create
        limit: 10r/s
    images/image:
      - action: read
        limit: 10r/s
      - action: update
        limit: 10r/s
    images/image/file:
      - action: read
        limit: 5r/s