# Pi extension definitions. `package.json` is generated from this file at build
# time; regenerate `package-lock.json` with `just update-pi-extensions` after
# changing an entry.
{
  name = "home-manager-pi-extensions";
  version = "1.0.0";

  # Registry version ranges, or fixed GitHub archives. Bumping a GitHub pin
  # requires a new `rev`, its `hash`, and a lockfile update.
  deps = {
    pi-cliproxyapi-provider = {
      owner = "monadix";
      repo = "pi-cliproxyapi-provider";
      rev = "4dac57b4fd013c5b39b2f5db75a0998ec94bbc69";
      hash = "sha256-ANB/Ey8trcOOrPQNFHEZCujuE1+ahpKp4hJCDCZFals=";
    };
    pi-subagents = "latest";
    pi-universal-usage = {
      owner = "monadix";
      repo = "pi-universal-usage";
      rev = "61df39c57fe429afdbf2fe21565d93ad230309ee";
      hash = "sha256-yvmP7quqELBW7DiUteHVrPdwSZrJxNIm7f6zZWNYxsM=";
    };
    pi-vim = "latest";
    pi-web-access = "latest";
  };
}
