#!/usr/bin/env zsh

source $HOME/.zshrc

# Strip code signatures to make this work on macOS 10.14
pushd macos
  unzip wildmagic-macos.zip
	codesign --remove-signature --deep wildmagic.app
	zip -q -r -y ./wildmagic-macos.zip ./wildmagic.app
	rm -r wildmagic.app
popd

for channel in *; do
  fname="wildmagic-${channel}.zip"

  if [[ "$channel" == "love" ]]; then
    fname="wildmagic.love"
  fi
  butler push ${channel}/${fname} jiaaro/wildmagic:${channel}
done
