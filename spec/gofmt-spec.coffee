path = require 'path'
fs = require 'fs-plus'
temp = require('temp').track()
{WorkspaceView} = require 'atom'
_ = require 'underscore-plus'

describe "format", ->
  [editor, buffer, filePath] = []

  beforeEach ->
    directory = temp.mkdirSync()
    atom.project.setPath(directory)
    atom.workspaceView = new WorkspaceView()
    atom.workspace = atom.workspaceView.model
    filePath = path.join(directory, 'go-plus.go')
    fs.writeFileSync(filePath, '')
    editor = atom.workspace.openSync(filePath)
    buffer = editor.getBuffer()

    waitsForPromise ->
      atom.packages.activatePackage('language-go')

    waitsForPromise ->
      atom.packages.activatePackage('go-plus')

  describe "when format on save is enabled", ->
    beforeEach ->
      atom.config.set("go-plus.formatOnSave", true)
      atom.config.set("go-plus.vetOnSave", false)
      atom.config.set("go-plus.lintOnSave", false)
      atom.config.set("go-plus.environmentOverridesConfiguration", true)
      atom.config.set("go-plus.goExecutablePath", "$GOROOT/bin/go")
      atom.config.set("go-plus.gofmtPath", "$GOROOT/bin/gofmt")
      atom.config.set("go-plus.showErrorPanel", false)

    it "reformats the file", ->
      done = false
      runs ->
        dispatch = atom.packages.getLoadedPackage('go-plus').mainModule.dispatch
        dispatch.on 'dispatch-complete', =>
          expect(fs.readFileSync(filePath, {encoding: 'utf8'})).toBe "package main\n\nfunc main() {\n}\n"
          expect(dispatch.errorCollection?).toBe true
          expect(_.size(dispatch.errorCollection)).toBe 0
          done = true
        buffer.setText("package main\n\nfunc main()  {\n}\n")
        buffer.save()

      waitsFor ->
        done is true

    it "collects errors when the input is invalid", ->
      done = false
      runs ->
        dispatch = atom.packages.getLoadedPackage('go-plus').mainModule.dispatch
        dispatch.on 'dispatch-complete', (editorView) =>
          expect(fs.readFileSync(filePath, {encoding: 'utf8'})).toBe "package main\n\nfunc main(!)  {\n}\n"
          expect(dispatch.errorCollection?).toBe true
          expect(_.size(dispatch.errorCollection)).toBe 1
          expect(dispatch.errorCollection[0].column).toBe "11"
          expect(dispatch.errorCollection[0].line).toBe "3"
          expect(dispatch.errorCollection[0].msg).toBe "expected type, found '!'"
          done = true
        buffer.setText("package main\n\nfunc main(!)  {\n}\n")
        buffer.save()

      waitsFor ->
        done is true

  describe "when format on save is disabled", ->
    beforeEach ->
      atom.config.set("go-plus.formatOnSave", false)
      atom.config.set("go-plus.vetOnSave", false)
      atom.config.set("go-plus.lintOnSave", false)
      atom.config.set("go-plus.environmentOverridesConfiguration", true)
      atom.config.set("go-plus.goExecutablePath", "$GOROOT/bin/go")
      atom.config.set("go-plus.gofmtPath", "$GOROOT/bin/gofmt")
      atom.config.set("go-plus.showErrorPanel", false)

    it "does not reformat the file", ->
      done = false
      runs ->
        dispatch = atom.packages.getLoadedPackage('go-plus').mainModule.dispatch
        dispatch.on 'dispatch-complete', =>
          expect(fs.readFileSync(filePath, {encoding: 'utf8'})).toBe "package main\n\nfunc main()  {\n}\n"
          expect(dispatch.errorCollection?).toBe true
          expect(_.size(dispatch.errorCollection)).toBe 0
          done = true
        buffer.setText("package main\n\nfunc main()  {\n}\n")
        buffer.save()

      waitsFor ->
        done is true
