# https://github.com/Orange-OpenSource/hurl/releases

[private]
HURL_VERSION := "6.1.1"
[private]
HURL_NAME := "hurl-" + HURL_VERSION + "-" + arch() + "-" + OS + "-" + OS_ALT
[private]
HURL := LOCAL_PATH / HURL_NAME / "bin" / "hurl"

[private]
hurl *ARGS:
  @[ -x {{ HURL }} ] \
  || (echo {{ _GREEN }}🔀 Installing hurl {{ HURL_VERSION }} ...{{ _RESET }} \
     && mkdir -p {{ BIN_PATH }} \
     && (curl -LSsf "https://github.com/Orange-OpenSource/hurl/releases/download/{{ HURL_VERSION }}/{{ HURL_NAME }}.tar.gz" | tar zxv -C {{ LOCAL_PATH }}) \
     && chmod +x {{ HURL }} && echo {{ _MAGENTA }}{{ HURL }} {{ _RESET }} && {{ HURL }} --version \
     && ln -sf {{ HURL }} {{ BIN_PATH }}/hurl && echo {{ _MAGENTA }}hurl{{ _RESET }} && hurl --version)
  {{ if ARGS != "" { HURL + " " + ARGS } else { HURL + " --help" } }}
