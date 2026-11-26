# sammann-fnordkollektiv/AWS_Grocery

* [x] Leave fork network to [trigger heatmap](https://docs.github.com/en/account-and-profile/reference/profile-contributions-reference).
* [x] Reference to original repository: https://github.com/AlejandroRomanIbanez/AWS_grocery
* [x] Set default branch to `main`
* [x] Link to original [README.md](./README.orginal.md)
* [x] Setup personal development environment
	* [x] [Codium](https://vscodium.com/)
	* [x] [direnv](https://direnv.net/docs/installation.html)
	* [x] [AWS Login]
  * [x] Automate backups
    * [x] rsync
    * [x] restig
  * [x] Refactor to common.sh
* [x] Do exercises. (see screenshots of succes in `./tests`)
* [ ] Inform tutors, that commits to forks are not counted by heatmap

## TODOS

* [ ] Extend run-more-securely.py to run on AWS _and_ locally. compose.yaml

## Learnings

* Docker
  * Look at files in docker `docker run --rm --entrypoint sh "$DOCKER_TAG" -c 'find /app -maxdepth 3 -type f'`
  * `docker build --file backend/Dockerfile --tag "${DOCKER_TAG}" . && docker run --rm --env-file backend/.env "${DOCKER_TAG}"`
