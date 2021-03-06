# Node.js Cloud Native Buildpack

Cloud Native Buildpacks are buildpacks that turn source code into OCI images. They follow a 4-step process (detect, analyze, build, and export) that outputs an image. The spec can be read about in detail [here](https://github.com/buildpack/spec/blob/master/buildpack.md).

## Usage

### Install pack

Using `brew` (assuming development is done on MacOS), install `pack`.

```sh
brew tap buildpack/tap
brew install pack
```

If you're using Windows or Linux, follow instructions [here](https://buildpacks.io/docs/install-pack/).

### Install shpec

This buildpack uses `shpec` for unit tests, so to run them locally, you'll need to install the package.

```sh
curl -sLo- http://get.bpkg.sh | bash
bpkg install rylnd/shpec
```

### Clone the buildpack

Right now, we are prototyping with a local version of the buildpack. Clone it to your machine.

```sh
git clone git@github.com:heroku/nodejs-engine-buildpack.git
```

### Build the image

Using pack, you're ready to create an image from the buildpack and source code. You will need to add flags that point to the path of the buildpack (`--buildpack`) and the path of the source code (`--path`).

```sh
cd nodejs-engine-buildpack
pack build TEST_IMAGE_NAME --buildpack ../nodejs-engine-buildpack --path ../TEST_REPO_PATH
```

### Local development

The buildpack uses a Golang binary to parse the engine versions from the `package.json`. It's better to create the binaries once locally, so they don't have to be downloaded and rebuilt with every build.

```
make build
```

This builds the binaries specific for the Docker image. The binaries are in the `.gitignore`, so they won't be committed or ever exist in the remote source code.

If you need them for a MacOS, run:

```
make build-local
```

## Testing

Make sure `shpec` is installed. Then, the test script can be run.

```sh
make test
```

If you want to run individual test suites, that's available too.

**Unit Tests**

```sh
make unit-test
```

**Binary Tests**

```sh
make binary-tests
```

## Glossary

- buildpacks: provide framework and a runtime for source code. Read more [here](https://buildpacks.io).
- OCI image: [OCI (Open Container Initiative)](https://www.opencontainers.org/) is a project to create open sourced standards for OS-level virtualization, most importantly in Linux containers.
