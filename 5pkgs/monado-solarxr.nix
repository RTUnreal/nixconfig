{
  monado,
  src,
}:

monado.overrideAttrs (
  finalAttrs: prevAttrs: {
    pname = "monado-solarxr";
    version = src.rev;

    inherit src;
    patches = builtins.filter (
      patch: patch.name != "monado-cylinder-aspectRatio.patch"
    ) prevAttrs.patches or [ ];

  }
)
