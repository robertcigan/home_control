import { Controller } from "@hotwired/stimulus"
import {
  EditorView,
  basicSetup,
  keymap,
  indentWithTab,
  indentUnit,
  StreamLanguage,
  ruby
} from "codemirror"

// Bundled manually (importmap pin failed on SSL): codemirror + @codemirror/legacy-modes
export default class extends Controller {
  connect() {
    this.textarea = this.element.querySelector("#program_code")

    if (!this.textarea) {
      return
    }

    this.view = new EditorView({
      doc: this.textarea.value,
      extensions: [
        basicSetup,
        keymap.of([indentWithTab]),
        indentUnit.of("  "),
        StreamLanguage.define(ruby),
        EditorView.updateListener.of((update) => {
          if (update.docChanged) {
            this.textarea.value = update.state.doc.toString()
          }
        })
      ]
    })

    this.textarea.parentNode.insertBefore(this.view.dom, this.textarea)
    this.textarea.style.display = "none"

    this.element.editorView = this.view
    this.view.dom.editorView = this.view
  }

  disconnect() {
    if (this.view) {
      this.view.destroy()
      this.view = null
    }

    if (this.element.editorView) {
      delete this.element.editorView
    }

    if (this.textarea) {
      this.textarea.style.display = ""
    }
  }
}
