import re
import os
import sys


# Define token types
NUMBER = "NUMBER"
STRING = "STRING"
INT = "INT"
FLOAT = "FLOAT"
STR = "STR"
BOOL = "BOOL"
NONE = "NONE"
PLUS = "PLUS"
MINUS = "MINUS"
MULTIPLY = "MULTIPLY"
DIVIDE = "DIVIDE"
PR = "PR"
EOF = "EOF"
COMMA = "COMMA"
LPAREN = "LPAREN"
RPAREN = "RPAREN"
ASSIGN = "ASSIGN"
VAR = "VAR"
PRINT = "PRINT"
INPUT = "INPUT"
CONV = "CONV"
EVAL = "EVAL"
ARRAY = "ARRAY"
iF = "iF"
EQEQ = "EQEQ"
LBRACE = "LBRACE"
RBRACE = "RBRACE"
MORE = "MORE"
LESS = "LESS"
MOREEQ = "MOREEQ"
LESSEQ = "LESSEQ"
NOTEQ = "NOTEQ"
NOT = "NOT"
AND = "AND"
OR = "OR"
CELL = "CELL"
INDEX = "INDEX"
RANGE = "RANGE"
APPEND = "APPEND"
INSERT = "INSERT"
LEN = "LEN"
TYPE = "TYPE"
eLSE = "ELSE"
FOR = "FOR"
IN = "IN"
aSYNC = "aSYNC"
SLEEP = "SLEEP"
MIN = "MIN"
MAX = "MAX"
MED = "MED"
CLEAR = "CLEAR"
SPLIT = "SPLIT"
JOIN = "JOIN"
TMAP = "MAP"
BREAK = "BREAK"
SORT = "SORT"
LIMITER = "LIMITER"
PASS = "PASS"
END_IF = "END_IF"
END_FOR = "END_FOR"
POP_STR = "POP_STR"
POP_ARR = "POP_ARR"
FUNC = "FUNC"
VOID = "VOID"
CALL = "CALL"
END_FUNC = "END_FUNC"
RETURN = "RETURN"
RANDOM = "RANDOM"
RANDINT = "RANDINT"
RANDRANGE = "RANDRANGE"
RANDSORT = "RANDSORT"
RANDCHOICE = "RANDCHOICE"
GENERATE = "GENERATE"
DEG = "DEG"
EXEC = "EXEC"
READ = "READ"
WRITE = "WRITE"




# Define a token class to represent tokens
cdef class Token:
    cdef public type
    cdef public value
    def __init__(self, type, value):
        self.type = type
        self.value = value

    def __str__(self):
        return f'Token({self.type}, {self.value})'

    def __repr__(self):
        return self.__str__()

# Define a lexer to tokenize the input
cdef class Lexer:
     cdef public text
     cdef public int pos
     cdef public current_char
     def __init__(self, text):
         self.text = text
         self.pos = 0
         self.current_char = self.text[self.pos]

     cdef advance(self):
         self.pos += 1
         if self.pos < len(self.text):
             self.current_char = self.text[self.pos]
         else:
             self.current_char = None

     cdef creturn_pos(self, int pos):
         self.pos = pos
         if self.pos < len(self.text):
             self.current_char = self.text[self.pos]
         else:
             self.current_char = None

     def return_pos(self, int pos):
         self.creturn_pos(pos)

     cdef skip_whitespace(self):
         while self.current_char is not None and self.current_char.isspace():
             self.advance()

     def get_next_token(self):
        token = self.cget_next_token()
        return token

     cdef cget_next_token(self):
         while self.current_char is not None:
             if self.current_char.isspace():
                 self.skip_whitespace()
                 continue

             if self.current_char.isdigit() or self.current_char == "-":
                 token_value = ""
                 while self.current_char is not None and (self.current_char.isdigit() or self.current_char == "." or self.current_char == "-"):
                     token_value += self.current_char
                     self.advance()
                 try:
                     return Token(NUMBER, int(token_value))
                 except:
                     try:
                         return Token(NUMBER, float(token_value))
                     except:
                         return Token(MINUS, "-")

             if self.current_char == '"':
                 self.advance()
                 string_value = ""
                 while self.current_char is not None and self.current_char != '"':
                     string_value += self.current_char
                     self.advance()
                 if self.current_char == '"':
                     self.advance()
                     return Token(STRING, string_value)
                 else:
                     print(f"Некорректный символ: {self.current_char}")
                     sys.exit()

             if self.current_char == '+':
                 self.advance()
                 return Token(PLUS, '+')

             if self.current_char == '-':
                 self.advance()
                 return Token(MINUS, '-')

             if self.current_char == '*':
                 self.advance()
                 return Token(MULTIPLY, '*')

             if self.current_char == '/':
                 self.advance()
                 return Token(DIVIDE, '/')

             if self.current_char == '%':
                 self.advance()
                 return Token(PR, '%')

             if self.current_char == '(':
                 self.advance()
                 return Token(LPAREN, '(')

             if self.current_char == ')':
                 self.advance()
                 return Token(RPAREN, ')')

             if self.current_char == '=':
                 self.advance()
                 if self.current_char == '=':
                     self.advance()
                     return Token(EQEQ, '==')
                 else:
                     return Token(ASSIGN, '=')

             if self.current_char == '>':
                 self.advance()
                 if self.current_char == '=':
                     self.advance()
                     return Token(MOREEQ, '>=')
                 else:
                     return Token(MORE, '>')

             if self.current_char == '<':
                 self.advance()
                 if self.current_char == '=':
                     self.advance()
                     return Token(LESSEQ, '<=')
                 else:
                     return Token(LESS, '<')

             if self.current_char == '!':
                 self.advance()
                 if self.current_char == '=':
                     self.advance()
                     return Token(NOTEQ, '!=')
                 else:
                     return Token(NOT, '!')

             if self.current_char == ',':
                 self.advance()
                 return Token(COMMA, ',')

             if self.current_char == '[':
                 self.advance()
                 return Token(ARRAY, '[')

             if self.current_char == ']':
                 self.advance()
                 return Token(ARRAY, ']')

             if self.current_char == '{':
                 self.advance()
                 return Token(LBRACE, '{')

             if self.current_char == '}':
                 self.advance()
                 if self.current_char == ':':
                     self.advance()
                     return Token(END_IF, '}:')
                 elif self.current_char == '!':
                     self.advance()
                     return Token(END_FOR, '}!')
                 elif self.current_char == ';':
                     return Token(END_FUNC, '};')
                 else:
                     return Token(RBRACE, '}')

             if self.current_char == '&':
                 self.advance()
                 return Token(LIMITER, '&')

             elif self.current_char == "@":
                 self.advance()
                 return Token(CALL, "@")

             elif self.current_char == ";":
                 self.advance()
                 return Token(END_FUNC, ";")

             elif self.current_char == "^":
                 self.advance()
                 return Token(DEG, "^")

             if self.current_char.isalpha():
                 token_value = ""
                 while self.current_char is not None and (self.current_char.isalpha() or self.current_char.isdigit() or self.current_char == "_"):
                     token_value += self.current_char
                     self.advance()
                 if token_value == "print":
                     return Token(PRINT, "print")
                 elif token_value == "input":
                     return Token(INPUT, "input")
                 elif token_value == "int":
                     return Token(INT, "int")
                 elif token_value == "float":
                     return Token(FLOAT, "float")
                 elif token_value == "str":
                     return Token(STR, "str")
                 elif token_value == "None":
                     return Token(NONE, "None")
                 elif token_value == "conv":
                     return Token(CONV, "conv")
                 elif token_value == "eval":
                     return Token(EVAL, "eval")
                 elif token_value == "if":
                     return Token(iF, "if")
                 elif token_value == "True" or token_value == "False":
                     return Token(BOOL, token_value)
                 elif token_value == "not":
                     return Token(NOT, "not")
                 elif token_value == "and":
                     return Token(AND, "and")
                 elif token_value == "or":
                     return Token(OR, "or")
                 elif token_value == "cell":
                     return Token(CELL, "cell")
                 elif token_value == "index":
                     return Token(INDEX, "index")
                 elif token_value == "range":
                     return Token(RANGE, "range")
                 elif token_value == "append":
                     return Token(APPEND, "append")
                 elif token_value == "insert":
                     return Token(INSERT, "insert")
                 elif token_value == "sort":
                     return Token(SORT, "sort")
                 elif token_value == "len":
                     return Token(LEN, "len")
                 elif token_value == "type":
                     return Token(TYPE, "type")
                 elif token_value == "else":
                     return Token(eLSE, "else")
                 elif token_value == "for":
                     return Token(FOR, "for")
                 elif token_value == "in":
                     return Token(IN, "in")
                 elif token_value == "async":
                     return Token(aSYNC, "async")
                 elif token_value == "sleep":
                     return Token(SLEEP, "sleep")
                 elif token_value == "min":
                     return Token(MIN, "min")
                 elif token_value == "max":
                     return Token(MAX, "max")
                 elif token_value == "med":
                     return Token(MED, "med")
                 elif token_value == "clear":
                     return Token(CLEAR, "clear")
                 elif token_value == "split":
                     return Token(SPLIT, "split")
                 elif token_value == "join":
                     return Token(JOIN, "join")
                 elif token_value == "tmap":
                     return Token(TMAP, "tmap")
                 elif token_value == "break":
                     return Token(BREAK, "break")
                 elif token_value == "pass":
                     return Token(PASS, "pass")
                 elif token_value == "pop_str":
                     return Token(POP_STR, "pop_str")
                 elif token_value == "pop_arr":
                     return Token(POP_ARR, "pop_arr")
                 elif token_value == "func":
                     return Token(FUNC, "func")
                 elif token_value == "void":
                     return Token(VOID, "void")
                 elif token_value == "return":
                     return Token(RETURN, "return")
                 elif token_value == "random":
                     return Token(RANDOM, "random")
                 elif token_value == "randint":
                     return Token(RANDINT, "randint")
                 elif token_value == "randrange":
                     return Token(RANDRANGE, "randrange")
                 elif token_value == "randsort":
                     return Token(RANDSORT, "randsort")
                 elif token_value == "randchoice":
                     return Token(RANDCHOICE, "randchoice")
                 elif token_value == "generate":
                     return Token(GENERATE, "generate")
                 elif token_value == "exec":
                     return Token(EXEC, "exec")
                 elif token_value == "read":
                     return Token(READ, "read")
                 elif token_value == "write":
                     return Token(WRITE, "write")
                 else:
                     return Token(VAR, token_value)

             print(f"Неверный синтаксис: {self.text}")
             sys.exit()

         return Token(EOF, None)



cdef crewrite_code(file, str text, libs_name, libs, str if_text, str for_text, str func_text, path):
    if "import" in text:
        try:
            try:
                text2 = open("/".join(path.split("/")[:-1]) + "/" + text.split()[1] + ".tsk", "r", encoding="utf-8").read()
            except:
                text2 = open("\\".join(path.split("\\")[:-1]) + "\\" + text.split()[1] + ".tsk", "r", encoding="utf-8").read()
        except Exception as ex:
            try:
                text2 = open("/".join(os.path.abspath(text.split()[1] + ".tsk").split("/")[:-1]) + "/Task/libs/" + text.split()[1] + ".tsk", "r", encoding="utf-8").read()
            except Exception as ex:
                text2 = open("Task\\libs\\" + text.split()[1] + ".tsk", "r", encoding="utf-8").read()

        text = "<module>" + text2.replace("\n", " ")
        return text


    if "if" in text:
        if_text += text
        while text[0:2] != '}:':
            text = file.readline()
            if_text += text
        text = if_text.replace("\n", " ")
        if_text = ""

    elif "for" in text:
        for_text += text
        while text[0:2] != '}!':
            text = file.readline()
            for_text += text
        text = for_text.replace("\n", " ")
        for_text = ""

    elif "func" in text or "void" in text:
        func_text += text
        while text[0:2] != '};':
            text = file.readline()
            func_text += text
        text = func_text.replace("\n", " ")
        func_text = ""

    if "#" in text:
        text = text.replace(text[text.index("#"):], "")

    return text


def rewrite_code(file, str text, libs_name, libs, str if_text, str for_text, str func_text, path):
    res = crewrite_code(file, text, libs_name, libs, if_text, for_text, func_text, path)
    return res


cdef class SymbolTable:
    cdef public symbols
    def __init__(self):
        self.symbols = {}

    def define(self, var_name, value):
        self.symbols[var_name] = value

    def lookup(self, var_name):
        if var_name in self.symbols:
            return self.symbols[var_name]
        print(f"Переменная {var_name} не определена")
        sys.exit()

    def antilookup(self, value):
        for var_name in self.symbols:
            if self.symbols[var_name] == value:
                return var_name

cdef class LocalSymbolTable:
    cdef public symbols
    def __init__(self):
        self.symbols = {}

    def define(self, var_name, value):
        self.symbols[var_name] = value

    def lookup(self, var_name):
        if var_name in self.symbols:
            return self.symbols[var_name]
        print(f"Переменная {var_name} не определена")
        sys.exit()

    def antilookup(self, value):
        for var_name in self.symbols:
            if self.symbols[var_name] == value:
                return var_name


cdef class FuncTable:
    cdef public symbols
    def __init__(self):
        self.symbols = {}

    def define(self, func_name, code):
        self.symbols[func_name] = code

    def lookup(self, func_name):
        if func_name in self.symbols:
            return self.symbols[func_name]
        print(f"Функция {func_name} не определена")
        sys.exit()