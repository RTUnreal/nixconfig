{ fetchurl }:
let
  version = "0.4.3";
in
fetchurl {
  url = "https://github.com/jagrosh/MusicBot/releases/download/${version}/JMusicBot-${version}.jar";
  sha256 = "sha256-7CHFc94Fe6ip7RY+XJR9gWpZPKM5JY7utHp8C3paU9s=";
}
