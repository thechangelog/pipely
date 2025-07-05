# https://app-updates.agilebits.com/product_history/CLI2

[private]
OP_VERSION := "2.31.1"
[private]
OP_NAME := "op_" + OS_ALT2 + "_" + ARCH_ALT + "_v" + OP_VERSION
[private]
OP_DIR := LOCAL_PATH / OP_NAME / "bin"
[private]
OP := OP_DIR / "op"

[private]
[positional-arguments]
op *ARGS:
  @[ -x {{ OP }} ] \
  || (echo {{ _GREEN }}🔐 Installing op {{ OP_VERSION }} ...{{ _RESET }} \
     && mkdir -p {{ BIN_PATH }} {{ OP_DIR }} \
     && curl -LSsfo {{ OP_NAME }}.zip "https://cache.agilebits.com/dist/1P/op2/pkg/v{{ OP_VERSION }}/{{ OP_NAME }}.zip" \
     && unzip {{ OP_NAME }}.zip -d {{ OP_DIR }} \
     && rm {{ OP_NAME }}.zip \
     && chmod +x {{ OP }} && echo {{ _MAGENTA }}{{ OP }} {{ _RESET }} && {{ OP }} --version \
     && ln -sf {{ OP }} {{ BIN_PATH }}/op && echo {{ _MAGENTA }}op{{ _RESET }} && op --version)
  {{ if ARGS != "" { OP + " " + ' "$@"' } else { OP + " --help" } }}
