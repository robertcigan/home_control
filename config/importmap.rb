# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin "@rails/actioncable", to: "actioncable.esm.js"
pin "bootstrap", to: "bootstrap.min.js"
pin "@popperjs/core", to: "popper.js"
pin "tom-select"
pin "gridstack", to: "gridstack.js"
pin "echarts", to: "echarts.esm.min.js"
# Manual vendor (bin/importmap pin failed on OpenSSL CRL verify):
# codemirror@6.0.2 + @codemirror/legacy-modes@6.5.3 (ruby) bundled via esbuild
pin "codemirror"
pin_all_from "app/javascript/controllers", under: "controllers"
pin_all_from "app/javascript/channels", under: "channels"
pin_all_from "app/javascript/lib", under: "lib"
