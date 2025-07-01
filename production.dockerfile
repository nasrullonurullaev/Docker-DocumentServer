### Arguments avavlivable only for FROM instruction ### 
ARG PULL_TAG=9.0.3.6
ARG COMPANY_NAME=nasrullonurullaev5
ARG PRODUCT_EDITION=
### Rebuild arguments
ARG UCS_PREFIX=
ARG IMAGE=${COMPANY_NAME}/documentserver${PRODUCT_EDITION}${UCS_PREFIX}:${PULL_TAG}

### Build main-release ###

FROM ${COMPANY_NAME}/4testing-documentserver${PRODUCT_EDITION}:${PULL_TAG} as documentserver-stable


