{
  fetchzip,
  freshrss,
  runCommand,
}:
let
  lucide = fetchzip {
    url = "https://registry.npmjs.org/lucide-static/-/lucide-static-1.53.0.tgz";
    hash = "sha256-yISCH4CQWjb2S98EB8lpflYDCFVhxke3m2zQsRURMY4=";
  };
in
runCommand "freshrss-theme-catppuccin" { } ''
  mkdir -p $out/icons

  awk '/^@media screen and \(prefers-color-scheme: dark\)/ { exit } { print }' \
    ${freshrss}/p/themes/Origine/origine.css > $out/origine.css
  cp ${./catppuccin.css} $out/catppuccin.css
  cp ${./metadata.json} $out/metadata.json
  cp $out/origine.css $out/origine.rtl.css
  cp $out/catppuccin.css $out/catppuccin.rtl.css

  while read -r name icon; do
    sed -e '/^<!--/d' \
      -e 's/stroke="currentColor"/stroke="#8c92ac"/' \
      -e 's/stroke-width="2"/stroke-width="1.75"/' \
      ${lucide}/icons/$icon.svg > $out/icons/$name.svg
  done < ${./icons.txt}

  sed -i -e 's/stroke="#8c92ac"/stroke="#e5a50a"/' -e 's/fill="none"/fill="#f5c542"/' \
    $out/icons/starred.svg
''
