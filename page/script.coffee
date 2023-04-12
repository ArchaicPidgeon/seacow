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

input.setValue vault.get 'last' 
input.gotoLine 0
input.focus()

format = (code) -> prettier.format code, parser: 'babel', plugins: prettierPlugins
array = (...arr) ->  [...arr]
object = (obj) -> obj
say = (...args) ->
    text =  output.getValue()
    newline = if text.length > 0 then '\n' else ''
    output.setValue text + newline + args.join(' ')

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
        if label is 'examples'
            output.setValue examples
        if label is 'clear'
            output.setValue ''

        output.gotoLine 1000000

    catch error

        output.setValue '' + error
        output.gotoLine 1000000

addEventListener "keydown", (evt) ->
    #log evt
    #evt.preventDefault()

examples =

'''
let animals = array 'rabits 'snakes 'whales 'ducks
for animal in animals
    say "i like [ animal ]"
say "they are all cute"
'''
