libra.global()

select = html.select

{ tokenize, parse, translate } = seacow

editorOptions = 

    fontSize: "16pt",
    highlightActiveLine: false,
    highlightGutterLine: false
    showPrintMargin: false,
    showGutter: true,
    theme: "ace/theme/merbivore"

input = ace.edit "input"
input.setOptions editorOptions

output = ace.edit "output"
output.setOptions editorOptions

output.setReadOnly true
output.renderer.$cursorLayer.element.style.display = "none"

window.input = input
window.output = output

format = (code) -> prettier.format code, parser: 'babel', plugins: prettierPlugins
array = (...arr) ->  [...arr]
object = (obj) -> obj
say = (...args) ->
    text =  output.getValue()
    newline = if text.length > 0 then '\n' else ''
    output.setValue text + newline + args.join(' ')

save = ->
    line = input.session.getLine 0
    res = line.match /^\[save to: ([a-zA-Z0-9]+)\]$/
    if res
        vault.set res[1], input.getValue()
        output.setValue "saved to #{res[1]}"
    else
        output.setValue "no save name found."

load = (name) ->
    # vault.get 'test | input.setValue
    input.setValue vault.get name
    input.gotoLine 0
    input.focus()

load 'last'

select('#controls').onclick = (evt) ->

    try

        return unless evt.target.classList.contains 'button'

        label = evt.target.innerText
        seaCode = input.getValue()
        tokens = tokenize seaCode
        ast = parse tokens
        jsCode = translate ast

        vault.set 'last', input.getValue()

        if label is 'tokens'
            output.setValue (format JSON.stringify tokens)[0..-2]
        if label is 'parse tree'
            output.setValue (format "(#{JSON.stringify ast})")[0..-2]
        if label is 'javascript'
            output.setValue (format jsCode)[0..-2]
        if label is 'evaluate'
            output.setValue ''
            eval jsCode
        if label is 'save'
            save()
        if label is 'help'
            output.setValue help

        output.gotoLine 1000000

    catch error

        output.setValue '' + error
        output.gotoLine 1000000

addEventListener "keydown", (evt) ->
    #log evt
    #evt.preventDefault()

vault.set "animals",
'''
animals = array 'rabits 'snakes 'whales 'ducks
for animal in animals
    say "i like [ animal ]"
say "they are all cute"
'''

help = 
'''
to save your code, put "[save to: name]" on the first line and click save.
replace name with your own name. names must match "[a-zA-Z0-9]+".

to load your code, write "load 'name" in the editor and click "evaluate".
'''