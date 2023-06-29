# (@)Id: makefile automates the build and deployment for docker projects
#
# The postgres client (psql binary) needs to be installed for the docker image.
# The downloaded MIMIC-III uncompressed CSV files should be put in
# `mimic-data`.
#
# Paul Landes  6/25/2023


## Config
#
# build init
PROJ_TYPE =		docker
PROJ_MODULES =		git markdown
DOCKER_IMG_NAME =	mimic3
DOCKER_USER =		plandes
DOCKER_UP_DEPS =	mkdirs

# build config
INFO_TARGETS +=		appinfo
ADD_CLEAN_ALL +=	$(DB_PASS_FILE) $(DB_SA_PASS_FILE)
CLEAN_ALL_DEPS +=	wipedb

# build app config
ENV_FILE ?=		.env
DB_DIR ?= 		./db
DATA_ARCH_FILE ?=	mimic-iii-clinical-database-1.4.zip
DATA_DIR ?=		$(abspath ./mimic-data)
CODE_DIR ?=		./mimic-code/mimic-iii/buildmimic/postgres
CODE_PARAMS ?=		DBHOST=localhost DBPORT=$(DB_PORT) DBNAME=$(DB_NAME) \
				DBUSER=$(DB_SA_USER) DBPASS='$(DB_SA_PASS)' \
				DBSCHEMA="public" DATADIR="$(DATA_DIR)/"
DB_PASS_FILE ?=		password.txt
DB_SA_PASS_FILE ?=	sa-password.txt
EXT_DEPS ?=		$(DATA_DIR) $(CODE_DIR)
ARCH_DIR ?=		archive

# postgres config (uses obfuscated port)
DB_PASS ?=		$(shell cat $(DB_PASS_FILE))
DB_SA_USER ?=		postgres
DB_SA_PASS ?=		$(shell cat $(DB_SA_PASS_FILE))

# docker config
DOCKER_UP_DEPS +=	mkenv


## User editable values
#
DB_PORT ?=		19321
DB_IN_PORT ?=		5432
DB_NAME ?= 		mimic3
DB_USER ?= 		mimic3


## Includes
#
include zenbuild/main.mk


## Build targets (called by build system)
#
# print app specific info
.PHONY:			appinfo
appinfo:
			@echo "port: $(DB_PORT)"
			@echo "db: $(DB_NAME)"
			@echo "password: $(DB_PASS)"
			@echo "sa-user: $(DB_SA_USER)"
			@echo "sa-password: $(DB_SA_PASS)"

# (re)create passwords
.PHONY:			genpass
genpass:
			@echo 'generating passwords'
			@for f in $(DB_PASS_FILE) $(DB_SA_PASS_FILE) ; do \
				echo "writing $$f" ; \
				dd if=/dev/urandom count=1 2> /dev/null | \
					uuencode -m - | sed -ne 2p | \
					cut -c-64 > $$f ; \
			done

# make host level directories
.PHONY:			mkdirs
mkdirs:
			mkdir -p $(DB_DIR)

# create the docker compose environment
.PHONY:			mkenv
mkenv:
			@echo "\
DB_NAME=$(DB_NAME)\n\
DB_PORT=$(DB_PORT)\n\
DB_IN_PORT=$(DB_IN_PORT)\n\
DB_USER=$(DB_USER)\n\
DB_PASS=$(DB_PASS)\n\
DB_SA_USER=$(DB_SA_USER)\n\
DB_SA_PASS=$(DB_SA_PASS)\n\
DB_DIR=$(DB_DIR)\
" > $(ENV_FILE)


# uncompress the full MIMIC-III distribution zip archive
$(DATA_DIR):
			@echo "uncompressing $(DATA_DIR) -> $(DATA_ARCH_FILE)"
			@if [ ! -f $(DATA_ARCH_FILE) ] ; then \
				echo "no mimic arch file found: $(DATA_ARCH_FILE)" ; \
				exit 1 ; \
			fi
			unzip $(DATA_ARCH_FILE)
			( cd `echo $(DATA_ARCH_FILE) | sed 's/\.zip$///'` ; \
			  for i in *.gz ; do gunzip $$i ; done )
			mv `echo $(DATA_ARCH_FILE) | sed 's/\.zip$///'` $(DATA_DIR)

# clone the MIMIC-III database parsing code base
$(CODE_DIR):
			@echo "cloning mimic code repository"
			git clone 'https://github.com/MIT-LCP/mimic-code.git'

# delete any previous database installs
.PHONY:			wipedb
wipedb:
			rm -rf $(DB_DIR)

.PHONY:			passfile
passfile:
			@echo "*:$(DB_PORT):$(DB_NAME):$(DB_SA_USER):$(DB_SA_PASS)" > ~/.pgpass
			@echo "*:$(DB_PORT):$(DB_NAME):$(DB_USER):$(DB_PASS)" >> ~/.pgpass
			chmod 0600 ~/.pgpass

# execute ad-hoc SQL
.PHONY:			execute
execute:
			@( PGPASSFILE="$(HOME)/.pgpass" \
			  psql -U $(DB_SA_USER) -d $(DB_NAME) -p $(DB_PORT) \
				-h localhost --no-password -c "$(SQL)" )

# load the database
.PHONY:			load
load:			$(EXT_DEPS)
			( export PGPASSWORD=$(DB_SA_PASS) ; \
			  make -C $(CODE_DIR) create-user mimic $(CODE_PARAMS) )

.PHONY:			init
init:
			@make SQL='create user $(DB_USER);' execute
			@make SQL="alter user $(DB_USER) with password '$(DB_PASS)';" execute
			@make SQL='grant all on schema public to public;' execute
			@make SQL='grant select on all tables in schema public to $(DB_USER);' execute


## User targets
#
# login as db sysadmin
.PHONY:			rootlogin
rootlogin:
			make passfile
			( PGPASSFILE="$(HOME)/.pgpass" \
			  psql -U $(DB_SA_USER) -d $(DB_NAME) -p $(DB_PORT) \
				-h localhost --no-password )

.PHONY:			userlogin
userlogin:
			make passfile
			( PGPASSFILE="$(HOME)/.pgpass" \
			  psql -U $(DB_USER) -d $(DB_NAME) -p $(DB_PORT) \
				-h localhost --no-password )

.PHONY:			archive
archive:
			$(eval base = $(shell basename $(DB_DIR)))
			@echo tar jcf $(base).tar.bz2 $(base)
			mkdir -p $(ARCH_DIR)
			mv $(base).tar.bz2 $(ARCH_DIR)
			cp makefile docker-compose.yml \
				$(DB_PASS_FILE) $(DB_SA_PASS_FILE) $(ARCH_DIR)

# load the database once up
.PHONY:			world
world:
			make down
			make cleanall
			make genpass
			make DB_PORT=5432 up
			sleep 5
			make DB_PORT=5432 load
			make init
			@echo "done installing the MIMIC-III corpus, shutting down..."
			make down
