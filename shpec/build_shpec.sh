set -e
set -o pipefail

source "./lib/utils/json.sh"
source "./lib/utils/toml.sh"
source "./lib/build.sh"

bootstrap_buildpack() {
  if [[ ! -f $bp_dir/bin/resolve-version ]]; then
    bash -- "$bp_dir/bin/bootstrap" "$bp_dir"
  fi
}

create_temp_layer_dir() {
  mktemp -d -t build_shpec_XXXXX
}

create_temp_project_dir() {
  mktemp -u -t project_shpec_XXXXX
}

create_temp_package_json() {
  mkdir -p "tmp"
  cp "./fixtures/package-patch-versions.json" "tmp/package.json"
}

rm_temp_dirs() {
  rm -rf $1
  rm -rf "tmp"
}

create_binaries() {
  stub_command "echo"
  bootstrap_buildpack
  # unstub_command "echo"
}

rm_binaries() {
  rm -f $bp_dir/bin/resolve-version
}

describe "lib/build.sh"
  rm_binaries
  create_binaries

  export PATH=$bp_dir/bin:$PATH

  describe "install_or_reuse_toolbox"
    layers_dir=$(create_temp_layer_dir)
    project_dir=$(create_temp_project_dir)

    export PATH=$layers_dir/toolbox/bin:$PATH

    it "creates a toolbox layer"
      install_or_reuse_toolbox "$layers_dir/toolbox"

      assert file_present "$layers_dir/toolbox/bin/jq"
      assert file_present "$layers_dir/toolbox/bin/yj"
    end

    it "creates a toolbox.toml"
      install_or_reuse_toolbox "$layers_dir/toolbox"

      assert file_present "$layers_dir/toolbox.toml"
    end
  end

  describe "install_or_reuse_node"
    layers_dir=$(create_temp_layer_dir)

    it "creates a node layer when it does not exist"
      assert file_absent "$layers_dir/nodejs/bin/node"
      assert file_absent "$layers_dir/nodejs/bin/npm"

      install_or_reuse_node "$layers_dir/nodejs" $project_dir

      assert file_present "$layers_dir/nodejs/bin/node"
      assert file_present "$layers_dir/nodejs/bin/npm"
    end

    it "reuses node layer when versions match"
      # TODO: set up fixtures for version matching
    end
  end

  describe "parse_package_json_engines"
    layers_dir=$(create_temp_layer_dir)

    echo -e "[metadata]\n" > "${layers_dir}/package_manager_metadata.toml"
    create_temp_package_json

    parse_package_json_engines "$layers_dir/package_manager_metadata" "tmp"

    it "writes npm version to layers/node.toml"
      local npm_version=$(toml_get_key_from_metadata "$layers_dir/package_manager_metadata.toml" "npm_version")

      assert equal "6.9.1" "$npm_version"
    end

    it "writes yarn_version to layers/node.toml"
      local yarn_version=$(toml_get_key_from_metadata "$layers_dir/package_manager_metadata.toml" "yarn_version")

      assert equal "1.19.1" "$yarn_version"
    end

    rm_temp_dirs "$layers_dir"
  end

  describe "install_or_reuse_yarn"
    layers_dir=$(create_temp_layer_dir)

    it "creates a yarn layer when it does not exist"
      assert file_absent "$layers_dir/yarn/bin/yarn"

      install_or_reuse_yarn "$layers_dir/yarn" "$project_dir"

      assert file_present "$layers_dir/yarn/bin/yarn"
    end

    it "reuses yarn layer when versions match"
      # TODO: set up fixtures for version matching
    end

    rm_temp_dirs "$layers_dir"
  end

  describe "write_launch_toml"
    layers_dir=$(create_temp_layer_dir)

    mkdir -p "tmp"
    touch "tmp/server.js" "tmp/index.js"

    it "creates a launch.toml file when there is index.js and server.js"
      assert file_absent "$layers_dir/launch.toml"

      write_launch_toml "tmp" "$layers_dir/launch.toml"

      assert file_present "$layers_dir/launch.toml"

      rm "$layers_dir/launch.toml"
    end

    it "creates a launch.toml file when there is server.js and no index.js"
      rm "tmp/index.js"

      assert file_absent "$layers_dir/launch.toml"

      write_launch_toml "tmp" "$layers_dir/launch.toml"

      assert file_present "$layers_dir/launch.toml"

      rm "$layers_dir/launch.toml"
    end

    it "does not create launch.toml when no js initialize files"
      rm "tmp/server.js"
      
      assert file_absent "$layers_dir/launch.toml"

      write_launch_toml "tmp" "$layers_dir/launch.toml"

      assert file_absent "$layers_dir/launch.toml"
    end

    rm_temp_dirs "$layers_dir"
  end

  rm_binaries
end
