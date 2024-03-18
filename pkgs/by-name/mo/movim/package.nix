{ lib
, fetchFromGitHub
, dash
, php
, phpCfg ? null
, withPgsql ? true # “strongly recommended” according to docs
, withMysql ? false
}:

php.buildComposerProject (finalAttrs: {
  pname = "movim";
  version = "0.23";

  src = fetchFromGitHub {
    owner = "movim";
    repo = "movim";
    rev = "v${finalAttrs.version}";
    hash = "sha256-9MBe2IRYxvUuCc5m7ajvIlBU7YVm4A3RABlOOIjpKoM=";
  };

  php = php.buildEnv ({
    extensions = ({ all, enabled }:
      enabled
        ++ (with all; [ curl dom gd imagick mbstring pdo simplexml ])
        ++ lib.optionals withPgsql (with all; [ pdo_pgsql pgsql ])
        ++ lib.optionals withMysql (with all; [ mysqli mysqlnd pdo_mysql ])
    );
  } // lib.optionalAttrs (phpCfg != null) {
    extraConfig = phpCfg;
  });

  # no listed license
  # pinned commonmark
  composerStrictValidation = false;

  vendorHash = "sha256-PBoJbVuF0Qy7nNlL4yx446ivlZpPYNIai78yC0wWkCM=";

  postInstall = ''
    mkdir -p $out/bin
    echo "#!${lib.getExe dash}" > $out/bin/movim
    echo "${lib.getExe finalAttrs.php} $out/share/php/${finalAttrs.pname}/daemon.php \"\$@\"" >> $out/bin/movim
    chmod +x $out/bin/movim

    mkdir -p $out/share/{bash-completion/completion,fish/vendor_completions.d,zsh/site-functions}
    $out/bin/movim completion bash | sed "s/daemon.php/movim/g" > $out/share/bash-completion/completion/movim.bash
    $out/bin/movim completion fish | sed "s/daemon.php/movim/g" > $out/share/fish/vendor_completions.d/movim.fish
    $out/bin/movim completion zsh | sed "s/daemon.php/movim/g" > $out/share/zsh/site-functions/_movim
    chmod +x $out/share/{bash-completion/completion/movim.bash,fish/vendor_completions.d/movim.fish,zsh/site-functions/_movim}
  '';

  meta = {
    description = "a federated blogging & chat platform that acts as a web front end for the XMPP protocol";
    homepage = "https://movim.eu";
    license = lib.licenses.agpl3Plus;
    maintainers = with lib.maintainers; [ toastal ];
    mainProgram = "movim";
  };
})
