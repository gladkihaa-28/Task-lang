import asyncio
import copy
import math
import multiprocessing
import random
import time

try:
    from CLexer import *
except:
    try:
        from CompiledFiles.CLexer import *
    except:
        from Task.CompiledFiles.CLexer import *


# Определение парсера для вычисления выражений
cdef class Parser():
    cdef public lexer
    cdef public symbol_table
    cdef public local_table
    cdef public func_table
    cdef public libs_name
    cdef public libs
    cdef public current_token
    cdef public run
    def __init__(self, lexer, symbol_table, local_table, func_table, libs_name=None, libs=None):
        """
        Конструктор класса Parser.

        Параметры:
        - lexer: экземпляр класса Lexer для токенизации входного текста.
        - symbol_table: экземпляр класса SymbolTable для отслеживания переменных.

        Примечание: symbol_table используется для хранения и управления переменными.
        """
        self.lexer = lexer
        self.current_token = self.lexer.get_next_token()
        self.symbol_table = symbol_table
        self.local_table = local_table
        self.func_table = func_table
        self.run = False
        self.libs_name = libs_name
        self.libs = libs

    cdef eat(self, token_type):
        """
        Потребление текущего токена, если его тип совпадает с ожидаемым.

        Параметры:
        - token_type: ожидаемый тип токена.
        """
        if self.current_token.type == token_type:
            self.current_token = self.lexer.get_next_token()
        else:
            raise Exception(f"Error eating {self.current_token.type} token!")

    cdef factor(self):
        """
        Обработка фактора (целого числа, переменной или выражения в скобках).

        Возвращает:
        - Значение фактора (целое число или значение переменной).
        """
        token = self.current_token
        if token.type == ARRAY:
            return self.array()
        elif token.type == NUMBER:
            self.eat(NUMBER)
            return token.value
        elif token.type == STRING:
            string_value = token.value
            self.eat(STRING)
            return string_value
        elif token.type == NONE:
            self.eat(NONE)
            return None
        elif token.type == BOOL:
            result = token.value
            if result == "True":
                result = True
            else:
                result = False
            self.eat(BOOL)
            return result
        elif token.type == VAR:
            var_name = token.value
            self.eat(VAR)
            return self.symbol_table.lookup(var_name)
        elif token.type == INT:
            self.eat(INT)
            self.eat(LPAREN)
            result = int(self.expr())
            self.eat(RPAREN)
            return result
        elif token.type == FLOAT:
            self.eat(FLOAT)
            self.eat(LPAREN)
            result = float(self.expr())
            self.eat(RPAREN)
            return result
        elif token.type == STR:
            self.eat(STR)
            self.eat(LPAREN)
            result = str(self.expr())
            self.eat(RPAREN)
            return result
        elif token.type == INPUT:
            input_value = input()
            self.eat(INPUT)
            self.eat(LPAREN)
            self.eat(RPAREN)
            return input_value
        elif token.type == CONV:
            self.eat(CONV)
            self.eat(LPAREN)
            values = [self.expr()]
            while self.current_token.type == COMMA:
                self.eat(COMMA)
                values.append(self.expr())
            self.eat(RPAREN)
            print(values)
            return self.convert_base(values[0], values[2], values[1])
        elif token.type == EVAL:
            self.eat(EVAL)
            self.eat(LPAREN)
            value = self.expr()
            self.eat(RPAREN)
            return eval(value)
        elif token.type == CELL:
            self.eat(CELL)
            self.eat(LPAREN)
            values = [self.expr()]
            while self.current_token.type == COMMA:
                self.eat(COMMA)
                values.append(self.expr())
            self.eat(RPAREN)
            return self.get_element(values[0], values[1])
        elif token.type == INDEX:
            self.eat(INDEX)
            self.eat(LPAREN)
            values = [self.expr()]
            while self.current_token.type == COMMA:
                self.eat(COMMA)
                values.append(self.expr())
            self.eat(RPAREN)
            return self.get_index(values[0], values[1])
        elif token.type == RANGE:
            self.eat(RANGE)
            self.eat(LPAREN)
            values = [self.expr()]
            while self.current_token.type == COMMA:
                self.eat(COMMA)
                values.append(self.expr())
            self.eat(RPAREN)
            if len(values) == 1:
                return list(range(values[0]))
            elif len(values) == 2:
                return list(range(values[0], values[1]))
            elif len(values) == 3:
                return list(range(values[0], values[1], values[2]))
        elif token.type == APPEND:
            self.eat(APPEND)
            self.eat(LPAREN)
            values = [self.expr()]
            while self.current_token.type == COMMA:
                self.eat(COMMA)
                values.append(self.expr())
            self.eat(RPAREN)
            values[0].append(values[1])
            return values[0]
        elif token.type == INSERT:
            self.eat(INSERT)
            self.eat(LPAREN)
            values = [self.expr()]
            while self.current_token.type == COMMA:
                self.eat(COMMA)
                values.append(self.expr())
            self.eat(RPAREN)
            return self.Insert(values[0], values[1], values[2])
        elif token.type == SORT:
            self.eat(SORT)
            self.eat(LPAREN)
            values = [self.expr()]
            while self.current_token.type == COMMA:
                self.eat(COMMA)
                values.append(self.expr())
            self.eat(RPAREN)
            if len(values) == 1:
                return sorted(values[0])
            else:
                return sorted(values[0], reverse=values[1])
        elif token.type == LEN:
            self.eat(LEN)
            self.eat(LPAREN)
            value = self.expr()
            self.eat(RPAREN)
            return len(value)
        elif token.type == TYPE:
            self.eat(TYPE)
            self.eat(LPAREN)
            value = self.expr()
            self.eat(RPAREN)
            if type(value) == int:
                return "int"
            elif type(value) == float:
                return "float"
            elif type(value) == str:
                return "string"
            elif type(value) == bool:
                return "bool"
            elif type(value) == list:
                return "list"
        elif token.type == MIN:
            self.eat(MIN)
            self.eat(LPAREN)
            arr = self.expr()
            self.eat(RPAREN)
            return min(arr)
        elif token.type == MAX:
            self.eat(MAX)
            self.eat(LPAREN)
            arr = self.expr()
            self.eat(RPAREN)
            return max(arr)
        elif token.type == MED:
            self.eat(MED)
            self.eat(LPAREN)
            arr = self.expr()
            self.eat(RPAREN)
            n = len(arr) // 2
            if len(arr) % 2 == 0:
                med = arr[n-1:n+1]
            else:
                med = arr[n]
            return med
        elif token.type == CLEAR:
            self.eat(CLEAR)
            self.eat(LPAREN)
            arr = self.expr()
            self.eat(RPAREN)
            arr.clear()
            return arr
        elif token.type == SPLIT:
            try:
                self.eat(SPLIT)
                self.eat(LPAREN)
                values = [self.expr()]
                while self.current_token.type == COMMA:
                    self.eat(COMMA)
                    values.append(self.expr())
                self.eat(RPAREN)
                return values[0].split(values[1])
            except:
                Syntax().syntax_error(self.lexer.text)
        elif token.type == JOIN:
            try:
                self.eat(JOIN)
                self.eat(LPAREN)
                values = [self.expr()]
                while self.current_token.type == COMMA:
                    self.eat(COMMA)
                    values.append(self.expr())
                self.eat(RPAREN)
                return values[1].join(values[0])
            except:
                Syntax().syntax_error(self.lexer.text)
        elif token.type == TMAP:
            self.eat(TMAP)
            self.eat(LPAREN)
            values = [self.expr()]
            while self.current_token.type == COMMA:
                self.eat(COMMA)
                values.append(self.expr())
            self.eat(RPAREN)
            if values[1] == 'int':
                values[1] = int
            elif values[1] == 'float':
                values[1] = float
            elif values[1] == 'str':
                values[1] = str
            elif values[1] == 'bool':
                values[1] = bool
            elif values[1] == 'list':
                values[1] = list
            return list(map(values[1], values[0]))
        elif token.type == POP_STR:
            self.eat(POP_STR)
            self.eat(LPAREN)
            value = self.expr()
            self.eat(COMMA)
            ind = self.expr()
            self.eat(RPAREN)
            return value.replace(value[ind], "")
        elif token.type == POP_ARR:
            self.eat(POP_ARR)
            self.eat(LPAREN)
            value = self.expr()
            self.eat(COMMA)
            ind = self.expr()
            value.pop(ind)
            self.eat(RPAREN)
            return value
        elif token.type == READ:
            self.eat(READ)
            self.eat(LPAREN)
            value = self.expr()
            try:
                return open("../" + value, "r", encoding="utf-8").read()
            except:
                return open("..\\" + value, "r", encoding="utf-8").read()
        elif token.type == LPAREN:
            self.eat(LPAREN)
            result = self.expr()
            self.eat(RPAREN)
            return result

    cdef term(self):
        """
        Обработка терма (произведения или частного).

        Возвращает:
        - Результат вычисления терма.
        """
        result = self.factor()

        while self.current_token.type in (MULTIPLY, DIVIDE, PR, DEG):
            token = self.current_token
            if token.type == MULTIPLY:
                self.eat(MULTIPLY)
                result *= self.factor()
            elif token.type == DIVIDE:
                self.eat(DIVIDE)
                result /= self.factor()
            elif token.type == PR:
                self.eat(PR)
                result %= self.factor()
            elif token.type == DEG:
                self.eat(DEG)
                num = self.factor()
                result = math.pow(result, num)

        return result

    cdef expr(self):
        """
        Обработка выражения (суммы или разности).

        Возвращает:
        - Результат вычисления выражения.
        """
        result = self.term()

        while self.current_token.type in (PLUS, MINUS):
            token = self.current_token
            if token.type == PLUS:
                self.eat(PLUS)
                result += self.term()
            elif token.type == MINUS:
                self.eat(MINUS)
                result -= self.term()

        return result

    cdef array(self):
        self.eat(ARRAY)
        elements = []


        if self.current_token.type != ARRAY:
            while self.current_token.type != EOF and self.current_token.type != ARRAY:
                elements.append(self.expr())
                if self.current_token.type == COMMA:
                    self.eat(COMMA)

        self.eat(ARRAY)
        return elements

    cdef if_statement(self):
        self.eat(iF)
        self.eat(LPAREN)
        condition = []
        while self.current_token.type != RPAREN:
            if self.current_token.value == "+" or self.current_token == "-" or self.current_token == "*" or self.current_token == "/":
                condition.append('"' + str(self.expr()) + '"')
            elif self.current_token.value != "not" and self.current_token.value != "and" and self.current_token.value != "or":
                condition.append(self.expr())
            if self.current_token.type == EQEQ:
                condition.append("==")
                self.eat(EQEQ)
            if self.current_token.type == MORE:
                condition.append(">")
                self.eat(MORE)
            if self.current_token.type == LESS:
                condition.append("<")
                self.eat(LESS)
            if self.current_token.type == MOREEQ:
                condition.append(">=")
                self.eat(MOREEQ)
            if self.current_token.type == LESSEQ:
                condition.append("<=")
                self.eat(LESSEQ)
            if self.current_token.type == NOTEQ:
                condition.append("!=")
                self.eat(NOTEQ)
            if self.current_token.type == NOT:
                condition.append("not")
                self.eat(NOT)
            if self.current_token.type == AND:
                condition.append("and")
                self.eat(AND)
            if self.current_token.type == OR:
                condition.append("or")
                self.eat(OR)

        self.eat(RPAREN)
        con = []
        for condit in condition:
            if condit == "True" or condit == "False":
                condit = bool(condit)
            if type(condit) == str and condit != "==" and condit != ">" and condit != "<" and condit != ">=" and condit != "<=" and condit != "!=" and condit != "not" and condit != "and" and condit != "or":
                con.append('"' + condit + '"')
            else:
                con.append(str(condit))

        condition.clear()
        condition = con
        condition = eval(" ".join(condition))
        br = False

        if condition:
            self.eat(LBRACE)
            while self.current_token.type != END_IF and self.current_token.type != RBRACE:
                br = self.statement()
            if self.current_token.type == RBRACE:
                self.eat(RBRACE)
            else:
                self.eat(END_IF)
            try:
                self.eat(eLSE)
                self.eat(LBRACE)
                while self.current_token.type != RBRACE and self.current_token.type != END_IF:
                    self.current_token = self.lexer.get_next_token()
                if self.current_token.type == RBRACE:
                    self.eat(RBRACE)
                else:
                    self.eat(END_IF)
            except:
                pass
        else:
            self.eat(LBRACE)
            while self.current_token.type != END_IF and self.current_token.type != RBRACE:
                self.current_token = self.lexer.get_next_token()

            if self.current_token.type == RBRACE:
                self.eat(RBRACE)
                try:
                    self.eat(eLSE)
                    self.eat(LBRACE)
                    while self.current_token.type != END_IF:
                        br = self.statement()
                    self.eat(END_IF)
                except:
                    pass
            else:
                self.eat(END_IF)
        return br

    cdef for_statement(self):
        self.eat(FOR)
        var_name = self.current_token.value
        self.eat(VAR)
        self.eat(IN)
        sp = self.expr()
        self.eat(LBRACE)
        pos = len(self.lexer.text.split('{')[0]) + 2
        self.run = True
        code = ""
        end = self.lexer.text.count("}!")
        k = 0

        for i in sp:
            self.symbol_table.define(var_name, i)
            while True:
                if self.current_token.type == END_FOR:
                    k += 1
                    if k == end:
                        k = 0
                        break

                if self.current_token.type == EOF:
                    self.current_token = self.lexer.get_next_token()
                    break
                else:
                    if self.current_token.type == STRING:
                        code += '"' + str(self.current_token.value) + '"'
                    else:
                        code += str(self.current_token.value) + " "
                    self.current_token = self.lexer.get_next_token()

            if self.current_token.type == END_FOR:
                pass
            if self.current_token.type == BREAK:
                self.eat(BREAK)
                self.run = False

            lex = Lexer(code)
            pars = Parser(lex, self.symbol_table, self.local_table, self.func_table, self.libs_name, self.libs)
            self.run = pars.parse()
            code = ""

            if not self.run:
                break

            if i != sp[-1]:
                self.lexer.return_pos(pos)
            self.eat(END_FOR)

    def iteration(self, var_name, i, pos, sp, k, end, symb_table, loc_table):
        code = ""
        self.symbol_table.define(var_name, i)
        while True:
            if self.current_token.type == END_FOR:
                k += 1
                if k == end:
                    k = 0
                    break

            if self.current_token.type == EOF:
                self.current_token = self.lexer.get_next_token()
                break
            else:
                if self.current_token.type == STRING:
                    code += '"' + str(self.current_token.value) + '"'
                else:
                    code += str(self.current_token.value) + " "
                self.current_token = self.lexer.get_next_token()

        if self.current_token.type == END_FOR:
            pass
        if self.current_token.type == BREAK:
            self.eat(BREAK)
            self.run = False

        lex = Lexer(code)
        pars = Parser(lex, symb_table, loc_table, self.func_table, self.libs_name, self.libs)
        self.run = pars.parse()

        code = ""


        if i != sp[-1]:
            self.lexer.return_pos(pos)
        self.eat(END_FOR)

    cdef threaded_for_statement(self, var_name, sp, threads):
        self.symbol_table.define(var_name, "")
        pos = len(self.lexer.text.split('{')[0]) + 2
        end = self.lexer.text.count("}!")
        k = 0

        if threads is None:
            with multiprocessing.Pool(processes=4) as pool:
                pool.starmap(self.iteration, [(var_name, i, pos, sp, k, end, self.symbol_table, self.local_table) for i in sp])
        else:
            with multiprocessing.Pool(processes=threads) as pool:
                pool.map(self.iteration, [(var_name, i, pos, sp, k, end, self.symbol_table, self.local_table) for i in sp[1:]])

    cdef async_for_statement(self):
        self.eat(aSYNC)
        try:
            self.eat(LIMITER)
            threads = self.expr()
        except:
            threads = None
        self.eat(FOR)
        var_name = self.current_token.value
        self.eat(VAR)
        self.eat(IN)
        sp = self.expr()
        self.eat(LBRACE)

        self.threaded_for_statement(var_name, sp, threads)

    cdef get_element(self, arr, ind):
        return arr[ind]

    cdef get_index(self, arr, el):
        return arr.index(el)

    cdef Insert(self, arr, el, ind):
        try:
            arr[ind] = el
            return arr
        except:
            Array().index_error(ind)

    cdef func_statement(self):
        try:
            self.eat(VOID)
            param = "void"
        except:
            self.eat(FUNC)
            param = "func"
        func_name = self.current_token.value
        self.eat(VAR)
        try:
            self.eat(LPAREN)
            vars = [self.current_token.value]
            self.current_token = self.lexer.get_next_token()
            while self.current_token.type == COMMA:
                self.eat(COMMA)
                vars.append(self.current_token.value)
                self.current_token = self.lexer.get_next_token()
            self.eat(RPAREN)
            _vars = {}
            for i, el in enumerate(vars):
                _vars[el] = str(i)
            self.local_table.define(func_name, _vars)
        except:
            pass
        self.eat(LBRACE)
        code = ""
        while self.current_token.type != END_FUNC:
            if self.current_token.type == STRING:
                code += '"' + str(self.current_token.value) + '"'
            else:
                code += str(self.current_token.value) + " "
            self.current_token = self.lexer.get_next_token()
        self.eat(END_FUNC)


        self.func_table.define(func_name, [code, param])
        #print(self.local_table.symbols)

    cdef call_statement(self):
        self.eat(CALL)
        func_name = self.current_token.value
        key = self.func_table.lookup(func_name)
        code = key[0]
        if key[1] == "func":
            self.call_func_statement(code, func_name)
        elif key[1] == "void":
            self.call_void_statement(code, func_name)

    cdef call_func_statement(self, code, func_name):
        self.eat(VAR)
        n = random.randint(1000, 10000)
        try:
            self.eat(LPAREN)
            var = self.current_token.value
            self.eat(VAR)
            self.eat(RPAREN)
            self.symbol_table.define(var, "Функция, имеющая тип func, должна возвращать значение!")
            try:
                i = 0
                self.eat(LPAREN)
                while self.current_token.type != RPAREN:
                    value = self.expr()
                    local_dict = self.local_table.lookup(func_name)
                    for var_name in local_dict:
                        if local_dict[var_name] == str(i):
                            local_var = var_name
                            break
                    local_dict[local_var] = value
                    self.local_table.define(func_name, local_dict)
                    i += 1
                    try:
                        self.eat(COMMA)
                    except:
                        pass
                self.eat(RPAREN)
            except:
                pass
        except:
            var = "not_init_var_" + str(n)

        #print(self.local_table.symbols)

        if "return" in code and var == "not_init_var_" + str(n):
            Syntax().syntax_error(self.lexer.text)

        try:
            table = copy.copy(self.local_table)
            table.symbols = copy.copy(self.local_table.symbols[func_name])
        except:
            table = copy.copy(self.local_table)
            table.symbols = {}

        lex = Lexer(code)
        pars = Parser(lex, table, self.symbol_table, self.func_table, self.libs_name, self.libs)
        pars.parse()
        self.local_table.symbols[func_name] = table.symbols

    cdef call_void_statement(self, code, func_name):
        self.eat(VAR)
        n = random.randint(1000, 10000)
        try:
            i = 0
            self.eat(LPAREN)
            while self.current_token.type != RPAREN:
                value = self.expr()
                local_dict = self.local_table.lookup(func_name)
                for var_name in local_dict:
                    if local_dict[var_name] == str(i):
                        local_var = var_name
                        break
                local_dict[local_var] = value
                self.local_table.define(func_name, local_dict)
                i += 1
                try:
                    self.eat(COMMA)
                except:
                    pass
            self.eat(RPAREN)
        except:
            pass


        #print(self.local_table.symbols)

        if "return" in code:
            Syntax().syntax_error(self.lexer.text)

        #print(self.local_table.symbols)
        try:
            table = copy.copy(self.local_table)
            table.symbols = copy.copy(self.local_table.symbols[func_name])
        except:
            table = copy.copy(self.local_table)
            table.symbols = {}

        lex = Lexer(code)
        pars = Parser(lex, table, self.symbol_table, self.func_table, self.libs_name, self.libs)
        pars.parse()
        self.symbol_table, self.local_table.symbols[func_name] = table, self.symbol_table

    cdef statement(self):
        """
        Обработка выражений присваивания переменных, ввода и вывода значений.

        В данной функции происходит определение переменных, ввод и вывод значений с использованием
        операторов присваивания (=), ввода (input) и функции print.

        Примечание: Если встречается неизвестная команда, генерируется исключение.
        """
        if self.current_token.type == VAR:
            var_name = self.current_token.value
            self.eat(VAR)
            if self.current_token.type == ASSIGN:
                self.eat(ASSIGN)
                value = self.expr()
                self.symbol_table.define(var_name, value)
            else:
                Syntax().syntax_error(self.lexer.text)
                sys.exit()

        elif self.current_token.type == PRINT:
            self.eat(PRINT)
            self.eat(LPAREN)
            values = []
            while self.current_token.type != EOF and self.current_token.type != RPAREN:
                values.append(self.expr())
                if self.current_token.type == COMMA:
                    self.eat(COMMA)
            self.eat(RPAREN)
            print(*values)

        elif self.current_token.type == INPUT:
            self.eat(INPUT)
            self.eat(LPAREN)
            var_name = self.current_token.value
            input_value = self.expr()
            self.eat(RPAREN)
            self.symbol_table.define(var_name, input_value)
        elif self.current_token.type == iF:
            br = self.if_statement()
            return br
        elif self.current_token.type == FOR:
            self.for_statement()
        elif self.current_token.type == aSYNC:
            self.async_for_statement()
        elif self.current_token.type == SLEEP:
            self.eat(SLEEP)
            self.eat(LPAREN)
            value = self.expr()
            self.eat(RPAREN)
            asyncio.sleep(value)
        elif self.current_token.type == END_IF:
            self.eat(END_IF)
        elif self.current_token.type == END_FOR:
            self.eat(END_FOR)
        elif self.current_token.type == END_FUNC:
            self.eat(END_FUNC)
        elif self.current_token.type == BREAK:
            self.run = False
            self.eat(BREAK)
            return True
        elif self.current_token.type == FUNC or self.current_token.type == VOID:
            self.func_statement()
        elif self.current_token.type == CALL:
            self.call_statement()
        elif self.current_token.type == RETURN:
            self.eat(RETURN)
            value = self.expr()
            var = self.local_table.antilookup("Функция, имеющая тип func, должна возвращать значение!")
            self.local_table.define(var, value)
            self.lexer.text = ""
        elif self.current_token.type == PASS:
            self.eat(PASS)
            pass
        elif self.current_token.type == GENERATE:
            self.eat(GENERATE)
            self.eat(LPAREN)
            var = self.expr()
            self.eat(COMMA)
            value = self.expr()
            self.eat(RPAREN)
            self.symbol_table.define(var, value)
        elif self.current_token.type == EOF:
            self.eat(EOF)
        elif self.current_token.type == WRITE:
            self.eat(WRITE)
            self.eat(LPAREN)
            values = [self.expr()]
            while self.current_token.type == COMMA:
                self.eat(COMMA)
                values.append(self.expr())
            self.eat(RPAREN)
            try:
                with open("../" + values[0], values[1], encoding="utf-8") as file:
                    file.write(values[2])
            except:
                with open("..\\" + values[0], values[1], encoding="utf-8") as file:
                    file.write(values[2])
        elif self.current_token.type == EXEC:
            self.eat(EXEC)
            self.eat(LPAREN)
            code = self.expr()
            self.eat(RPAREN)
            exec(code)
        else:
            self.current_token = self.lexer.get_next_token()

    cdef convert_base(self, num, to_base, from_base):
        num = str(num)
        # first convert to decimal number
        n = int(num, from_base) if isinstance(num, str) else num
        # now convert decimal to 'to_base' base
        alphabet = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        res = ""
        while n > 0:
            n, m = divmod(n, to_base)
            res += alphabet[m]
        return res[::-1]

    cdef cparse(self):
        """
        Парсинг входного текста и выполнение выражений.

        Эта функция запускает парсинг входного текста и последовательно выполняет
        выражения, включая присваивание переменных и вывод значений.
        """
        br = False
        while self.current_token.type != EOF:
            br = self.statement()

        if br:
            return self.run
        else:
            return True

    def parse(self):
        br = self.cparse()
        return br