{ inputs, cell }:

let
  src = inputs.nixpkgs.lib.sourceFilesBySuffices
    (cell.library.gitignore-source inputs.self)
    [ ".cabal" ];
in

inputs.nixpkgs.runCommand "cabal-fmt-checker"
{
  buildInputs = [
    cell.packages.fix-cabal-fmt
    inputs.nixpkgs.diffutils
    inputs.nixpkgs.glibcLocales
  ];
} ''
  set +e
  cp -a ${src} orig
  cp -a ${src} cabal
  chmod -R +w cabal
  cd cabal
  fix-cabal-fmt
  cd ..
  diff --brief --recursive orig cabal > /dev/null
  EXIT_CODE=$?
  if [[ $EXIT_CODE != 0 ]]
  then
    mkdir -p $out/nix-support
    diff -ur orig cabal > $out/cabal.diff
    echo "file none $out/cabal.diff" > $out/nix-support/hydra-build-products
    echo "*** cabal-fmt found changes that need addressed first"
    echo "*** Please run \`fix-cabal-fmt\` and commit changes"
    echo "*** or apply the diff generated by hydra if you don't have nix."
    exit $EXIT_CODE
  else
    echo $EXIT_CODE > $out
  fi
''