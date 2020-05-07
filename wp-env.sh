#!/usr/bin/env bash

# Exit on (non catched) error 
set -e

cmd=wp-env
wp_env_dir=~/wp-env

project_dir=${PWD}
project_name=${PWD##*/}

script_dir=$(dirname "$0")

wp_folder=${project_name}
wp_abspath=${wp_env_dir}/${wp_folder}

compose_tpl_file="${script_dir}/.wp-env.sh/docker-compose.yml"
compose_file="${wp_abspath}/docker-compose.yml"
toolbox="docker-compose -f ${compose_file} run --rm ${project_name}_wpcli wp"

if [ ! -r "${project_dir}/wp-env.json" ]; then
    echo "Couldn't find wp-env.json file. Aborting."
    exit 1
fi

# check if "jq" is installed
command -v jq >/dev/null 2>&1 || { echo >&2 "jq it's not installed. Aborting."; exit 1; }

# -p - if not exists
mkdir -p ${wp_abspath}

create_compose_file() {
    
    port=$(jq -r '.port' wp-env.json)
    if [ "${port}" = "null" ]; then
        port=9090
    fi
    # plugin version
    sed -e "s/%PROJECT_NAME%/${project_name}/g" -e "s|%WP_ENV_DIR%|${wp_env_dir}|g" -e "s/%PORT%/${port}/" -e "s|%VOLUME%|${project_dir}/:/var/www/html/wp-content/plugins/${project_name}|g" "${compose_tpl_file}" > "${compose_file}"
}

compose_up() {

    container_id="$(docker ps -q -f name=${project_name}_www)"

    if [ -z "$container_id" ]; then

        docker-compose -f ${compose_file} up -d --build
        docker exec -ti ${project_name}_www chown -R 1000:1000 /var/www/html
    fi
}

compose_down() {

    container_id="$(docker ps -qa -f name=${project_name}_www)"

    if [ ! -z "$container_id" ]; then

        docker-compose -f ${compose_file} down
    fi
}

install_plugins() {

    plugins=$(jq -r '.plugins | .[]' wp-env.json)
    # printf "%s\n" "${plugins[@]}"
    if [ "${plugins}" != "null" ]; then
        for plugin in ${plugins[@]}; do

            ${toolbox} plugin install ${plugin} --activate --force
        done
    fi
}

install_themes() {

    themes=$(jq -r '.themes | .[]' wp-env.json)
    if [ "${themes}" != "null" ]; then
        first_run=1
        for theme in ${themes[@]}; do
            if [ "${first_run}" == 1 ]; then
                ${toolbox} theme install ${theme} --activate --force
                first_run=0
            else
                ${toolbox} theme install ${theme} --force
            fi
        done
    fi
}

setup_config() {

    config_keys=$(jq -r '.config | keys | .[]' wp-env.json)
    # printf "%s\n" "${config[@]}"
    for key in ${config_keys[@]}; do
        value=$(jq -r ".config | .${key}" wp-env.json)
        if [ "${value}" = "true" ] || [ "${value}" = "false" ]; then
            $toolbox config set ${key} ${value} --add --raw
        else
            $toolbox config set ${key} ${value} --add
        fi
    done
}

udpate_core() {

    version=$(jq -r '.core' wp-env.json)
    current_version=$(${toolbox} core version)

    if [ "${version}" != "${current_version}" ]; then
        ${toolbox} core update --version=${version} --force
    fi
}

rm_files() {

    rm -rf ${wp_abspath}
}

maybe_update() {

    org_file="${project_dir}/wp-env.json"
    file_copy="${wp_abspath}/wp-env.json"

    if [ ! -r "${file_copy}" ]; then
        cp $org_file $file_copy
    elif cmp -s "${org_file}" "${file_copy}" ; then
        return
    fi

    setup_config
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
        maybe_update
    ;;
    stop)
        compose_down
    ;;
    clean)
        compose_down
        rm_files
    ;;
    *)
        >&2 echo "Bad command ${1:-}"
        exit 1
    ;;
esac