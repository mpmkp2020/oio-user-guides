#!/usr/bin/env bats

TEST_FILE=/tmp/test.txt
BUCKET_NAME=quickstart-bucket
OIO_NAMESPACE=OPENIO

# This function is called for EACH test
setup() {
    cd "${BATS_TEST_DIRNAME}/../" || (echo "ERROR: cannot change directory to ${BATS_TEST_DIRNAME}. Exiting." && exit 1)
    # shellcheck disable=SC1091
    source ./.env
}

@test "We can start the docker-compose stack of this story" {
    file /usr/local/bin/docker-compose
    uname -m
    docker-compose up -d --build --force-recreate
}

@test "OpenIO is started successfully" {
    local counter=0
    local max_retries=60
    local wait_time=5
    until [ "${counter}" -ge "${max_retries}" ]
    do
        echo "== Trial ${counter} for openio-server logs check"
        if [ "10" -eq "$(docker-compose logs openio-server 2>&1 | grep -c 'is now up')" ]
        then
            break
        fi
        sleep "${wait_time}"
        counter=$((counter + 1))
    done
    echo "== Final counter: ${counter}"
    [ ${counter} -lt ${max_retries} ]
    
    docker-compose exec openio-server openio cluster list --ns="${OIO_NAMESPACE}"
}

@test "We can store a file with OpenIO client" {
    docker-compose exec openio-client bash -c "echo 'Hello OIO' > ${TEST_FILE}"
    docker-compose exec openio-client openio object create MY_OIO_CONTAINER "${TEST_FILE}" --oio-account MY_ACCOUNT --ns="${OIO_NAMESPACE}" --oio-proxy="${OIO_URL}:6006"
}

@test "We can store a file with AWS S3" {
    docker-compose exec aws-client bash -c "echo 'Hello S3' > ${TEST_FILE}"
    docker-compose exec aws-client aws --endpoint-url="https://${S3_URL}:6007" s3 mb "s3://${BUCKET_NAME}"
    docker-compose exec aws-client aws --endpoint-url="https://${S3_URL}:6007" s3 cp "${TEST_FILE}" "s3://${BUCKET_NAME}/$(basename ${TEST_FILE})"
}

@test "We can stop gracefully the docker-compose example" {
    docker-compose down -v --remove-orphans
}
