# https://github.com/Orange-OpenSource/hurl/releases

[private]
HURL_VERSION := "7.0.0"
[private]
HURL_NAME := "hurl-" + HURL_VERSION + "-" + arch() + "-" + OS + "-" + OS_ALT
[private]
HURL := LOCAL_PATH / HURL_NAME / "bin" / "hurl"

[private]
hurl *ARGS:
  @[ -x {{ HURL }} ] \
  || (echo {{ GREEN }}🔀 Installing hurl {{ HURL_VERSION }} ...{{ NORMAL }} \
     && mkdir -p {{ BIN_PATH }} \
     && (curl -LSsf "https://github.com/Orange-OpenSource/hurl/releases/download/{{ HURL_VERSION }}/{{ HURL_NAME }}.tar.gz" | tar zxv -C {{ LOCAL_PATH }}) \
     && chmod +x {{ HURL }} && echo {{ MAGENTA }}{{ HURL }} {{ NORMAL }} && {{ HURL }} --version \
     && ln -sf {{ HURL }} {{ BIN_PATH }}/hurl && echo {{ MAGENTA }}hurl{{ NORMAL }} && hurl --version)
  {{ if ARGS != "" { HURL + " " + ARGS } else { HURL + " --help" } }}
