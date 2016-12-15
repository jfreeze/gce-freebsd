#!/bin/sh

usage ()
{
  echo "Usage : $(basename "$0") project-name"
  echo "Updates rel/config.exs with a Distillery plugin module to populate priv/ for deployments."
  exit
}

if [ "$#" -ne 1 ]; then
  usage
fi

run () {

    CMD=$(cat <<EOF
defmodule ${1}.PhoenixDigestTask do
  use Mix.Releases.Plugin

  def before_assembly(%Release{} = _release) do
    info "before assembly!"
    # NOTE: If your app has brunch, you can enable this code.
    case System.cmd("npm", ["install"]) do
      {output, 0} ->
        case System.cmd("npm", ["run", "deploy"]) do
          {output, 0} ->
            info output
            Mix.Task.run("phoenix.digest")
            nil
          {output, error_code} ->
            {:error, output, error_code}
        end
      {output, error_code} ->
         {:erro, output, error_code}
    end
  end

  def after_assembly(%Release{} = _release) do
    info "after assembly!"
    nil
  end

  def before_package(%Release{} = _release) do
    info "before package!"
    nil
  end

  def after_package(%Release{} = _release) do
    info "after package!"
    nil
  end

  def after_cleanup(%Release{} = _release) do
    info "after cleanup!"
    nil
  end
end

EOF
)

    echo "Generating plugin.."
    mkdir -p rel/plugins
    echo "${CMD}" > rel/plugins/digest_plugin.exs

    echo "Updating rel/config.exs.."

    PREV_CONFIG=$(cat rel/config.exs)
    CONFIG=$(cat <<EOF
Code.eval_file(Path.join([__DIR__, "plugins", "digest_plugin.exs"]))

${PREV_CONFIG}
EOF
)
  
    echo "${CONFIG}" > rel/config.exs

    echo "Done!"
}

run $1
