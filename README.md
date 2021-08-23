# Laminas Continuous Integration GitHub Action

This repository represents a GitHub Action that runs a single PHP QA job, using the [laminas/laminas-continuous-integration image](https://ghcr.io/laminas/laminas-continuous-integration).

A job is presented as an argument to the container, and will be a JSON string representing the job to run.

> **NOTE** that it is a JSON string representation, and not an actual JSON object.

The JSON string should represent an object with the following information:

```json
{
  "php": "string PHP minor version to run against",
  "extensions": [
    "extension names to install; names are from the ondrej PHP repository, minus the php{VERSION}- prefix"
  ],
  "ini": [
    "php.ini directives, one per element; e.g. 'memory_limit=-1'"
  ],
  "dependencies": "dependencies to test against; one of lowest, locked, latest",
  "ignore_platform_reqs_on_8": "(boolean; OPTIONAL; DEPRECATED) Whether or not to ignore platform requirements on PHP 8; defaults to true",
  "ignore_php_platform_requirement": "(boolean; OPTIONAL) Whether or not to ignore PHP platform requirement; defaults to false",
  "command": "command to run to perform the check (empty in case you dont want to excecute any command)"
}
```

The PHP version and command are required; all other elements are optional.

It will then execute the job, and the exit status will determine job failure or success.

Generally speaking, you will use this in combination with the [laminas/laminas-ci-matrix-action](https://github.com/laminas/laminas-ci-matrix-action), which will build a matrix of jobs for you based on configuration files already present in your package.

## Usage

```yaml
jobs:
  matrix:
    name: Generate job matrix
    runs-on: ubuntu-latest
    outputs:
      matrix: ${{ steps.matrix.outputs.matrix }}
    steps:
      - name: Gather CI configuration
        id: matrix
        uses: laminas/laminas-ci-matrix-action@v1

  qa:
    name: QA Checks
    needs: [matrix]
    runs-on: ${{ matrix.operatingSystem }}
    strategy:
      fail-fast: false
      matrix: ${{ fromJSON(needs.matrix.outputs.matrix) }}
    steps:
      - name: ${{ matrix.name }}
        uses: laminas/laminas-continuous-integration-action@v1
        env:
          "GITHUB_TOKEN": ${{ secrets.GITHUB_TOKEN }}
        with:
          job: ${{ matrix.job }}
```

> ### actions/checkout not required
>
> The action will perform a checkout of the repository at the requested reference as part of its work, and therefore does not require the actions/checkout action as a preceding step.

> ### GITHUB_TOKEN not required
>
> While injection of the `GITHUB_TOKEN` env variable is demonstrated above, in most cases it is not necessary.
> Only add it if you start seeing rate limit issues when using Composer (e.g., when you receive a "Could not authenticate against github.com" message when installing dependencies).

### Pre/Post commands

Some packages may require additional setup steps: setting up a web server to test an HTTP client, seeding a database or cache service, etc.
Other times, you may want to do additional reporting, particularly if the QA command failed.

To enable this, you may create one or more of the following files in your package:

- `.laminas-ci/pre-install.sh`
- `.laminas-ci/pre-run.sh`
- `.laminas-ci/post-run.sh`

(Note: the files MUST be executable to be consumed!)

The `.laminas-ci/pre-install.sh` command runs before any other command is executed in the action, and will receive the following arguments:

- `$1`: the user the QA command will run under
- `$2`: the WORKDIR path
- `$3`: the `$JOB` passed to the entrypoint (see above)

The `.laminas-ci/pre-run.sh` command runs immediately prior to the QA command, and will receive the following arguments:

- `$1`: the user the QA command will run under
- `$2`: the WORKDIR path
- `$3`: the `$JOB` passed to the entrypoint (see above)

The `.laminas-ci/post-run.sh` command will receive these arguments:

- `$1`: the exit status of the QA command
- `$2`: the user the QA command will run under
- `$3`: the WORKDIR path
- `$4`: the `$JOB` passed to the entrypoint (see above)

#### Parsing the $JOB

You may want to grab elements of the `$JOB` argument in order to branch logic.
Generally speaking, you can use the [jq](https://stedolan.github.io/jq/) command to get at this data.
As an example, to get the PHP version:

```bash
JOB=$3
PHP_VERSION=$(echo "${JOB}" | jq -r '.php')
```

If you want to conditionally skip setup based on the command (in this case, exiting early if the command to run is not phpunit):

```bash
JOB=$3
COMMAND=$(echo "${JOB}" | jq -r '.command')
if [[ ! ${COMMAND} =~ phpunit ]];then
    exit 0
fi
```

Perhaps after running a job against locked dependencies, you want to see if newer versions are available:

```bash
JOB=$3
DEPS=$(echo "${JOB}" | jq -r '.dependencies')
if [[ "${DEPS}" != "locked" ]];then
    exit 0
fi
# check for newer versions...
```

If you need access to the list of extensions or php.ini directives, you should likely write a script in PHP or node to do so.

#### Using PECL

One key reason to use a `.laminas-ci/pre-install.sh` script is to install an extension via PECL.
You may need to do this if no corresponding package exists for an extension you need, or if you need to test against a different version than is in the Sury repository.

An example of such a script:

```bash
#!/bin/bsh
# .laminas-ci/pre-install.sh

pecl install couchbase-2.6.2
```

### Using locally

The [standard Laminas Continuous Integration workflow](https://gist.github.com/weierophinney/9decd19f76b7d9745c6559074053fa65) defines one job using the laminas/laminas-ci-matrix-action to create the matrix, and defines another job to run the various jobs in the matrix that consumes it.
Unfortunately, as of this writing, tools like [nektos/act](https://github.com/nektos/act) are unable to work with job/step dependencies, nor with workflow metadata expressions, meaning you cannot run the full suite at once.

What you _can_ do, however, is run individual jobs via the [laminas/laminas-continuous-integration container](https://ghcr.io/laminas/laminas-continuous-integration).

It defines an entrypoint that accepts a single argument, a JSON string. The JSON string should contain the following elements:

- command: (string; required) the command to run (e.g., `./vendor/bin/phpunit`)
- php: (string; required) the PHP version to use when running the check
- extensions: (array of strings; optional) additional extensions to install.
  The names used should correspond to package names from the Sury repository, minus the `php{version}-` prefix.
  As examples, "sqlite3" or "tidy".
- ini: (array of strings; optional) php.ini directives to use.
  Each item should be the full directive; e.g., `memory_limit=-1` or `date.timezone=America/New_York`.
- dependencies: (string; optional) the dependency set to run against: lowest, locked, or latest.
  If not provided, "locked" is used.

To run a test locally, first, pull the container:

```bash
$ docker pull ghcr.io/laminas/laminas-continuous-integration:1
```

Once you have pulled it, you can run individual jobs.
The tricks to remember are:

- You need to set bind the package directory as a volume.
- You need to set the container WORKDIR to that volume.
- You need to provide the job JSON.

As an example, if you wanted to run the CS checks under PHP 7.4 using locked dependencies, you could do something like the following:

```bash
$ docker run -v $(realpath .):/github/workspace -w=/github/workspace laminas-check-runner:latest '{"php":"7.4","dependencies":"locked","extensions":[],"ini":["memory_limit=-1"],"command":"./vendor/bin/phpcs"}'
```

The trick to remember: the job JSON should generally be in single quotes, to allow the `"` characters used to delimit properties and strings in the JSON to not cause interpolation issues.

## PHP versions, extensions, and tools available

The container the action provides and consumes builds off the ubuntu:focal image, installs the [Sury PHP repository](https://deb.sury.org/), and installs PHP versions:

- 5.6
- 7.0
- 7.1
- 7.2
- 7.3
- 7.4
- 8.0

Each provides the following extensions by default:

- bz2
- curl
- fileinfo
- intl
- json
- mbstring
- phar
- readline
- sockets
- xml
- xsl
- zip

You may specify other extensions to install during a job by selecting them from the list of packages in the Sury repository, and dropping the `php{VERSION}` prefix; e.g., the package "php7.4-tidy" provides the "tidy" extension, so you would only specify "tidy" if you want to include that extension for your build.

We also provide the following extensions:

- sqlsrv (version 5.9.0)
- pdo_sqlsrv (version 5.9.0)

Other extensions may be installed using pecl, or directly retrieving the extension package, and doing the `phpize`/`configure`/`make` dance; this can be done in a [pre-run command script](#pre-post-commands).

### Other tools available

The container provides the following tools:

- Composer (v2 release)

- [cs2pr](https://github.com/staabm/annotate-pull-request-from-checkstyle), which creates PR annotations from checkstyle output. If a tool you are using, such as `phpcs`, provides checkstyle output, you can pipe it to `cs2pr` to create PR annotations from errors/warnings/etc. raised.

- A `markdownlint` binary, via the [DavidAnson/markdownlint-cli2](https://github.com/DavidAnson/markdownlint-cli2) package.
  A default configuration is provided that disables the following rules:

  - MD013 (line-length)
  - MD014 (dollar signs used before commands without showing output)
  - MD024 (duplicate header)
  - MD028 (blank line inside block quote)
  - MD034 (bare URLs)

  Consumers can provide their own rules via a [.markdownlint.json](https://github.com/DavidAnson/markdownlint-cli2#markdownlintjsonc-or-markdownlintjson) file.

- A `xmllint` binary, via the [libxml2-utils](https://packages.debian.org/stretch/libxml2-utils) package.

- A `yamllint` binary, via the [adrienverge/yamllint](https://github.com/adrienverge/yamllint) package.

- The [jq](https://stedolan.github.io/jq/) command, a CLI JSON processor.

## Notes on contributing

This package includes a workflow that will build the container during pull request, to verify that builds complete successfully.

The workflow has three different conditional build steps:

- One that happens only on release; this is irrelevant to pull requests.
- Two that happen for pull requests:
  - One that triggers if the repository's `CONTAINER_USERNAME` (and, by extension, `CONTAINER_PAT`) secret is present.
  - One that triggers if the repository's `CONTAINER_USERNAME` (and, by extension, `CONTAINER_PAT`) secret is NOT present.

In the case where the repository secrets are present, the build will also cache layers it has built, which will speed up later builds.
However, because repository secrets are not provided when a pull request is performed from a forked repository, the second case will kick in; in that scenario, the build will still run, but no layers will be pushed to the container registry.

As such, if you are a Laminas Technical Steering Committee member or a maintainer with write access to this repository, please submit your patches via branches pushed directly to the repository, as this will speed up builds for everyone.
