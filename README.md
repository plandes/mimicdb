# MIMIC-III database docker container

[MIMIC-III] is a corpus has 58,976 hospital admission and 2,083,180 had written
notes by medical professionals.  This repo contains [Docker] configuration
files and a GNU `makefile` create and control the life cycle of a [Postgres]
database containing the [MIMIC-III] corpus.  The [Docker] [Postgres] container
is populated with the [MIMIC-III] corpus using scripts from the [MIMIC Code
Repository].


## Installation

The installation of the database isn't trivial.  Even though everything is
automated, there is a lot that can go wrong.  For this reason, images of the
database are available by the author with **provided proof** you have taking the
PhysioNet [MIMIC-III] training.  The steps to install are as follows:

1. Clone this repository: `git --recurse-submodules
   https://github.com/plandes/mimicdb.git`
1. Do the PhysioNet [MIMIC-III training].  Only after you have done this do you
   have access to the corpus source data.
1. Download the source [MIMIC-III] data files as the file
   `mimic-iii-clinical-database-1.4.zip` to this directory.
1. Install the [Postgres] client:
   * macOS: `brew install libpq`
   * Linux: `apt install postgresql postgresql-contrib`
   * Windows: [Installer](https://www.postgresql.org/download/windows)
1. Install [git], [Docker], and [GNU make]
1. Edit the *user editable values* section of the [makefile] to
   make any changes such as the database name, user, or port.
1. Bring up the database [Docker] container and install the database: `make
   world`.
   
The last step does the following:
1. Decompresses the [MIMIC-III] data files.
1. Clones the [MIMIC Code Repository].
1. Generates passwords in `password.txt` and `sa-password.txt`.
1. Uses the [MIMIC Code Repository] to load the [Postgres] database with the
   corpus.
1. Creates the `mimic3` database user and grants the user `select` rights.
1. Shuts down the instance.


## Usage

* To start the container: `make up`
* To stop the container: `make down`
* To login to the database as a user: `make userlogin`
* To login to the database as the system administrator: `make rootlogin`

A bash script could be created to do everything the [makefile] does very
easily.  If you do that, please send it to me and I will add it to this repo.


## Changelog

An extensive changelog is available [here](CHANGELOG.md).


## License

[MIT License](LICENSE.md)

Copyright (c) 2023 Paul Landes


<!-- links -->
[Docker]: https://www.docker.com
[git]: https://git-scm.com
[GNU make]: https://www.gnu.org/software/make/
[Postgres]: https://www.postgresql.org
[MIMIC-III]: https://mimic.mit.edu/docs/iii/
[MIMIC-III training]: https://mimic.mit.edu/docs/gettingstarted/
[MIMIC Code Repository]: https://github.com/MIT-LCP/mimic-code.git
[makefile]: ./makefile
