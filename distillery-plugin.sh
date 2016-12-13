#!/bin/sh

usage ()
{
  echo "Usage : $(basename "$0") project-name"
  echo "Adds a plugin module to populate priv/ for deployments."
  exit
}

if [ "$#" -ne 1 ]
then
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

  echo "${CMD}
  
  $(cat rel/config.exs)" > rel/config.exs
}

run $1
