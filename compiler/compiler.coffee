
#{encode} = require("./sourcemap-codec.js")

log = console.log

logs = (...x) ->
    log ...x
    log ''

logAll = (xs) ->
    log x for x in xs
    log ''

run = (x) -> x()

##########################################################################################

la =    '(?=[, :})#\\]]|\\n|$)' # look ahead
lanpa = '(?=[, })#\\]]|\\n|$)' # look ahead - no prop access

numRegexA =
///^ [+-]? ( [0-9A-Z]+[.][0-9A-Z]+ | [.][0-9A-Z]+ | [0-9A-Z]+ )/[0-9]+ #{la} ///i

numRegexB =
///^ [+-]? ( [0-9]+[.][0-9]+ | [.][0-9]+ | [0-9]+ ) #{la} ///

operatorRegex =
/// ^(==|!=|<=|>=|<<|>>|//|%%|\*\*|[-+*/%=<>]) #{lanpa} ///

reservedWordRegex = /// ^(def|await|yield|outer|var|let|return
|break|continue|comment|lang|default|while|until|loop|for|of|in
|ever|if|unless|else|opt|alt|do|try|catch|finally) #{lanpa} ///

nameRegexA =
    ///^~?
    ( @?[a-zA-Z_$][a-zA-Z0-9_$]* | &[a-zA-Z_$][a-zA-Z0-9_$]* | &[0-9]+ | && | & )
    ( [?]?:[a-zA-Z_$][a-zA-Z0-9_$]* )* [?!]? #{la}
    ///

nameRegexB =
    ///^
    ( [.:]?[a-zA-Z_$][a-zA-Z0-9_$]* ) ( [?]?:[a-zA-Z_$][a-zA-Z0-9_$]* )* [?]? #{la}
    ///

##########################################################################################

tokenize = (charStream, logMode) ->

    if charStream.split('\n')[0] is '[mode = literate]'
        mode = 'literate'

    tokenFuncs = {}

    scanToken = (type, regex) ->
            res = charStream[idx..].match regex
            return false if res is null
            eat {type, content: res[0]}
            return true

    scanTokenBlock = (type, regex) ->

        return false unless charStream[idx..].match regex

        parts = []

        idx2 = idx

        line = charStream[idx2..].match /^.*/
        parts.push line[0]
        idx2 += line[0].length

        ## find base indent level

        # match all whitespace between the end of the first line
        # and the first non-whitespace character.
        whitespace = (charStream[idx2..].match /^[ \n]*(?=[^ \n])/)

        # return if there is no next non-whitespace char (ie EOF)
        unless whitespace
            #eat {type, content: parts[0]}
            return false #true

        baseIndent = whitespace[0].split('\n').at(-1).length

        # return if first non-whitespace char is not indented.
        unless baseIndent > indentStack.at(-1)
            #eat {type, content: parts[0]}
            return false #true

        ## consume lines

        while true

            line = charStream[idx2..].match /^\n([ ]*)(.*)/
            break unless line

            isDedent = line[2].length > 0
            isNonEmpty = line[1].length < baseIndent
            break if isDedent and isNonEmpty

            parts.push line[0]
            idx2 += line[0].length

        eat {type, content: parts.join ''}
        return true

    ######################################################################################

    tokenFuncs.litComment = ->
        return false unless mode is 'literate'
        res = charStream[idx..].match /^\n[^ \n].+/
        return false unless res
        eat {type: 'comment', content: res[0]}
        return true

    tokenFuncs.bool = -> scanToken 'bool', "^true|false" + la
    tokenFuncs.reservedWord = -> scanToken 'resWord', reservedWordRegex
    tokenFuncs.operator = -> scanToken 'biOp', operatorRegex
    tokenFuncs.label = -> scanToken 'label', '^/[a-zA-Z_$]+/' + lanpa
    tokenFuncs.comma = -> scanToken 'comma', '^,' + lanpa
    tokenFuncs.wave = -> scanToken 'wave', '^~' + la
    tokenFuncs.pipe = -> scanToken 'pipe', '^\\|' + lanpa
    tokenFuncs.key = -> scanToken 'key', '^[a-zA-Z][a-zA-Z0-9_$]*[:;]' + lanpa
    tokenFuncs.name = -> scanToken 'name', nameRegexA
    tokenFuncs.tag = -> scanToken 'tag', '^<(\\w+)(#\\w+)?(\\.\\w+)*>' + lanpa
    tokenFuncs.dotName = -> scanToken 'dotName', nameRegexB
    tokenFuncs.thinArrow = -> scanToken 'thinArrow', '^->' + lanpa
    tokenFuncs.fatArrow = -> scanToken 'fatArrow', '^=>' + lanpa
    tokenFuncs.space = -> scanToken 'space', '^[ ]+'
    tokenFuncs.openParen = -> scanToken 'openParen', '^\\('
    tokenFuncs.closeParen = -> scanToken 'closeParen', '^\\)' + la
    tokenFuncs.openCurly = -> scanToken 'openCurly', '^[{]'
    tokenFuncs.closeCurly = -> scanToken 'closeCurly', '^[}]' + la
    tokenFuncs.inlineComment = -> scanToken 'comment', '^\\[.*\\]' + lanpa

    tokenFuncs.numberRadix = -> scanToken 'number', numRegexA
    tokenFuncs.numberSep = -> scanToken 'number', '^[0-9]{1,3}(_[0-9]{3})+' + la
    tokenFuncs.number = -> scanToken 'number', numRegexB

    tokenFuncs.commentBlock = -> scanTokenBlock 'comment', /^#/
    tokenFuncs.commentLine = -> scanToken 'comment', /^#.*/

    tokenFuncs.arrowStringA = -> scanToken 'string', /^~>[ ].*/
    tokenFuncs.arrowStringB = -> scanTokenBlock 'blockString', /^~>(?![^ \n])/
    tokenFuncs.arrowStringC = -> scanToken 'string', /^~>(?=\n)|^~>$/

    tokenFuncs.stringSingle = -> scanToken 'string', ///^'[a-zA-Z0-9_-]*#{lanpa}///
    tokenFuncs.stringDouble = -> scanToken 'string', ///^"(?:\\.|[^"[])*"#{la}///

    tokenFuncs.stringStart = -> scanToken 'stringStart', ///^"(?:\\.|[^"[])*\[#{la}///
    tokenFuncs.stringMiddle = -> scanToken 'stringMiddle', ///^](?:\\.|[^"[])*\[#{la}///
    tokenFuncs.stringEnd = -> scanToken 'stringEnd', ///^](?:\\.|[^"[])*"#{la}///

    tokenFuncs.endOfFile = ->

        return false unless charStream[idx..] is ''

        while indentStack.length > 1
            indentStack.pop()
            eat {type: 'newline', content: ''}
            eat {type: 'dedent', content: ''}

        eat {type: 'EOF', content: ''}

        return true

    ######################################################################################

    indentStack = [0]

    tokenFuncs.newLine = ->
        res = charStream[idx..].match /^\n */
        return false unless res
        idx += res[0].length

        indent = res[0].length - 1
        previous = indentStack.at(-1)

        # don't change indent level for empty lines.
        if charStream[idx] is '\n'
            eat {type: 'emptyLine', content: ''}

        else if indent == previous
            eat {type: 'newline', content: ''}

        else if indent > previous
            indentStack.push indent
            eat {type: 'indent', content: ''}

        else if indent < previous
            throw 'Error: invalid dedent level' unless indent in indentStack
            dedents = indentStack.length - (indentStack.indexOf indent) - 1

            eat {type: 'newline', content: ''}

            while dedents-- > 0
                indentStack.pop()
                eat {type: 'dedent', content: ''}
                eat {type: 'newline', content: ''}

        return true


    ######################################################################################

    eat = (token) ->
        #log token
        tokenStream.push token
        idx += token.content.length
        return true

    tokenStream = []

    idx = 0

    advance = ->

        for funcName, func of tokenFuncs
            return funcName isnt 'endOfFile' if func()

        throw 'ERROR: unable to identify token at index ' +
               idx + ':\n' + charStream[idx..].match /^.*/

    continue while advance()

    return tokenStream.filter (token) ->
        token.type not in ['space', 'comment', 'emptyLine']

##########################################################################################

parse = (tokenStream) ->

    idx = 0

    token = null
    nextToken = null

    advance = ->
        token = tokenStream[idx++]
        nextToken = tokenStream[idx]

    advance()

    ######################################################################################

    parseTerminal = ->
        res = token
        advance()
        #log token
        return res

    ######################################################################################

    endExpr = false

    valueTypes = [
        'string', 'number', 'thinArrow', 'openCurly', 'stringStart'
        'name', 'openParen', 'blockString', 'fatArrow', 'bool', 'tag'
    ]

    blockTypes = ['blockString', 'fatArrow']

    parseValue = (options) ->

        {canBeBlock, canBeUpdate} = options

        if (token.type in blockTypes) and (not canBeBlock)
            throw 'block not allowed here'

        #lastValueWasBlock = token.type in blockTypes

        if token.type is 'name'
            if token.content.endsWith '?'
                throw 'parseValue: illegal "?"'
            if (canBeUpdate) and token.content.startsWith '~'
                throw 'bad spread'
            if (not canBeUpdate) and token.content.endsWith '!'
                throw 'bad update'
            return parseTerminal()
        else if token.type in ['bool', 'number', 'string', 'blockString']
            return parseTerminal()
        else if token.type is 'stringStart'
            return parseStringInterp()
        else if token.type in ['thinArrow', 'openCurly']
            return parseLineFunction()
        else if token.type is 'fatArrow'
            return parseFatArrow()
        else if token.type is 'openParen'
            return parseParen()

    parseTag = ->

        logs token.content

        [front, ...classes] = token.content[1 .. -2].split '.'
        [tag, id] = front.split '#'

        #logs 'tag:', tag
        #logs 'id:', id
        #logs 'classes:', ...classes

        content = [
            {type: 'name', content: '$tag'}
            {type: 'string', content: "~> #{token.content}"}
        ]

        parseTerminal()

        return content

    parseExpression = (options) ->

        {mustBeHead, canBeBlock} = options

        content = []

        if canStartHead token
            content.push parseHead canBeBlock
        else if mustBeHead
            throw 'bad expression'
        else content.push {type: 'head', content: [{type: 'name', content: '&'}]}

        while true
            if token.content is '='
                content.push parsePipeAssign()
            else if token.type is 'dotName'
                content.push parsePipeCall canBeBlock
            else if token.type is 'biOp'
                content.push parsePipeOp canBeBlock
            else if token.type is 'pipe'
                parseTerminal()
                if token.type is 'name' and token.content.match /^[^!@&]+$/
                    token.type = 'dotName'
                    token.content = '.' + token.content
                throw 'bad pipe' unless token.type in ['dotName', 'biOp']
            else if token.type is 'newline'
                #log endExpr
                #break if endExpr
                if nextToken?.type in ['dotName', 'biOp']
                then parseTerminal()
                else break
            else break

        # handle update assignment
        handleUpdate content

        return {type: 'expr', content}

    handleUpdate = (expr) ->
        seg = expr[0]
        return unless seg.type is 'head'
        for elem in seg.content
            continue if elem.content in ['yield', 'await']
            if (elem.type is 'name') and (elem.content.endsWith '!')
                expr.push { type: 'pipeAssign', content: [elem] }
            break

    parseHead = (canBeBlock) ->
        endExpr = false
        content = []

        while token.content in ['await', 'yield']
            content.push parseTerminal()

        if (content.length > 0) and (token.type not in valueTypes)
            throw 'bad await/yield'

        endExpr = true if token.type in blockTypes
        if token.type is 'tag' then content.push ...(parseTag())
        else content.push parseValue {canBeUpdate: true, canBeBlock}

        while true
            if token.type in valueTypes
                endExpr = true if token.type in blockTypes
                content.push parseValue {canBeUpdate: false, canBeBlock}
            else if (token.type is 'wave')
                a = content.at(-2)
                throw 'bad ~' if a and a.content not in ['await', 'yield']
                content.push parseTerminal()
                break
            else if token.type is 'indent' and canBeBlock
                endExpr = true
                content.push parseArgBlock()
            else if token.type is 'key'
                content.push parseObject canBeBlock
            else break

        return {type: 'head', content}

    parsePipeCall = (canBeBlock) ->
        content = []

        content.push parseTerminal()

        while true
            if token.type in valueTypes
                endExpr = true if token.type in blockTypes
                content.push parseValue {canBeUpdate: false, canBeBlock}
            else if token.type is 'indent' and canBeBlock
                endExpr = true
                content.push parseArgBlock()
            else if token.type is 'key'
                content.push parseObject canBeBlock
            else break

        return {type: 'pipeCall', content}

    parsePipeOp = (canBeBlock) ->
        content = []
        content.push parseTerminal()

        while true
            if token.type in valueTypes
                endExpr = true if token.type in blockTypes
                content.push parseValue {canBeUpdate: false, canBeBlock}
            #else if token.type is 'indent' and canBeBlock
            #    endExpr = true
            #    content.push parseArgBlock()
            else break

        return {type: 'pipeOp', content}

    parseObject = (canBeBlock) ->
        content = []

        while token.type is 'key'
            if token.content.endsWith ';'
                name = token.content[.. -2]
                token.content = name + ':'
                content.push parseTerminal()
                content.push {type: 'name', content: name}
                continue
            content.push parseTerminal()
            unless token.type in valueTypes
                throw 'bad value'
            endExpr = true if token.type in blockTypes
            if (token.type is 'name') and (token.content.startsWith '~')
                throw 'bad spread'
            content.push parseValue {canBeUpdate: false, canBeBlock}

        return {type: 'object', content}

    parseParen = ->

        parseTerminal()
        unless canStartHead token
            throw '(bad)'
        res = parseExpression mustBeHead: true, canBeBlock: false
        throw 'missing paren' unless token.type is 'closeParen'
        parseTerminal()

        return res

    hasArguments = ->
        idx2 = idx - 1
        while true
            if tokenStream[idx2].type is 'comma'
                return true
            unless isParamName tokenStream[idx2]
                return false
            idx2++

    parseLineFunction = ->

        content = []

        content.push {type: 'resWord', content: ''}

        type = token.type

        parseTerminal()

        #throw 'bad comma' if token.type is 'comma'

        if hasArguments()
            until token.type is 'comma'
                if token.content.startsWith '~'
                    throw 'bad soak' unless nextToken?.type is 'comma'
                content.push parseTerminal()
            parseTerminal()

        if (canStartHead token) or (token.type in ['biOp', 'dotName'])
            content.push parseExpression mustBeHead: false, canBeBlock: false
        else content.push {type: 'empty', content: ''}

        if type is 'openCurly'
            #logs token unless token.type is 'closeCurly'
            throw 'missing curly' unless token.type is 'closeCurly'
            parseTerminal()

        return handleAwaitYield {type: 'lineFunction', content}

    parseStringInterp = ->

        content = []

        content.push parseTerminal()

        while true

            throw '[bad]' unless canStartHead token
            content.push parseExpression mustBeHead: true, canBeBlock: false

            if token.type is 'stringMiddle'
                content.push parseTerminal()
            else if token.type is 'stringEnd'
                content.push parseTerminal()
                break
            else throw '[bad]'

        return {type: 'stringInterp', content}

    ######################################################################################

    canStartHead = (token) ->
        a = token.type in valueTypes
        b = token.content in ['await', 'yield']
        return a or b

    handleAwaitYield = (node) ->

        foundAwait = false
        foundYield = false

        recFunc = (node) ->

            for subNode in node.content
                if subNode.content is 'await'
                    foundAwait = true
                if subNode.content is 'yield'
                    foundYield = true
                continue if subNode.type in ['def', 'blockFunc', 'thinArrow', 'curly']
                continue unless Array.isArray subNode.content
                recFunc subNode

        recFunc node

        kw = 'function'
        if foundAwait then kw = 'async ' + kw
        if foundYield then kw = kw + '*'
        node.content[0].content = kw

        return node

    handleScope = (node) ->

        vars = []
        outers = []

        recFunc = (node) ->

            if isString node.content
                return

            if node.type in ['def', 'blockFunc']
                return

            subNodes = node.content

            if node.type is 'pipeAssign'
                if isString subNodes[0].content
                    unless subNodes[0].content.endsWith '!'
                        vars.push subNodes[0].content

            if node.type is 'destruct'
                for subNode in subNodes
                    if isString subNode.content
                        vars.push subNode.content

            if node.type is 'let'
                if isString subNodes[0].content
                    vars.push subNodes[0].content

            if node.type is 'for'
                vars.push subNodes[0].content
                if isSimpleName subNodes[1]
                then vars.push subNodes[1].content

            if node.type is 'var'
                (vars.push subNode.content) for subNode in subNodes

            if node.type is 'outer'
                (outers.push subNode.content) for subNode in subNodes

            recFunc subNode for subNode in subNodes

        recFunc node

        vars = vars.filter (name) ->

            (name not in outers) and (name.match /^:?[^@&:?]*$/)

        vars = vars.map (name) ->

            if name.startsWith ':'
            then name = name[1 .. -1]

            if name.endsWith '?'
            then name = name[0 .. -2]

            return name

        return node if vars.length is 0

        node.content.unshift {type: 'scope', content: 'var ' + vars.join ','}

        return node

    checkName = (tok, regex) ->
        a = tok.type in ['name', 'dotName']
        b = tok.content.match regex
        return a and b

    isVarName = (tok) -> checkName tok, /^[^~!]*$/
    isParamName = (tok) -> checkName tok, /^~?[a-zA-Z_$][a-zA-Z0-9_$]*$/
    isSimpleName = (tok) -> checkName tok, /^[a-zA-Z_$][a-zA-Z0-9_$]*$/
    isDestructName =  (tok) -> checkName tok, /^[:~]?[a-zA-Z_$][a-zA-Z0-9_$]*$/

    parsePipeAssign = -> #throw 'unimplemented'

        parseTerminal()

        content = []

        if isVarName token
            content.push parseTerminal()
        else if token.type is 'openParen'
            content.push parseDestruct()
        else throw 'parsePipeAssign'

        return {type: 'pipeAssign', content}

    parseDestruct = ->

        content = []

        parseTerminal()

        type = null

        while isDestructName token

            if type and (token.type isnt type)
            then throw 'parseDestruct'
            else type = token.type
            content.push parseTerminal()

        throw 'parseDestruct' unless content.length > 0

        throw 'parseDestruct' unless token.type is 'closeParen'
        parseTerminal()

        return {type: 'destruct', content}

    parseFatArrow = ->

        content = []

        content.push parseTerminal()

        while isParamName token
            if token.content.startsWith '~'
                throw 'bad soak' unless nextToken?.type is 'indent'
            content.push parseTerminal()

        throw 'missing block' unless token.type is 'indent'
        content.push handleScope parseStatementBlock()

        return handleAwaitYield {type: 'blockFunc', content}

    parseDef = ->

        content = []

        content.push parseTerminal()

        throw 'bad func name' unless token.type is 'name'
        content.push parseTerminal()

        while isParamName token
            if token.content.startsWith '~'
                throw 'bad soak' unless nextToken?.type is 'indent'
            content.push parseTerminal()

        throw 'missing block' unless token.type is 'indent'
        content.push handleScope parseStatementBlock()

        return handleAwaitYield {type: 'def', content}

    ######################################################################################

    parseStatementBlock = ->

        content = [{
            type: 'var', content: [ {type: 'name', content: '_'} ]
        }]

        if token.type is 'indent'
            parseTerminal()

        while true
            #if token.type is 'newline'
            #    parseTerminal()
            if token.content is 'let'
                content.push parseLet()
            else if token.content is 'return'
                content.push parseReturn()
            else if token.content is 'throw'
                content.push parseThrow()
            else if token.content is 'try'
                content.push parseTry()
            else if token.content is 'opt'
                content.push parseOpt()
            else if token.content is 'def'
                content.push parseDef()
            else if token.content is 'while'
                content.push parseWhile()
            else if token.content is 'for'
                content.push parseFor()
            else if token.content in ['var', 'outer']
                content.push parseDeclaration()
            else if token.content in ['if', 'unless']
                content.push parseConditional()
            else if token.content in ['break', 'continue']
                content.push parseLoopControl()
            else if canStartHead token
                content.push parseExpression mustBeHead: true, canBeBlock: true
            else if token.type is 'dedent'
                parseTerminal()
                break

            if token.type is 'newline' then parseTerminal()
            else if token.type is 'EOF' then break
            else throw 'bad statement: ' + token.type

        return {type: 'statementBlock', content}

    parseTry = ->

        content = []

        parseTerminal()
        throw 'try' unless token.type is 'indent'
        content.push {type: 'try', content: [parseStatementBlock()]}

        if nextToken?.content is 'catch'

            catchContent = []

            if token.type is 'newline'
            then parseTerminal()
            else throw 'catch'

            parseTerminal()

            if isSimpleName token
                catchContent.push parseTerminal()

            throw 'catch' unless token.type is 'indent'
            catchContent.push parseStatementBlock()

            content.push {type: 'catch', content: catchContent}

        if nextToken?.content is 'finally'

            if token.type is 'newline'
            then parseTerminal()
            else throw 'finally'

            parseTerminal()

            throw 'finally' unless token.type is 'indent'
            content.push {type: 'finally', content: [parseStatementBlock()]}

        throw 'missing catch/finally' if content.length < 2

        return {type: 'TCF', content}

    parseLoopControl = ->

        content = []

        content.push parseTerminal()

        if token.type is 'name'
        then content.push parseTerminal()

        return {type: 'loopControl', content}

    parseDeclaration = ->

        content = []

        type = token.content

        parseTerminal()

        content.push parseTerminal() while isSimpleName token

        return {type, content}

    parseConditional = ->

        content = []

        type = token.content

        parseTerminal()

        throw 'expression expected' unless canStartHead token
        content.push parseExpression mustBeHead: true, canBeBlock: false

        parseTerminal() if token.type is 'newline'

        if token.content is 'let'
            content.push parseLet()
        else if token.content is 'return'
            content.push parseReturn()
        else if token.content is 'throw'
            content.push parseThrow()
        else if token.content is 'def'
            content.push parseDef()
        else if token.content is 'while'
            content.push parseWhile()
        else if token.content is 'for'
            content.push parseFor()
        else if token.content in ['break', 'continue']
            content.push parseTerminal()
        else if token.content is 'do'
            parseTerminal()
            throw 'parseContitional' unless canStartHead token
            content.push parseExpression mustBeHead: true, canBeBlock: true

        return {type, content}

    parseFor = ->

        content = []

        parseTerminal()

        throw 'name expected' unless isSimpleName token
        content.push parseTerminal()

        content.push parseTerminal() if isSimpleName token

        throw 'in/of expected' unless token.content in ['in', 'of']

        content.push parseTerminal()

        throw 'expression expected' unless canStartHead token
        content.push parseExpression mustBeHead: true, canBeBlock: false

        content.push parseTerminal() if token.type is 'label'

        throw 'missing block' unless token.type is 'indent'
        content.push parseStatementBlock()

        return {type: 'for', content}

    parseWhile = ->

        content = []

        parseTerminal()

        throw 'expression expected' unless canStartHead token
        content.push parseExpression mustBeHead: true, canBeBlock: false

        content.push parseTerminal() if token.type is 'label'

        throw 'missing block' unless token.type is 'indent'
        content.push parseStatementBlock()

        return {type: 'while', content}

    parseOpt = ->

        content = []

        while true

            if (token.content is 'alt') and (nextToken?.content is 'default')

                parseTerminal()
                parseTerminal()

                throw 'missing block' unless token.type is 'indent'
                content.push parseStatementBlock()

                break

            parseTerminal()

            throw 'expression expected' unless canStartHead token
            content.push parseExpression mustBeHead: true, canBeBlock: false

            throw 'missing block' unless token.type is 'indent'
            content.push parseStatementBlock()

            throw 'wha??' unless token.type in ['newline', 'EOF']

            if nextToken?.content is 'alt'
                parseTerminal()
            else break

        return {type: 'opt', content}

    parseLet = ->

        content = []

        parseTerminal()

        if isVarName token
            content.push parseTerminal()
        else if token.type is 'openParen'
            content.push parseDestruct()
        else throw 'parseLet'

        throw '= expected' unless token.content is '='
        parseTerminal()

        throw 'value expected' unless canStartHead token
        content.push parseExpression mustBeHead: true, canBeBlock: true

        return {type: 'let', content}

    parseReturn = ->

        content = []

        parseTerminal()

        if canStartHead token
            content.push parseExpression mustBeHead: true, canBeBlock: true

        return {type: 'return', content}

    parseThrow = ->

        content = []

        parseTerminal()

        if canStartHead token
            content.push parseExpression mustBeHead: true, canBeBlock: true

        return {type: 'throw', content}

    parseArgBlock = ->

        content = []

        parseTerminal()

        while true

            if canStartHead token
                content.push parseExpression mustBeHead: true, canBeBlock: true
                throw 'bad argument: ' + token.type unless token.type is 'newline'
            else if token.type is 'key'
                content.push parseObjectBlock()
            else if token.type is 'newline'
                parseTerminal()
            else if token.type is 'dedent'
                parseTerminal()
                break
            else if token.type is 'EOF'
                break
            else throw 'bad argument'

        return {type: 'argBlock', content}

    parseObjectBlock = ->

        content = []

        while token.type is 'key'
            if token.content.endsWith ';'
                name = token.content[.. -2]
                token.content = name + ':'
                content.push token # too hacky?
                token = {type: 'name', content: name} # too hacky?
                # instead: push (expression (head (name)))?
            else content.push parseTerminal()
            unless canStartHead token
                log token
                throw 'bad value'
            content.push parseExpression mustBeHead: true, canBeBlock: true
            throw 'bad value: ' + token.type unless token.type is 'newline'
            parseTerminal()

        return {type: 'object', content}

    makeStrict = (block) ->

        block.content.unshift {type: 'string', content: '~> use strict'}

        return block

    return makeStrict handleScope parseStatementBlock()

##########################################################################################

pVal = '_'

isString = (x) -> typeof x is 'string'
isArray = (x) -> Array.isArray x

translate = (node) ->

    if isString node.content
        if generate[node.type]
        then return generate[node.type] node.content
        else return node.content

    if isArray node.content
        subNodes = []
        for subNode in node.content
            subNodes.push translate subNode
        throw "can't translate " + node.type unless generate[node.type]
        return generate[node.type] subNodes

    logs node
    throw 'no content?'

generate =

    statementBlock: (subNodes) -> subNodes.join ';'

    expr: (subNodes) ->
        sn = subNodes.map (x) -> pVal + '=' + x
        sn[sn.length - 1] = subNodes[subNodes.length - 1]
        return "(#{sn.join(',')})"

    head: (subNodes) -> #subNodes.join ', '

        rs = []
        while subNodes[0] in ['await', 'yield']
            rs.push subNodes.shift()

        x = subNodes[0]
        xs = subNodes[1..]
        if xs.length is 0 then exp = x
        else exp = x + '(' + xs + ')'

        for r in rs.reverse()
            exp = "(#{r} #{exp})"

        return exp

    pipeOp: (subNodes) -> return [pVal, subNodes[0], subNodes[1]].join ''

    pipeAssign: (subNodes) ->
        name = subNodes[0].replaceAll '?.', '.'
        if name.endsWith '?'
            name = name[0 .. -2]
            return "(#{name} != null ? #{name} : #{name} = #{pVal})"
        return "#{name}=#{pVal}"

    let: (subNodes) ->
        name = subNodes[0].replaceAll '?.', '.'
        expr = subNodes[1]
        if name.endsWith '?'
            name = name[0 .. -2]
            return "(#{name} != null ? #{name} : #{name} = #{expr})"
        return "#{name}=#{expr}"

    return: (subNodes) -> return ["return", ...subNodes].join ' '
    throw: (subNodes) -> return ["throw", ...subNodes].join ' '

    pipeCall: (subNodes) ->
        #log subNodes
        func = subNodes[0]
        args = subNodes[1 ..]
        type = (if func[0] is ':' then 'method' else 'function')
        func = func.slice(1).replaceAll(':', '?.')

        if type is 'method'
            return "#{pVal}.#{func}(#{args.join ','})"
        if type is 'function'
            args.unshift pVal
            return "#{func}(#{args.join ','})"
        throw 'e.259'

    name: (content) ->
        res = content
        res = res.replaceAll(':', '?.')
        res = res.replace('@', 'this.')
        res = res.replace('&&', 'arguments')
        res = res.replace /^&([0-9]+)/, 'arguments[$1]'
        res = res.replace /^&([^.]+)/, 'arguments[0].$1'
        res = res.replace('&', 'arguments[0]')
        res = res.replace('~', '...')
        return res.replace '!', ''

    biOp: (content) -> return content
    bool: (content) -> return content
    number: (content) -> return content
    dotName: (content) -> return content
    resWord: (content) -> return content

    string: (content) ->
        if content.startsWith '"'
            return content
        if content.startsWith "'"
            return content + "'"
        JSON.stringify content[2 ..].trim()

    stringStart: (content) -> return content[0 .. -2] + '"'
    stringMiddle: (content) -> return '"' + content[1 .. -2] + '"'
    stringEnd: (content) -> return '"' + content[1 .. -1]
    wave: (content) -> return ''

    stringInterp: (content) ->
        return '(' + (content.join '+') + ')'

    blockFunc: (content) ->
        kw = content[0]
        args = content[1 .. -2]
        block = content.at(-1)
        return "#{kw}(#{args.join ','}){#{block}}"

    def: (content) ->
        kw = content[0]
        name = content[1]
        args = content[2 .. -2]
        block = content.at(-1)
        return "#{kw} #{name}(#{args.join ','}){#{block}}"

    lineFunction: (sn) -> "#{sn[0]}(#{sn[1..-2].join ','}){var _;return #{sn.at -1}}"

    opt: (content) ->

        res = []

        idx = 0

        while true

            a = content[idx++]
            b = content[idx++]

            break unless a and b

            res.push "if(#{a}){#{b}}"

        res = res.join 'else '

        if a then res += "else{#{a}}"

        return res

    while: (content) ->

        if content.at(-2).match '^[a-zA-Z_$]+:$'
        then label = content.at -2
        else label = ''

        return "#{label}while(#{content[0]}){#{content.at -1}}"

    for: (content) ->

        nameA = content[0]
        nameB = content[1]
        kw = content.at -3
        expr = content.at -2
        block = content.at -1

        label = ''

        if content.at(-2).match '^[a-zA-Z_$]+:$'
            kw = content.at -4
            expr = content.at -3
            label = content.at -2

        unless nameB in ['in', 'of']
            if kw is 'in'
                block = "#{nameB}++;" + block
                expr = "((#{nameB}=-1)," + expr + ')'
            else
                block = "#{nameB}=_ref[#{nameA}];" + block
                expr = '_ref = ' + expr + ''

        if kw is 'in'
        then kw = 'of'
        else kw = 'in'

        return "#{label}for(#{nameA} #{kw} #{expr}){#{block}}"

    if: (content) -> "if(#{content[0]}){#{content[1]}}"
    unless: (content) -> "if(not #{content[0]}){#{content[1]}}"

    var: -> return ''
    outer: -> return ''

    destruct: (content) ->
        if content[0].startsWith ':'
        then names = content.map (name) -> name[1..]
        else names = content

        if content[0].startsWith ':'
        then return "{" + names.join(',') + "}"
        else return "[" + names.join(',') + "]"

    object: (content) ->
        content
        res = content.join(',')
        res = res.replaceAll(':,', ':')
        return '{' + res + '}'

    argBlock: (content) -> return content.join ','

    label: (content) -> return content[1 .. -2] + ':'

    loopControl: (content) -> return content.join ' '

    TCF: (content) -> content.join ''
    try: (content) -> "try{#{content}}"
    catch: (c) -> if c.length is 1 then "catch{#{c[0]}}" else "catch(#{c[0]}){#{c[1]}}"
    finally: (content) -> "finally{#{content}}"

    #generate.statementBlock ast

##########################################################################################

seacow = { tokenize, parse, translate }
if module?
then module.exports = seacow
else globalThis.seacow = seacow

##########################################################################################

# code | tokenize | parse | translate | format

###

TODO:
X handle complex:names
X handle ~soak and ~spread
X handle key;
X handle {args, ...}
X check @x, &1, &x, &, &&

X labels
X try / catch / finally
X throw

no 'new' operator. use Reflect.construct instead.

classes?

class foo extends bar

    def constructor a b
        ...

    def baz c d
        ...

----

  global foo bar baz

###
