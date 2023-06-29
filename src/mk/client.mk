# (@)Id: MIMIC-III database Docker image


## Environment
#
# build config
DOCKER_UP_DEPS +=	mimicdbprep mimicdbmkconf
ADD_CLEAN +=		$(MIMICDB_ENV_FILE)

# mimicdb
MIMICDB_DIR ?=		$(abspath $(word 2,$(MAKEFILE_LIST))/../../..)
MIMICDB_ENV_FILE ?=	$(abspath .env)

MIMICDB_CONF_FILE=	$(APP_MOUNT_DIR)/db.conf


## Targets
#
.PHONY:			mimicdbmkenv
mimicdbmkenv:
			@echo "creating $(MIMICDB_DIR) -> $(MIMICDB_ENV_FILE)"
			$(eval dir=$(subst /,\/,$(MIMICDB_DIR)))
			@echo $(dir)
			make -C $(MIMICDB_DIR) ENV_FILE=$(MIMICDB_ENV_FILE) mkenv
			sed -i 's/^DB_DIR=\(.\/\)*\(.*\)/DB_DIR=$(dir)\/\2/g' $(MIMICDB_ENV_FILE)
			@echo "wrote $(MIMICDB_ENV_FILE)"

.PHONY:			mimicdbmkconf
mimicdbmkconf:
			@echo "creating $(MIMICDB_CONF_FILE)"
			$(eval include $(MIMICDB_ENV_FILE))
			@echo "\
[mimic_db]\n\
host = mimicdb\n\
name = mimic3\n\
database = $(DB_NAME)\n\
password = $(DB_PASS)\n\
port = $(DB_IN_PORT)\n\
user = $(DB_USER)\
" > $(MIMICDB_CONF_FILE)
			@echo "wrote: $(MIMICDB_CONF_FILE)"

.PHONY:			mimicdbprep
mimicdbprep:		mimicdbmkenv mimicdbmkconf
