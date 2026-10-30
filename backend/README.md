```
# build docker image, in project root folder, not in ./backend/
docker build --file "$(readlink -e Dockerfile)" --tag grocerymate-app .

# run docker image
docker run --interactive --tty --publish 5000:5000 grocerymate-app

# look where run.py lies
docker run --rm --entrypoint sh grocerymate-app -c 'find /app -name run.py'

# 
docker exec -it grocerymate-app /bin/sh

```
