# WP-ENV

This is simple bash version of the wp-env nodejs package for gutenberg https://github.com/WordPress/gutenberg/tree/master/packages/env

## Install script globally
```
git clone https://github.com/endriu84/wp-env.git
chmod +x wp-env/wp-env.sh
cp wp-env.sh /usr/local/bin/wp-env
cp .wp-env.sh /usr/local/bin/
```

## How to use

Inside Your plugin folder, You have to create wp-env.json file ( same file as in @wordpress/env package - spec below )

Next run

```
wp-env start
wp-env stop
wp-env clean
```
## .wp-env.json 
[ from https://github.com/WordPress/gutenberg/tree/master/packages/env ]

You can customize the WordPress installation, plugins and themes that the development environment will use by specifying a `.wp-env.json` file in the directory that you run `wp-env` from.

`.wp-env.json` supports five fields:

| Field         | Type          | Default                                    | Description                                                                                                               |
| ------------- | ------------- | ------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------- |
| `"core"`      | `string\|null` | `null`                                     | The WordPress installation to use. If `null` is specified, `wp-env` will use the latest production release of WordPress.  |
| `"plugins"`   | `string[]`    | `[]`                                       | A list of plugins to install and activate in the environment.                                                             |
| `"themes"`    | `string[]`    | `[]`                                       | A list of themes to install in the environment. The first theme in the list will be activated.                            |
| `"port"`      | `integer`      | `8888`                                   | The primary port number to use for the insallation. You'll access the instance through the port: 'http://localhost:8888'. |
| `"config"`    | `Object`      | `"{ WP_DEBUG: true, SCRIPT_DEBUG: true }"` | Mapping of wp-config.php constants to their desired values.                                                               |

_Note: the port number environment variables (`WP_ENV_PORT` and `WP_ENV_TESTS_PORT`) take precedent over the .wp-env.json values._

Several types of strings can be passed into the `core`, `plugins`, and `themes` fields:

| Type              | Format                        | Example(s)                                               |
| ----------------- | ----------------------------- | -------------------------------------------------------- |
| Relative path     | `.<path>\|~<path>`             | `"./a/directory"`, `"../a/directory"`, `"~/a/directory"` |
| Absolute path     | `/<path>\|<letter>:\<path>`    | `"/a/directory"`, `"C:\\a\\directory"`                   |
| GitHub repository | `<owner>/<repo>[#<ref>]`      | `"WordPress/WordPress"`, `"WordPress/gutenberg#master"`  |
| ZIP File          | `http[s]://<host>/<path>.zip` | `"https://wordpress.org/wordpress-5.4-beta2.zip"`        |

Remote sources will be downloaded into a temporary directory located in `~/wp-env`.



## Avalilable commands
```
usage: wp-env [COMMAND]

commands:
  start     - start the wordpress Docker enviroment
  stop      - enter the testing shell
  clean     - update these Docker scripts
  --help    - show this help

```