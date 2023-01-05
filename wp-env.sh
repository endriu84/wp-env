#!/usr/bin/env bash

# Exit on (non catched) error 
set -e

# debuging
# set -x

cmd=wp-env
# wp_env_dir=~/wp-env
env_file=".wp-env.json"

project_dir=${PWD}
project_name=${PWD##*/}
parent_dir=$(dirname "$project_dir")

script_dir=$(dirname "$0")

# wp_folder=${project_name}
wp_folder="core"
# wp_abspath=${wp_env_dir}/${wp_folder}
wp_abspath=${parent_dir}/${wp_folder}

compose_tpl_file="${script_dir}/.wp-env.sh/docker-compose.yml"
dockerfile_tpl="${script_dir}/.wp-env.sh/Dockerfile"
compose_file="${parent_dir}/docker-compose.yml"
app_container="docker exec --user=www-data ${project_name}_www"
# wp_cli="docker-compose -f ${compose_file} run --rm ${project_name}_wpcli wp"
wp_cli="/home/andrzej/.config/composer/vendor/bin/wp --path=${wp_abspath}"

if [ ! -r "${project_dir}/${env_file}" ]; then
    echo "Couldn't find ${env_file} file. Aborting."
    exit 1
fi

# check if "jq" is installed
command -v jq >/dev/null 2>&1 || { echo >&2 "jq it's not installed. Aborting."; exit 1; }

# -p - if not exists
mkdir -p "${wp_abspath}"

create_compose_file() {
    
    port=$(jq -r '.port' ${env_file})
    if [ "${port}" = "null" ]; then
        port=9090
    fi
    # plugin version
    # sed -e "s/%PROJECT_NAME%/${project_name}/g" -e "s|%WP_ABSPATH%|${wp_abspath}|g" -e "s/%PORT%/${port}/" -e "s|%VOLUME%|${project_dir}/${project_name}/:/var/www/html/wp-content/plugins/${project_name}|g" "${compose_tpl_file}" > "${compose_file}"
    # theme version
    sed -e "s/%PROJECT_NAME%/${project_name}/g" -e "s|%WP_ABSPATH%|${wp_abspath}|g" -e "s/%PORT%/${port}/" -e "s|%VOLUME%|${parent_dir}/${project_name}/:/var/www/html/wp-content/themes/${project_name}|g" "${compose_tpl_file}" > "${compose_file}"

    cp "${dockerfile_tpl}" "${parent_dir}/Dockerfile"
}

compose_up() {

    container_id=$(docker ps -q -f name="${project_name}"_www)

    if [ -z "${container_id}" ]; then

        docker-compose -f "${compose_file}" up -d --build > /dev/null 2>&1
        docker exec -ti "${project_name}"_www chown -R 1000:1000 /var/www/html
    fi
}

compose_down() {

    container_id=$(docker ps -qa -f name="${project_name}"_www)

    if [ ! -z "${container_id}" ]; then

        docker-compose -f "${compose_file}" down
    fi
}

install_core() {

#  ${local_wpcli} --path=${wp_abspath} db create --quiet || true > /dev/null
    ${wp_cli} db create --quiet || true > /dev/null
    ${wp_cli} core install --url="localhost:${port}" --title="${project_name}" --admin_user=admin --admin_password=password --admin_email=admin@email.com --skip-email
}

install_plugins() {

    plugins=$(jq -r '.plugins | .[]?' ${project_dir}/${env_file})
    # printf "%s\n" "${plugins[@]}"
    if [ "${plugins}" != "" ]; then
        for plugin in "${plugins[@]}"; do
            ${wp_cli} plugin install "${plugin}" --activate --force
        done
    fi
}

install_themes() {

    themes=$(jq -r '.themes | .[]?' ${project_dir}/${env_file})
    if [ "${themes}" != "" ]; then
        first_run=1
        for theme in "${themes[@]}"; do
            if [ "${first_run}" == 1 ]; then
                ${wp_cli} theme install "${theme}" --activate --force
                
                # below would not activate local theme becouse it is called from outside of the container, thous theme folder is empty
                # ${wp_cli} theme activate "${theme}" 
                first_run=0
            else
                ${wp_cli} theme install "${theme}" --force
            fi
        done
    fi
}

setup_config() {

    # config_keys=$(jq -r '.config | keys | .[]' ${env_file})
    # printf "%s\n" "${config_keys[@]}"
    # $wp_cli config create --dbname=testing --dbuser=wp --dbpass=securepswd --locale=en_EN || true
    cp "${wp_abspath}/wp-config-sample.php" "${wp_abspath}/wp-config.php"
    $wp_cli config shuffle-salts
    for key in $(jq -r '.config | keys | .[]' ${project_dir}/${env_file}); do
        value="$(jq -r ".config | .${key}" ${project_dir}/${env_file})"
        if [ "${value}" = "true" ] || [ "${value}" = "false" ]; then
            $wp_cli config set "${key}" "${value}" --add --raw
        else
            $wp_cli config set "${key}" "${value}" --add
        fi
        # export "${key}=${value}"
        # ${app_container} export "${key}=${value}"
        # echo "${key}=${value}" >> "${wp_abspath}/env_FILE"
    done
}

udpate_core() {

    version=$(jq -r '.core' ${project_dir}/${env_file})
    current_version=$(${wp_cli} core version)

    if [ -z "${version}" ]; then
        return
    fi

    if [ "${version}" != "${current_version}" ]; then
        ${wp_cli} core update --version="${version}" --force
    fi
}

rm_files() {

    ${wp_cli} db drop --yes
    rm -rf "${wp_abspath}"
}

maybe_update() {

    org_file="${project_dir}/${env_file}"
    file_copy="${wp_abspath}/${env_file}"

    if [ ! -r "${file_copy}" ]; then
        cp "$org_file" "$file_copy"
    elif cmp -s "${org_file}" "${file_copy}" ; then
        return
    fi

    setup_config
    install_core
    install_plugins
    install_themes
    udpate_core
}

help() {
    echo "wordpress docker envirnoment for plugin and theme development

usage: $cmd [COMMAND]

commands:
  start     - start the wordpress Docker enviroment
  stop      - enter the testing shell
  clean     - update these Docker scripts
  --help    - show this help
  "
}

case "${1:-}" in
    -h|--help)
        help
        exit
    ;;
    "")
        >&2 help
        exit
    ;;
    start)
        create_compose_file
        compose_up
        sleep 3
        maybe_update
    ;;
    stop)
        compose_down
    ;;
    clean)
        compose_down
        rm_files
    ;;
    wp)
        ${wp_cli} "${2}"
    ;;
    *)
        >&2 echo "Bad command ${1:-}"
        exit 1
    ;;
esac